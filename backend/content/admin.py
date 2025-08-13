# sportsverse/backend/content/admin.py

from django.contrib import admin
from .models import ProgressVideo, DietPlan

@admin.register(ProgressVideo)
class ProgressVideoAdmin(admin.ModelAdmin):
    list_display = ('title', 'organization', 'uploaded_by', 'uploaded_at', 'display_assigned_students')
    search_fields = ('title', 'description', 'organization__academy_name', 'uploaded_by__username')
    list_filter = ('organization', 'uploaded_at')
    filter_horizontal = ('assigned_to_students',) # For ManyToMany field
    date_hierarchy = 'uploaded_at'
    raw_id_fields = ('uploaded_by',) # For user who uploaded

    def display_assigned_students(self, obj):
        return ", ".join([f"{s.first_name} {s.last_name}" for s in obj.assigned_to_students.all()])
    display_assigned_students.short_description = 'Assigned Students'

@admin.register(DietPlan)
class DietPlanAdmin(admin.ModelAdmin):
    list_display = ('title', 'organization', 'uploaded_by', 'uploaded_at', 'display_assigned_students')
    search_fields = ('title', 'description', 'organization__academy_name', 'uploaded_by__username')
    list_filter = ('organization', 'uploaded_at')
    filter_horizontal = ('assigned_to_students',) # For ManyToMany field
    date_hierarchy = 'uploaded_at'
    raw_id_fields = ('uploaded_by',) # For user who uploaded

    def display_assigned_students(self, obj):
        return ", ".join([f"{s.first_name} {s.last_name}" for s in obj.assigned_to_students.all()])
    display_assigned_students.short_description = 'Assigned Students'