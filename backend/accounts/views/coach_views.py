# accounts/views/coach_views.py — Coach dashboard endpoint

import logging
from datetime import date, timedelta

from django.db.models import Sum, Q
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from coaches.models import CoachProfile, CoachAssignment
from organizations.models import Attendance, Enrollment
from payments.models import CoachSalaryTransaction

logger = logging.getLogger(__name__)

# Mapping from JSON schedule_details day abbreviations → Python weekday integer
_DAY_MAP = {
    'Mon': 0, 'Tue': 1, 'Wed': 2, 'Thu': 3,
    'Fri': 4, 'Sat': 5, 'Sun': 6,
}


def _upcoming_sessions(assignments, days_ahead: int = 7) -> list:
    """
    Given a list of CoachAssignment ORM objects (with prefetched batch),
    return a list of dicts describing sessions that fall within the next
    `days_ahead` calendar days.

    Each batch stores its schedule in:
        batch.schedule_details = {
            "days": ["Mon", "Wed"],
            "start_time": "18:00",
            "end_time": "19:00",
        }
    """
    today = date.today()
    upcoming = []

    for assignment in assignments:
        batch = assignment.batch
        schedule = batch.schedule_details or {}
        day_names = schedule.get('days', [])
        start_time = schedule.get('start_time', '')
        end_time = schedule.get('end_time', '')

        for offset in range(days_ahead):
            check_date = today + timedelta(days=offset)
            day_name = check_date.strftime('%a')  # 'Mon', 'Tue', …
            if day_name in day_names:
                upcoming.append({
                    'date': check_date.isoformat(),
                    'day': day_name,
                    'batch_id': batch.pk,
                    'batch_name': batch.name,
                    'branch_id': assignment.branch.pk,
                    'branch_name': assignment.branch.name,
                    'sport': batch.sport.name if hasattr(batch, 'sport') else '',
                    'start_time': start_time,
                    'end_time': end_time,
                })

    upcoming.sort(key=lambda s: s['date'])
    return upcoming


class CoachDashboardView(APIView):
    """
    GET /api/accounts/coach-dashboard/

    Returns a comprehensive dashboard payload for the authenticated COACH:
      - coach_profile: name, specialisation, organisation, photo URL
      - assignments: active batch/branch/sport assignments (prefetched)
      - upcoming_sessions: next-7-days schedule derived from batch.schedule_details
      - attendance_summary: attendances marked by this coach in the last 30 days
      - pending_salary: total unpaid CoachSalaryTransaction amount
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user

        # ── Role enforcement ──────────────────────────────────────────────────
        if user.user_type != 'COACH':
            logger.warning(
                "CoachDashboardView: access denied for user_id=%s type=%s",
                user.pk, user.user_type,
            )
            return Response(
                {'error': 'Access denied. This endpoint is for coaches only.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        if not hasattr(user, 'coach_profile'):
            logger.error("CoachDashboardView: COACH user_id=%s has no CoachProfile", user.pk)
            return Response(
                {'error': 'Coach profile not found. Please contact your admin.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        coach = user.coach_profile  # type: CoachProfile
        org = coach.organization

        # ── Coach profile summary ─────────────────────────────────────────────
        coach_profile_data = {
            'id': coach.pk,
            'full_name': f"{user.first_name} {user.last_name}".strip() or user.username,
            'email': user.email,
            'phone_number': coach.phone_number,
            'specialization': coach.specialization,
            'bio': coach.bio,
            'is_active': coach.is_active,
            'organization_id': org.pk,
            'organization_name': org.academy_name,
            'profile_photo': (
                f"{request.build_absolute_uri('/')[:-1]}{coach.profile_photo.url}"
                if coach.profile_photo else None
            ),
        }

        # ── Active assignments (prefetched in one query) ──────────────────────
        assignments_qs = (
            CoachAssignment.objects
            .filter(coach=coach)
            .select_related('branch', 'batch', 'batch__sport', 'batch__branch')
        )

        assignments_data = [
            {
                'assignment_id': a.pk,
                'branch_id': a.branch.pk,
                'branch_name': a.branch.name,
                'batch_id': a.batch.pk,
                'batch_name': a.batch.name,
                'sport_id': a.batch.sport.pk,
                'sport_name': a.batch.sport.name,
                'schedule': a.batch.schedule_details,
                'fee_per_session': float(a.batch.fee_per_session) if a.batch.fee_per_session else None,
                'payment_policy': a.batch.payment_policy,
                'date_assigned': a.date_assigned.isoformat(),
            }
            for a in assignments_qs
        ]

        # ── Upcoming sessions (next 7 days) ───────────────────────────────────
        upcoming = _upcoming_sessions(assignments_qs, days_ahead=7)

        # ── Attendance summary (last 30 days, marked by this coach) ───────────
        thirty_days_ago = date.today() - timedelta(days=30)
        marked_attendances = (
            Attendance.objects
            .filter(marked_by=user, date__gte=thirty_days_ago)
            .select_related('batch', 'enrollment__batch')
        )

        total_marked = marked_attendances.count()

        # Group by batch
        batch_breakdown = {}
        for att in marked_attendances:
            batch_name = att.batch.name
            batch_breakdown[batch_name] = batch_breakdown.get(batch_name, 0) + 1

        attendance_summary = {
            'period_days': 30,
            'total_sessions_marked': total_marked,
            'by_batch': [
                {'batch_name': bname, 'sessions_marked': count}
                for bname, count in batch_breakdown.items()
            ],
        }

        # ── Pending salary ────────────────────────────────────────────────────
        pending_salary_agg = (
            CoachSalaryTransaction.objects
            .filter(coach=coach, is_paid=False)
            .aggregate(total=Sum('amount'))
        )
        pending_salary = float(pending_salary_agg['total'] or 0)

        logger.info(
            "CoachDashboardView: served dashboard for coach_id=%s assignments=%d",
            coach.pk, len(assignments_data),
        )

        return Response(
            {
                'coach_profile': coach_profile_data,
                'assignments': assignments_data,
                'upcoming_sessions': upcoming,
                'attendance_summary': attendance_summary,
                'pending_salary': {
                    'amount': pending_salary,
                    'currency': 'INR',
                },
            },
            status=status.HTTP_200_OK,
        )
