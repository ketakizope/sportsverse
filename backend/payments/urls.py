# backend/accounts/urls.py

from django.urls import path
from . import views

urlpatterns = [
    path('', views.dummy_view),  # Just a placeholder route
]
