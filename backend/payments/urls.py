# backend/accounts/urls.py

from django.urls import path
from . import views

urlpatterns = [
    path('', views.dummy_view),
    path('batch-financials/', views.BatchFinancialsSummaryView.as_view(), name='batch-financials-summary'),
]
