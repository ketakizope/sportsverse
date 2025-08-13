# sportsverse/backend/payments/models.py

from django.db import models
from organizations.models import Organization, Enrollment
from accounts.models import StudentProfile, CoachProfile, StaffProfile, CustomUser

class FeeTransaction(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='fee_transactions')
    student = models.ForeignKey(StudentProfile, on_delete=models.CASCADE, related_name='fee_transactions')
    enrollment = models.ForeignKey(Enrollment, on_delete=models.SET_NULL, null=True, blank=True, related_name='fee_transactions') # Link to specific enrollment
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_date = models.DateField(auto_now_add=True)
    due_date = models.DateField(null=True, blank=True)
    is_paid = models.BooleanField(default=False)
    payment_method = models.CharField(max_length=50, blank=True, null=True) # e.g., 'Cash', 'Online', 'Card'
    receipt_number = models.CharField(max_length=100, unique=True, blank=True, null=True)
    
    # You might add a field for the fee plan/type if you have different pricing models
    # fee_plan = models.ForeignKey(FeePlan, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return f"Fee: {self.amount} for {self.student.first_name} ({'Paid' if self.is_paid else 'Due'})"

    class Meta:
        ordering = ['-transaction_date']

class CoachSalaryTransaction(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='coach_salary_transactions')
    coach = models.ForeignKey(CoachProfile, on_delete=models.CASCADE, related_name='salary_transactions')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_date = models.DateField(auto_now_add=True)
    payment_period = models.CharField(max_length=100, help_text="e.g., 'July 2024'") # Or start_date, end_date for period
    is_paid = models.BooleanField(default=False)
    paid_by = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, blank=True, related_name='coach_payments_made')

    def __str__(self):
        return f"Salary: {self.amount} for {self.coach.user.get_full_name} ({'Paid' if self.is_paid else 'Due'})"

    class Meta:
        ordering = ['-transaction_date']

# You could also add StaffSalaryTransaction if needed, similar to CoachSalaryTransaction