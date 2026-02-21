# backend/payments/urls.py

from django.urls import path
from .views import student_payment_history

urlpatterns = [
    # Student self-serve payment history
    path('my-history/', student_payment_history, name='student-payment-history'),
]
