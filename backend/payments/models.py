import logging
from datetime import date as date_type

from django.db import models
from organizations.models import Organization, Enrollment
from accounts.models import StudentProfile, CustomUser
from coaches.models import CoachProfile

logger = logging.getLogger(__name__)


class FeeTransaction(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='fee_transactions')
    student = models.ForeignKey(StudentProfile, on_delete=models.CASCADE, related_name='fee_transactions')
    enrollment = models.ForeignKey(
        Enrollment, on_delete=models.SET_NULL, null=True, blank=True, related_name='fee_transactions'
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)

    # Changed from auto_now_add so it can be manually set when recording payments
    transaction_date = models.DateField(default=date_type.today)

    due_date = models.DateField(null=True, blank=True)
    is_paid = models.BooleanField(default=False)
    payment_method = models.CharField(
        max_length=50,
        choices=[('Cash', 'Cash'), ('Online', 'Online')],
        default='Cash',
    )
    receipt_number = models.CharField(max_length=100, unique=True, blank=True, null=True)

    # Tracks when fee was actually collected (separate from transaction creation date)
    paid_date = models.DateTimeField(
        null=True, blank=True,
        help_text="Timestamp when the payment was marked as paid"
    )

    class Meta:
        ordering = ['-transaction_date']

    def __str__(self):
        status = "PAID" if self.is_paid else "UNPAID"
        return f"FeeTransaction #{self.pk} — {self.student} — ₹{self.amount} [{status}]"


class CoachSalaryTransaction(models.Model):
    organization = models.ForeignKey(Organization, on_delete=models.CASCADE, related_name='coach_salary_transactions')
    coach = models.ForeignKey(CoachProfile, on_delete=models.CASCADE, related_name='salary_transactions')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    transaction_date = models.DateField(auto_now_add=True)
    payment_period = models.CharField(max_length=100)
    is_paid = models.BooleanField(default=True)
    paid_by = models.ForeignKey(CustomUser, on_delete=models.SET_NULL, null=True, related_name='coach_payments_made')

    def __str__(self):
        return f"Salary for {self.coach} — {self.payment_period}"