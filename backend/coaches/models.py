import logging
from django.db import models
from django.conf import settings
from organizations.models import Organization, Branch, Batch, Sport

logger = logging.getLogger(__name__)


class CoachProfile(models.Model):
    """One-to-one link from a CustomUser (user_type=COACH) to coach-specific data."""
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='coach_profile',
    )
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='coaches')

    phone_number = models.CharField(max_length=15, blank=True)
    specialization = models.CharField(
        max_length=100, blank=True, help_text="e.g. Tennis, Yoga, etc."
    )
    bio = models.TextField(blank=True)
    profile_photo = models.ImageField(upload_to='coach_profiles/', blank=True, null=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"Coach: {self.user.first_name} {self.user.last_name}".strip() or f"Coach #{self.pk}"


class CoachAssignment(models.Model):
    """Links a CoachProfile to a specific Batch (scoped to a Branch and Sport)."""
    coach = models.ForeignKey(CoachProfile, on_delete=models.CASCADE, related_name='assignments')
    branch = models.ForeignKey(Branch, on_delete=models.CASCADE)
    sport = models.ForeignKey(Sport, on_delete=models.CASCADE)
    batch = models.ForeignKey(Batch, on_delete=models.CASCADE)
    date_assigned = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('coach', 'batch')

    def __str__(self):
        return f"{self.coach} → {self.batch.name}"