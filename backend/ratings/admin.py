"""
ratings/admin.py
Django admin registrations for DUPR rating models.
"""
from django.contrib import admin
from django.utils.html import format_html

from .models import PlayerRatingProfile, RatingMatch, RatingAudit


@admin.register(PlayerRatingProfile)
class PlayerRatingProfileAdmin(admin.ModelAdmin):
    list_display = (
        "user", "sport", "organization",
        "dupr_rating_singles", "dupr_rating_doubles",
        "reliability_bar", "matches_played_singles",
        "matches_played_doubles", "is_provisional_singles",
        "last_synced_at",
    )
    list_filter = ("sport", "organization")
    search_fields = ("user__username", "user__email", "user__first_name")
    readonly_fields = ("created_at", "updated_at", "last_synced_at")
    ordering = ("-dupr_rating_singles",)

    @admin.display(description="Reliability")
    def reliability_bar(self, obj):
        pct = obj.reliability
        color = "#e55" if pct < 40 else "#e90" if pct < 70 else "#3a3"
        return format_html(
            '<div style="width:80px;background:#eee;border-radius:3px;">'
            '<div style="width:{pct}%;background:{color};height:12px;border-radius:3px;">'
            '</div></div>&nbsp;{pct}%',
            pct=pct, color=color,
        )


@admin.register(RatingMatch)
class RatingMatchAdmin(admin.ModelAdmin):
    list_display = (
        "id", "date", "format", "importance", "status",
        "validated", "processed_at", "submitted_by", "organization",
    )
    list_filter = ("format", "importance", "status", "validated", "organization", "sport")
    search_fields = ("submitted_by__username", "submitted_by__email")
    readonly_fields = ("dedup_hash", "created_at", "updated_at", "processed_at")
    ordering = ("-date", "id")
    actions = ["mark_validated"]

    @admin.action(description="Mark selected matches as Validated")
    def mark_validated(self, request, queryset):
        updated = queryset.filter(status="PENDING").update(
            validated=True, status="VALIDATED"
        )
        self.message_user(request, f"{updated} match(es) marked as validated.")


@admin.register(RatingAudit)
class RatingAuditAdmin(admin.ModelAdmin):
    list_display = (
        "id", "player", "match", "format",
        "old_rating", "new_rating", "delta_display",
        "method", "rolled_back", "created_at",
    )
    list_filter = ("method", "format", "rolled_back")
    search_fields = ("player__username", "player__email")
    readonly_fields = ("created_at",)
    ordering = ("-created_at",)

    @admin.display(description="Delta", ordering="delta")
    def delta_display(self, obj):
        sign = "+" if obj.delta >= 0 else ""
        color = "#3a3" if obj.delta >= 0 else "#e55"
        return format_html(
            '<span style="color:{color};font-weight:bold;">{sign}{delta}</span>',
            color=color, sign=sign, delta=obj.delta,
        )
