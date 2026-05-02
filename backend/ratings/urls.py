"""
ratings/urls.py

URL routing for the DUPR internal rating system.
"""
from django.urls import path
from ratings.views import (
    MatchSubmitView,
    MatchVerificationView,
    PendingMatchesView,
    MatchHistoryView,
    StudentRatingsView,
    MyRatingHistoryView,
    ForecastMatchView,
)

app_name = "ratings"

urlpatterns = [
    # New Match Lifecycle Flow
    path('matches/history/', MatchHistoryView.as_view(), name='match-history'),
    path('matches/pending/', PendingMatchesView.as_view(), name='pending-matches'),
    path('matches/', MatchSubmitView.as_view(), name='match-submit'),
    path('matches/<int:pk>/verify/', MatchVerificationView.as_view(), name='match-verify'),
    
    # Rating Lookups
    path('students/', StudentRatingsView.as_view(), name='student-ratings'),
    path('my-history/', MyRatingHistoryView.as_view(), name='my-history'),
    path('forecast/', ForecastMatchView.as_view(), name='forecast'),
]
