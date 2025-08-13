# sportsverse/backend/payments/admin.py

from django.contrib import admin
from .models import FeeTransaction, CoachSalaryTransaction

@admin.register(FeeTransaction)
class FeeTransactionAdmin(admin.ModelAdmin):
    list_display = ('student', 'organization', 'amount', 'is_paid', 'due_date', 'transaction_date', 'payment_method')
    search_fields = ('student__first_name', 'student__last_name', 'organization__academy_name', 'receipt_number')
    list_filter = ('organization', 'is_paid', 'payment_method', 'transaction_date')
    date_hierarchy = 'transaction_date'
    raw_id_fields = ('student', 'enrollment') # For large number of students/enrollments

@admin.register(CoachSalaryTransaction)
class CoachSalaryTransactionAdmin(admin.ModelAdmin):
    list_display = ('coach', 'organization', 'amount', 'is_paid', 'payment_period', 'transaction_date')
    search_fields = ('coach__user__first_name', 'coach__user__last_name', 'organization__academy_name', 'payment_period')
    list_filter = ('organization', 'is_paid', 'transaction_date')
    date_hierarchy = 'transaction_date'
    raw_id_fields = ('coach', 'paid_by') # For large number of coaches/users