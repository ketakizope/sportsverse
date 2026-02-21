# sportsverse/backend/organizations/models.py

import logging
from django.db import models
from django.core.exceptions import ValidationError
from django.db.models import F

logger = logging.getLogger(__name__)


class Organization(models.Model):
    # This is your main Tenant model
    full_name = models.CharField(max_length=255, help_text="Full legal name of the organization/academy")
    academy_name = models.CharField(max_length=255, help_text="Commonly used display name")
    logo = models.ImageField(upload_to='academy_logos/', blank=True, null=True)
    location = models.TextField(blank=True, help_text="Full physical address of the primary location")
    mobile_number = models.CharField(max_length=20, blank=True)
    email_address = models.EmailField(unique=True)
    slug = models.SlugField(max_length=100, unique=True, help_text="Unique identifier for URL, e.g., 'elite-tennis'")
    sports_offered = models.ManyToManyField('Sport', related_name='organizations', blank=True)

    # Status/Subscription fields
    is_active = models.BooleanField(default=True)
    subscription_plan = models.CharField(
        max_length=50, default='FREE_TRIAL',
        choices=[('FREE_TRIAL', 'Free Trial'), ('BASIC', 'Basic'), ('PREMIUM', 'Premium')]
    )
    subscription_end_date = models.DateField(null=True, blank=True)
    date_joined = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.academy_name


class Sport(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    icon = models.ImageField(upload_to='sport_icons/', blank=True, null=True)

    def __str__(self):
        return self.name


class Branch(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='branches')
    name = models.CharField(max_length=200)
    address = models.TextField()
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} ({self.organization.academy_name})"


class Batch(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='batches')
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE, related_name='batches')
    sport = models.ForeignKey(Sport, on_delete=models.CASCADE, related_name='batches')
    name = models.CharField(max_length=200)

    # Schedule: e.g. {'days': ['Mon', 'Wed'], 'start_time': '18:00', 'end_time': '19:00'}
    schedule_details = models.JSONField(
        default=dict,
        help_text="e.g., {'days': ['Mon', 'Wed'], 'start_time': '18:00', 'end_time': '19:00'}"
    )
    max_students = models.IntegerField(default=20)
    is_active = models.BooleanField(default=True)

    # Fee structure
    PAYMENT_POLICY_CHOICES = (
        ('PRE_PAID', 'Pre-paid'),
        ('POST_PAID', 'Post-paid'),
    )
    fee_per_session = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    payment_policy = models.CharField(max_length=20, choices=PAYMENT_POLICY_CHOICES, default='POST_PAID')

    def __str__(self):
        return f"{self.name} - {self.sport.name} at {self.branch.name} ({self.organization.academy_name})"


class Enrollment(models.Model):
    ENROLLMENT_TYPE_CHOICES = (
        ('SESSION_BASED', 'Session Based'),
        ('DURATION_BASED', 'Duration Based'),
    )
    student = models.ForeignKey('accounts.StudentProfile', on_delete=models.CASCADE, related_name='enrollments')
    batch = models.ForeignKey(Batch, on_delete=models.CASCADE, related_name='enrollments')
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='enrollments')

    enrollment_type = models.CharField(max_length=20, choices=ENROLLMENT_TYPE_CHOICES)

    # Duration-based fields
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)

    # Session-based fields
    total_sessions = models.IntegerField(null=True, blank=True)
    sessions_attended = models.IntegerField(default=0)

    is_active = models.BooleanField(default=True)
    enrollment_started = models.BooleanField(default=False)
    date_enrolled = models.DateTimeField(auto_now_add=True)
    date_first_attendance = models.DateTimeField(null=True, blank=True)

    class Meta:
        # Prevent a student from being enrolled in the same batch more than once
        unique_together = ('student', 'batch')

    def __str__(self):
        return f"{self.student.first_name} in {self.batch.name} - {self.enrollment_type}"

    def clean(self):
        """Django-level validation called by full_clean() and DRF serializers."""
        if self.enrollment_type == 'SESSION_BASED' and not self.total_sessions:
            raise ValidationError(
                "Total sessions must be provided for session-based enrollment."
            )

    def save(self, *args, **kwargs):
        # Run clean() so the ValidationError is raised with a proper HTTP 400 via DRF
        self.clean()
        super().save(*args, **kwargs)


class Attendance(models.Model):
    enrollment = models.ForeignKey(Enrollment, on_delete=models.CASCADE, related_name='attendances')
    batch = models.ForeignKey(Batch, on_delete=models.CASCADE, related_name='batch_attendances')
    student = models.ForeignKey('accounts.StudentProfile', on_delete=models.CASCADE, related_name='student_attendances')
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='attendances')

    date = models.DateField()
    marked_by = models.ForeignKey('accounts.CustomUser', on_delete=models.SET_NULL, null=True, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    is_session_deducted = models.BooleanField(default=False)

    class Meta:
        unique_together = ('enrollment', 'date')

    def __str__(self):
        return f"Attendance for {self.student.first_name} in {self.batch.name} on {self.date}"

    def save(self, *args, **kwargs):
        is_new = self.pk is None
        super().save(*args, **kwargs)

        if not is_new:
            # Nothing extra to do for existing attendance updates
            return

        # ── First attendance triggers enrollment start ────────────────────────
        if not self.enrollment.enrollment_started:
            from django.utils import timezone
            from datetime import timedelta

            update_fields = {
                'enrollment_started': True,
                'start_date': self.date,
                'date_first_attendance': timezone.now(),
            }
            if self.enrollment.enrollment_type == 'DURATION_BASED':
                update_fields['end_date'] = self.date + timedelta(days=30)

            # Atomic update — safe for concurrent saves
            Enrollment.objects.filter(pk=self.enrollment.pk).update(**update_fields)
            logger.info(
                "Enrollment %s started on first attendance (student_id=%s)",
                self.enrollment.pk, self.student.pk,
            )

        # ── Session deduction — uses F() to avoid race condition ─────────────
        if self.enrollment.enrollment_type == 'SESSION_BASED' and not self.is_session_deducted:
            Enrollment.objects.filter(pk=self.enrollment.pk).update(
                sessions_attended=F('sessions_attended') + 1
            )
            # Mark this attendance record as deducted in one round-trip
            Attendance.objects.filter(pk=self.pk).update(is_session_deducted=True)
            logger.debug(
                "Session deducted for enrollment %s (student_id=%s)",
                self.enrollment.pk, self.student.pk,
            )

        # ── Auto-create fee transaction for POST_PAID batches ────────────────
        if self.batch.payment_policy == 'POST_PAID' and self.batch.fee_per_session is not None:
            from payments.models import FeeTransaction
            FeeTransaction.objects.create(
                organization=self.organization,
                student=self.student,
                enrollment=self.enrollment,
                amount=self.batch.fee_per_session,
                due_date=self.date,
                is_paid=False,
            )
            logger.debug(
                "FeeTransaction created for student_id=%s, batch_id=%s, amount=%s",
                self.student.pk, self.batch.pk, self.batch.fee_per_session,
            )