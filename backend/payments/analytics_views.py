from django.db.models import Sum, F
from django.db.models.functions import TruncMonth, TruncQuarter, TruncYear
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from .models import FeeTransaction, CoachSalaryTransaction

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def organization_financial_analytics(request):
    # 1. Identify the Organization (Multi-tenancy check)
    # Assuming your User model has a link to Organization
    org = request.user.organization 
    
    # Get timeframe from request (month, quarter, or year)
    period = request.GET.get('period', 'month') 
    
    if period == 'year':
        trunc_func = TruncYear
    elif period == 'quarter':
        trunc_func = TruncQuarter
    else:
        trunc_func = TruncMonth

    # 2. Aggregate Fees Collected (Revenue)
    fees_data = FeeTransaction.objects.filter(organization=org, is_paid=True) \
        .annotate(date_period=trunc_func('transaction_date')) \
        .values('date_period') \
        .annotate(total_fees=Sum('amount')) \
        .order_by('date_period')

    # 3. Aggregate Coach Salaries (Expenses)
    salary_data = CoachSalaryTransaction.objects.filter(organization=org, is_paid=True) \
        .annotate(date_period=trunc_func('transaction_date')) \
        .values('date_period') \
        .annotate(total_salary=Sum('amount')) \
        .order_by('date_period')

    # 4. Merge data for Flutter
    # Logic to combine fees and salaries into one timeline
    response_data = []
    # (I will provide the full merging logic in the next step when we code)
    
    return JsonResponse({"status": "success", "data": list(fees_data)})