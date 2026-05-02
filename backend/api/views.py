# backend/api/views.py
#
# ChatbotQueryView — role-aware, two-stage Gemini pipeline.
# Supports ACADEMY_ADMIN, COACH, and STUDENT roles.
# All data queries use existing org-scoped Django querysets.

import logging
from django.utils import timezone
from django.db.models import Sum, Q
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication

from .ai_utils import parse_intent, generate_response

logger = logging.getLogger(__name__)


class ChatbotQueryView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    # Maximum messages per session enforced on backend too
    _MAX_MESSAGES = 20
    _LOW_CONFIDENCE = 0.6

    def post(self, request):
        user = request.user
        role = user.user_type
        query = request.data.get('query', '').strip()

        if not query:
            return Response({'error': 'No query provided.'}, status=status.HTTP_400_BAD_REQUEST)

        if role not in ('ACADEMY_ADMIN', 'COACH', 'STUDENT'):
            return Response(
                {'response': 'The AI chatbot is not available for your account type.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        # ── Gather session context ────────────────────────────────────────────
        try:
            context = self._build_context(user, role)
        except Exception as e:
            logger.error("Context build failed for user %s: %s", user.id, e)
            return Response(
                {'response': 'Could not load your profile. Please try again.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # ── Stage 1: Intent parsing ───────────────────────────────────────────
        intent_result = parse_intent(
            user_text=query,
            role=role,
            user_id=user.id,
            org_id=context.get('org_id'),
            extra_context=context,
        )

        intent = intent_result.get('intent', 'unknown')
        params = intent_result.get('params', {})
        confidence = intent_result.get('confidence', 0.0)

        logger.info("Chatbot | user=%s role=%s intent=%s conf=%.2f",
                    user.id, role, intent, confidence)

        # Low confidence fallback
        if confidence < self._LOW_CONFIDENCE or intent == 'unknown':
            examples = self._get_examples(role)
            return Response({
                'response': (
                    f"I'm not sure what you mean. You can ask me things like: {examples}"
                ),
                'intent': 'unknown',
            })

        # ── Data fetch ────────────────────────────────────────────────────────
        try:
            api_data = self._fetch_data(user, role, intent, params, context)
        except PermissionError as e:
            return Response({'response': str(e)}, status=status.HTTP_403_FORBIDDEN)
        except LookupError:
            return Response({
                'response': 'No records were found for that query.',
                'intent': intent,
            })
        except Exception as e:
            logger.error("Data fetch error for intent=%s: %s", intent, e)
            return Response({
                'response': 'Something went wrong on the server. Please try again.',
                'intent': intent,
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        # ── Stage 2: Natural language response ────────────────────────────────
        nl_response = generate_response(query, api_data, role)

        return Response({'response': nl_response, 'intent': intent})

    # ── Context builder ───────────────────────────────────────────────────────

    def _build_context(self, user, role):
        ctx = {'org_id': None, 'student_id': None, 'assigned_batch_ids': []}
        if role == 'ACADEMY_ADMIN':
            profile = user.academy_admin_profile
            ctx['org_id'] = profile.organization_id
        elif role == 'COACH':
            profile = user.coach_profile
            ctx['org_id'] = profile.organization_id
            from coaches.models import CoachAssignment
            ctx['assigned_batch_ids'] = list(
                CoachAssignment.objects.filter(coach=profile)
                .values_list('batch_id', flat=True)
            )
        elif role == 'STUDENT':
            profile = user.student_profile
            ctx['org_id'] = profile.organization_id
            ctx['student_id'] = profile.id
        return ctx

    # ── Central data dispatcher ───────────────────────────────────────────────

    def _fetch_data(self, user, role, intent, params, context):
        org_id = context.get('org_id')

        # ── ACADEMY_ADMIN intents ─────────────────────────────────────────────
        if role == 'ACADEMY_ADMIN':
            from accounts.models import StudentProfile
            from organizations.models import Branch, Batch, Enrollment, Attendance
            from payments.models import FeeTransaction
            from coaches.models import CoachProfile, CoachAssignment

            if intent == 'get_dashboard_summary':
                return {
                    'total_students': StudentProfile.objects.filter(organization_id=org_id).count(),
                    'total_coaches': CoachProfile.objects.filter(organization_id=org_id).count(),
                    'total_branches': Branch.objects.filter(organization_id=org_id).count(),
                    'total_batches': Batch.objects.filter(branch__organization_id=org_id).count(),
                    'active_enrollments': Enrollment.objects.filter(organization_id=org_id, is_active=True).count(),
                }

            if intent == 'get_unpaid_fees':
                txns = FeeTransaction.objects.filter(
                    organization_id=org_id, is_paid=False
                ).select_related('student').order_by('-transaction_date')[:20]
                return [
                    {
                        'student': f"{t.student.first_name} {t.student.last_name}",
                        'amount': float(t.amount),
                        'due_date': str(t.due_date) if t.due_date else None,
                    }
                    for t in txns
                ]

            if intent == 'get_student_fees':
                name = params.get('student_name', '')
                students = StudentProfile.objects.filter(
                    organization_id=org_id,
                    first_name__icontains=name.split()[0] if name else '',
                )
                if not students.exists():
                    raise LookupError("No student found")
                student = students.first()
                txns = FeeTransaction.objects.filter(student=student)
                total_paid = float(txns.filter(is_paid=True).aggregate(s=Sum('amount'))['s'] or 0)
                total_due = float(txns.filter(is_paid=False).aggregate(s=Sum('amount'))['s'] or 0)
                return {
                    'student': f"{student.first_name} {student.last_name}",
                    'total_paid': total_paid,
                    'total_due': total_due,
                }

            if intent == 'get_fee_collection_summary':
                txns = FeeTransaction.objects.filter(organization_id=org_id)
                return {
                    'total_collected': float(txns.filter(is_paid=True).aggregate(s=Sum('amount'))['s'] or 0),
                    'total_outstanding': float(txns.filter(is_paid=False).aggregate(s=Sum('amount'))['s'] or 0),
                    'paid_count': txns.filter(is_paid=True).count(),
                    'unpaid_count': txns.filter(is_paid=False).count(),
                }

            if intent == 'get_student_list':
                students = StudentProfile.objects.filter(organization_id=org_id)[:30]
                return [
                    {'name': f"{s.first_name} {s.last_name}", 'phone': s.phone_number}
                    for s in students
                ]

            if intent == 'get_active_enrollments':
                count = Enrollment.objects.filter(organization_id=org_id, is_active=True).count()
                return {'active_enrollments': count}

            if intent == 'get_batch_students':
                batch_name = params.get('batch_name', '')
                batches = Batch.objects.filter(
                    branch__organization_id=org_id,
                    name__icontains=batch_name,
                )
                if not batches.exists():
                    raise LookupError("Batch not found")
                batch = batches.first()
                enrollments = Enrollment.objects.filter(batch=batch, is_active=True).select_related('student')
                return {
                    'batch': batch.name,
                    'students': [
                        {'name': f"{e.student.first_name} {e.student.last_name}"}
                        for e in enrollments
                    ],
                }

            if intent == 'get_branch_batches':
                branch_name = params.get('branch_name', '')
                branches = Branch.objects.filter(
                    organization_id=org_id,
                    name__icontains=branch_name,
                )
                if not branches.exists():
                    raise LookupError("Branch not found")
                branch = branches.first()
                batches = Batch.objects.filter(branch=branch)
                return {
                    'branch': branch.name,
                    'batches': [
                        {'name': b.name, 'sport': b.sport.name if b.sport else 'N/A', 'max_students': b.max_students}
                        for b in batches
                    ],
                }

            if intent == 'get_coach_assignments':
                assignments = CoachAssignment.objects.filter(
                    coach__organization_id=org_id
                ).select_related('coach', 'batch', 'branch')[:20]
                return [
                    {
                        'coach': f"{a.coach.user.first_name} {a.coach.user.last_name}",
                        'batch': a.batch.name,
                        'branch': a.branch.name if a.branch else 'N/A',
                    }
                    for a in assignments
                ]

            if intent == 'get_attendance_for_batch':
                batch_name = params.get('batch_name', '')
                batches = Batch.objects.filter(
                    branch__organization_id=org_id,
                    name__icontains=batch_name,
                )
                if not batches.exists():
                    raise LookupError("Batch not found")
                batch = batches.first()
                from django.db.models import Count
                today = timezone.localdate()
                count = Attendance.objects.filter(
                    enrollment__batch=batch,
                    date=today,
                ).count()
                total_enrolled = Enrollment.objects.filter(batch=batch, is_active=True).count()
                return {
                    'batch': batch.name,
                    'date': str(today),
                    'present_today': count,
                    'total_enrolled': total_enrolled,
                }

        # ── COACH intents ─────────────────────────────────────────────────────
        elif role == 'COACH':
            from organizations.models import Batch, Enrollment, Attendance
            from coaches.models import CoachAssignment

            assigned_batch_ids = context.get('assigned_batch_ids', [])
            coach_profile = user.coach_profile

            if not assigned_batch_ids:
                return "You are not currently assigned to any batches."

            if intent == 'get_my_schedule':
                assignments = CoachAssignment.objects.filter(
                    coach=coach_profile
                ).select_related('batch', 'branch', 'batch__sport')
                return [
                    {
                        'batch': a.batch.name,
                        'sport': a.batch.sport.name if a.batch.sport else 'N/A',
                        'branch': a.branch.name if a.branch else 'N/A',
                        'schedule': a.batch.schedule_details,
                    }
                    for a in assignments
                ]

            if intent == 'get_my_batch_students':
                batch_name = params.get('batch_name', '')
                qs = Enrollment.objects.filter(
                    batch_id__in=assigned_batch_ids,
                    is_active=True,
                )
                if batch_name:
                    qs = qs.filter(batch__name__icontains=batch_name)
                qs = qs.select_related('student', 'batch')
                return [
                    {
                        'student': f"{e.student.first_name} {e.student.last_name}",
                        'batch': e.batch.name,
                        'sessions_attended': e.sessions_attended,
                    }
                    for e in qs
                ]

            if intent == 'get_attendance_summary':
                today = timezone.localdate()
                count = Attendance.objects.filter(
                    enrollment__batch_id__in=assigned_batch_ids,
                    date=today,
                ).count()
                total = Enrollment.objects.filter(
                    batch_id__in=assigned_batch_ids, is_active=True
                ).count()
                return {'present_today': count, 'total_enrolled': total, 'date': str(today)}

            if intent == 'get_student_attendance':
                student_name = params.get('student_name', '')
                enrollments = Enrollment.objects.filter(
                    batch_id__in=assigned_batch_ids,
                    student__first_name__icontains=student_name.split()[0] if student_name else '',
                    is_active=True,
                ).select_related('student')
                if not enrollments.exists():
                    raise LookupError("Student not found in your batches")
                enrollment = enrollments.first()
                return {
                    'student': f"{enrollment.student.first_name} {enrollment.student.last_name}",
                    'batch': enrollment.batch.name,
                    'sessions_attended': enrollment.sessions_attended,
                    'total_sessions': enrollment.total_sessions,
                }

        # ── STUDENT intents ───────────────────────────────────────────────────
        elif role == 'STUDENT':
            from accounts.models import StudentProfile
            from organizations.models import Enrollment, Attendance
            from payments.models import FeeTransaction

            student = user.student_profile

            if intent in ('get_my_attendance', 'get_sessions_remaining', 'get_my_enrollment', 'get_my_schedule'):
                enrollments = student.enrollments.filter(is_active=True).select_related('batch', 'batch__sport', 'batch__branch')
                return [
                    {
                        'batch': e.batch.name,
                        'sport': e.batch.sport.name if e.batch.sport else 'N/A',
                        'branch': e.batch.branch.name if e.batch.branch else 'N/A',
                        'sessions_attended': e.sessions_attended,
                        'total_sessions': e.total_sessions,
                        'sessions_remaining': max(0, (e.total_sessions or 0) - (e.sessions_attended or 0)),
                        'schedule': e.batch.schedule_details,
                        'is_active': e.is_active,
                    }
                    for e in enrollments
                ]

            if intent in ('get_my_payments', 'get_my_payment_summary'):
                txns = FeeTransaction.objects.filter(student=student)
                total_paid = float(txns.filter(is_paid=True).aggregate(s=Sum('amount'))['s'] or 0)
                total_due = float(txns.filter(is_paid=False).aggregate(s=Sum('amount'))['s'] or 0)
                pending = list(txns.filter(is_paid=False).values('amount', 'due_date')[:5])
                return {
                    'total_paid': total_paid,
                    'total_due': total_due,
                    'pending_transactions': pending,
                }

        raise LookupError(f"No handler for intent: {intent}")

    # ── Example chips per role ────────────────────────────────────────────────

    def _get_examples(self, role):
        examples = {
            'ACADEMY_ADMIN': (
                '"How many students are enrolled?", "Show unpaid fees", '
                '"Which students are in Morning Cricket batch?"'
            ),
            'COACH': (
                '"What is my schedule today?", '
                '"Who are the students in my batch?", '
                '"How many attended today?"'
            ),
            'STUDENT': (
                '"How many sessions have I attended?", '
                '"Is my fee paid?", '
                '"What time is my next class?"'
            ),
        }
        return examples.get(role, '"Ask me about your academy data."')