from django.urls import path
from .views import ChatbotQueryView

urlpatterns = [
    # ── AI Chatbot ────────────────────────────────────────────────────────────
    # POST /api/chatbot/query/
    # Body: { "query": "..." }
    # Requires: Authorization: Token <token>
    # Returns: { "response": "...", "intent": "..." }
    path('chatbot/query/', ChatbotQueryView.as_view(), name='chatbot-query'),
]