# sportsverse/backend/accounts/urls.py

from django.urls import path
from .views import (
    RegisterAcademyView, 
    LoginView, 
    RegisterCoachStudentStaffView,
    PasswordResetRequestView,
    PasswordResetConfirmView,
    ChangePasswordView,
    CoachListView,
    CoachAssignmentView,
    StudentFinancialsView,
    StudentListView
)

urlpatterns = [
    path('register-academy/', RegisterAcademyView.as_view(), name='register-academy'),
    path('login/', LoginView.as_view(), name='login'),
    path('register-user/', RegisterCoachStudentStaffView.as_view(), name='register-coach-student-staff'),
    path('password-reset/', PasswordResetRequestView.as_view(), name='password-reset'),
    path('password-reset-confirm/', PasswordResetConfirmView.as_view(), name='password-reset-confirm'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    
    # Coach management endpoints
    path('coaches/', CoachListView.as_view(), name='coach-list'),
    path('coaches/<int:coach_id>/assign-branches/', CoachAssignmentView.as_view(), name='coach-assignment'),

    # Student endpoints
    path('students/', StudentListView.as_view(), name='student-list'),
    path('students/<int:student_id>/financials/', StudentFinancialsView.as_view(), name='student-financials'),
]