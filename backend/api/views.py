from rest_framework.views import APIView
from rest_framework.response import Response
from .ai_utils import process_bot_request
from rest_framework.permissions import IsAuthenticated
from rest_framework.authentication import TokenAuthentication

class AIChatBotView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.user_type != 'ACADEMY_ADMIN':
            return Response({"error": "Only Academy Admins can use this feature."}, status=403)

        try:
            profile = request.user.academy_admin_profile
            org_id = profile.organization_id
            org_name = profile.organization.academy_name
        except Exception:
            return Response({"error": "Admin profile not found."}, status=400)

        query = request.data.get('query')
        if not query:
            return Response({"error": "No query provided"}, status=400)
            
        bot_message = process_bot_request(query, org_id, org_name)
        return Response({"response": bot_message})