# sportsverse/backend/communications/models.py

from django.db import models
from organizations.models import Organization
from accounts.models import CustomUser

class Notification(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='notifications')
    sender = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, blank=True, related_name='sent_notifications')
    subject = models.CharField(max_length=255)
    message = models.TextField()
    recipients = models.ManyToManyField(CustomUser, related_name='received_notifications', blank=True) # Targeted recipients
    sent_to_all_students = models.BooleanField(default=False)
    sent_to_all_coaches = models.BooleanField(default=False)
    sent_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification: {self.subject} ({self.organization.academy_name})"

    class Meta:
        ordering = ['-sent_at']