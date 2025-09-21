# sportsverse/backend/accounts/models.py

from django.contrib.auth.models import AbstractUser
from django.db import models
from organizations.models import Organization, Branch # Import Organization and Branch from your organizations app

class CustomUser(AbstractUser):
    USER_TYPE_CHOICES = (
        ('PLATFORM_ADMIN', 'Platform Admin'),
        ('ACADEMY_ADMIN', 'Academy Admin'),
        ('COACH', 'Coach'),
        ('STUDENT', 'Student'),
        ('STAFF', 'Staff') # For other staff besides coaches
    )
    user_type = models.CharField(max_length=20, choices=USER_TYPE_CHOICES, default='STUDENT')
    phone_number = models.CharField(max_length=20, blank=True, null=True, unique=True)
    gender = models.CharField(max_length=1, choices=[('M', 'Male'), ('F', 'Female'), ('O', 'Other')], blank=True, null=True)
    date_of_birth = models.DateField(null=True, blank=True)
    must_change_password = models.BooleanField(default=False, help_text="Forces user to change password on next login")

    # Add other common fields here if needed across all user types

    def __str__(self):
        return self.username

    @property
    def get_full_name(self):
        return f"{self.first_name} {self.last_name}".strip() or self.username


class AcademyAdminProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='academy_admin_profile')
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='admin_profiles')

    def __str__(self):
        return f"Admin for {self.organization.academy_name}"

class CoachProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='coach_profile')
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='coach_profiles')
    branches = models.ManyToManyField(Branch, related_name='coaches_assigned') # Coaches can be assigned to multiple branches
    resume = models.FileField(upload_to='coach_resumes/', blank=True, null=True)

    def __str__(self):
        return f"{self.user.get_full_name} (Coach at {self.organization.academy_name})"

class StudentProfile(models.Model):
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='student_profile', null=True, blank=True)
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='student_profiles')
    # If student might not have a login account immediately, capture basics here:
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(unique=True, null=True, blank=True) # Can be null if younger students don't have email
    phone_number = models.CharField(max_length=20, blank=True) # Redundant if on CustomUser, but useful for students without user account
    date_of_birth = models.DateField()
    address = models.TextField(blank=True)
    gender = models.CharField(max_length=1, choices=[('M', 'Male'), ('F', 'Female'), ('O', 'Other')], blank=True)
    parent_name = models.CharField(max_length=200, blank=True)
    parent_phone_number = models.CharField(max_length=20, blank=True)
    parent_email = models.EmailField(blank=True)

    def __str__(self):
        return f"{self.first_name} {self.last_name} (Student at {self.organization.academy_name})"

class StaffProfile(models.Model): # For other administrative staff etc.
    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='staff_profile')
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='staff_profiles')
    # Add other staff-specific fields like 'role', 'department' etc.

    def __str__(self):
        return f"{self.user.get_full_name} (Staff at {self.organization.academy_name})"