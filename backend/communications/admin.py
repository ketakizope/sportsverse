# sportsverse/backend/communications/admin.py

from django.contrib import admin
from .models import Notification

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('subject', 'organization', 'sender', 'sent_to_all_students', 'sent_to_all_coaches', 'sent_at')
    search_fields = ('subject', 'message', 'organization__academy_name', 'sender__username')
    list_filter = ('organization', 'sent_to_all_students', 'sent_to_all_coaches', 'sent_at')
    filter_horizontal = ('recipients',) # For ManyToMany field
    date_hierarchy = 'sent_at'
    raw_id_fields = ('sender',) # Use raw ID for sender (CustomUser)