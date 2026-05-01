import google.generativeai as genai
from django.conf import settings
from accounts.models import StudentProfile
from payments.models import FeeTransaction

# Ensure API key is configured
try:
    genai.configure(api_key=settings.GEMINI_API_KEY)
except AttributeError:
    # Fallback to the hardcoded key for now, but in production this should be in settings
    genai.configure(api_key="AIzaSyDbiN-A2MheTeOgJ0paJgr_mUMQjb_NR0Y")

def process_bot_request(user_text, organization_id, organization_name):
    """
    Process the bot request with context-aware tools locked to the organization_id.
    """
    
    # 1. Define secure closures that capture organization_id
    def get_student_count() -> str:
        """Returns the total number of enrolled students in the academy."""
        count = StudentProfile.objects.filter(organization_id=organization_id).count()
        return f"There are {count} students currently registered in {organization_name}."

    def get_recent_payments(limit: int = 5) -> str:
        """Returns the latest fee payments collected in the academy."""
        payments = FeeTransaction.objects.filter(
            organization_id=organization_id, 
            is_paid=True
        ).order_by('-paid_date')[:limit]
        
        if not payments.exists():
            return "No recent payments found."
            
        result = "Recent payments:\n"
        for p in payments:
            date_str = p.paid_date.strftime('%Y-%m-%d') if p.paid_date else p.transaction_date.strftime('%Y-%m-%d')
            result += f"- ₹{p.amount} from {p.student.first_name} {p.student.last_name} on {date_str} via {p.payment_method}\n"
        return result

    # 2. Define the model with the secure tools and system instruction
    model = genai.GenerativeModel(
        model_name='gemini-flash-latest',  # Verified working for 2026 environment
        tools=[get_student_count, get_recent_payments],
        system_instruction=(
            f"You are the official AI assistant exclusively for {organization_name}. "
            "Use the provided tools to query the database and answer the user's questions about the academy. "
            "Be polite, professional, and concise. Do not answer questions about other academies."
        )
    )

    # 3. Process the query
    try:
        chat = model.start_chat(enable_automatic_function_calling=True)
        response = chat.send_message(user_text)
        return response.text
    except Exception as e:
        return f"I'm sorry, I encountered an error: {str(e)}"