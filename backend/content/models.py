# sportsverse/backend/content/models.py

from django.db import models
from organizations.models import Organization
from accounts.models import StudentProfile, CustomUser

class ProgressVideo(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='progress_videos')
    uploaded_by = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, blank=True, related_name='uploaded_videos')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    video_file = models.FileField(upload_to='progress_videos/')
    assigned_to_students = models.ManyToManyField(StudentProfile, related_name='progress_videos', blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Video: {self.title} ({self.organization.academy_name})"

    class Meta:
        ordering = ['-uploaded_at']

class DietPlan(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='diet_plans')
    uploaded_by = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, blank=True, related_name='uploaded_diet_plans')
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    pdf_file = models.FileField(upload_to='diet_plans/')
    assigned_to_students = models.ManyToManyField(StudentProfile, related_name='diet_plans', blank=True)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Diet Plan: {self.title} ({self.organization.academy_name})"

    class Meta:
        ordering = ['-uploaded_at']