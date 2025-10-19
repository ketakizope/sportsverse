from django.shortcuts import render

# Create your views here.
# backend/accounts/views.py

from django.http import HttpResponse
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.db.models import Sum

from organizations.models import Batch, Branch, Sport, Enrollment
from accounts.models import StudentProfile
from .models import FeeTransaction

def dummy_view(request):
    return HttpResponse("Accounts app is working!")


class BatchFinancialsSummaryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        branch_id = request.query_params.get('branch')
        sport_id = request.query_params.get('sport')
        batch_id = request.query_params.get('batch')

        if not (branch_id and sport_id and batch_id):
            return Response({
                'detail': 'branch, sport and batch are required query params'
            }, status=status.HTTP_400_BAD_REQUEST)

        batch = get_object_or_404(Batch, pk=batch_id)

        # Basic validation
        if str(batch.branch_id) != str(branch_id) or str(batch.sport_id) != str(sport_id):
            return Response({'detail': 'Batch does not belong to provided branch/sport'}, status=status.HTTP_400_BAD_REQUEST)

        # Organization security: only allow academy admin of same org
        if not hasattr(request.user, 'academy_admin_profile'):
            return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)
        if batch.organization_id != request.user.academy_admin_profile.organization_id:
            return Response({'detail': 'Permission denied'}, status=status.HTTP_403_FORBIDDEN)

        # Get active enrollments for this batch
        enrollments = Enrollment.objects.filter(batch=batch, is_active=True).select_related('student')

        students_data = []
        for enrollment in enrollments:
            student = enrollment.student

            # Sessions left (only for session-based)
            sessions_left = None
            total_sessions = None
            if enrollment.enrollment_type == 'SESSION_BASED' and enrollment.total_sessions is not None:
                sessions_left = max(0, (enrollment.total_sessions or 0) - (enrollment.sessions_attended or 0))
                total_sessions = enrollment.total_sessions or 0

            # Unpaid sessions equals count of unpaid FeeTransactions for this enrollment in POST_PAID policy
            unpaid_sessions = 0
            if batch.payment_policy == 'POST_PAID':
                unpaid_sessions = FeeTransaction.objects.filter(enrollment=enrollment, is_paid=False).count()

            # Payment history
            transactions = FeeTransaction.objects.filter(student=student, enrollment=enrollment).order_by('-transaction_date')
            payment_history = [
                {
                    'amount': float(t.amount),
                    'transaction_date': t.transaction_date.isoformat(),
                    'due_date': t.due_date.isoformat() if t.due_date else None,
                    'is_paid': t.is_paid,
                    'payment_method': t.payment_method,
                    'receipt_number': t.receipt_number,
                }
                for t in transactions
            ]

            students_data.append({
                'student_id': student.id,
                'first_name': student.first_name,
                'last_name': student.last_name,
                'sessions_left': sessions_left,
                'total_sessions': total_sessions,
                'sessions_left_display': (f"{sessions_left}/{total_sessions}" if (sessions_left is not None and total_sessions is not None) else None),
                'unpaid_sessions': unpaid_sessions,
                'payment_history': payment_history,
            })

        data = {
            'batch': {
                'id': batch.id,
                'name': batch.name,
                'fee_per_session': float(batch.fee_per_session) if batch.fee_per_session is not None else None,
                'payment_policy': batch.payment_policy,
            },
            'students': students_data,
        }

        return Response(data)
