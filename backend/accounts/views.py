# sportsverse/backend/accounts/views.py

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.authtoken.models import Token # For token-based authentication
from django.contrib.auth import login # For session-based login if preferred
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from django.conf import settings
import json
import logging

logger = logging.getLogger(__name__)

from .serializers import RegisterAcademySerializer, LoginSerializer, RegisterCoachStudentStaffSerializer, UserSerializer, CoachAssignmentSerializer
from .models import CustomUser, AcademyAdminProfile, CoachProfile
from organizations.models import Organization

class RegisterAcademyView(APIView):
    """
    API endpoint for a Platform Admin (or public) to register a new Academy/Organization.
    """
    permission_classes = [AllowAny] # Allow anyone to register a new academy

    def post(self, request):
        # Log the incoming data for debugging
        logger.info(f"Registration request data: {request.data}")
        
        # Convert QueryDict to regular dict for easier manipulation
        data = dict(request.data.lists())  # This preserves lists for fields that have multiple values
        
        # Convert single-value lists to single values for most fields
        for key, value_list in data.items():
            if not key.startswith('sports_offered_ids[') and len(value_list) == 1:
                data[key] = value_list[0]
        
        # Handle sports_offered_ids if sent as individual multipart fields
        if any(key.startswith('sports_offered_ids[') for key in data.keys()):
            sports_ids = []
            for key in list(data.keys()):
                if key.startswith('sports_offered_ids['):
                    try:
                        # Extract the value from the list
                        value = data[key][0] if isinstance(data[key], list) else data[key]
                        sports_ids.append(int(value))
                        # Remove the individual field
                        del data[key]
                    except (ValueError, TypeError, IndexError):
                        logger.error(f"Invalid sports ID: {data[key]}")
                        return Response({
                            'sports_offered_ids': [f'Invalid sports ID: {data[key]}']
                        }, status=status.HTTP_400_BAD_REQUEST)
            data['sports_offered_ids'] = sports_ids
            logger.info(f"Converted sports_offered_ids to: {sports_ids}")
        
        # Handle sports_offered_ids if sent as JSON string
        elif 'sports_offered_ids' in data and isinstance(data['sports_offered_ids'], str):
            try:
                data['sports_offered_ids'] = json.loads(data['sports_offered_ids'])
            except json.JSONDecodeError:
                logger.error(f"Failed to parse sports_offered_ids: {data['sports_offered_ids']}")
                return Response({
                    'sports_offered_ids': ['Invalid JSON format for sports_offered_ids']
                }, status=status.HTTP_400_BAD_REQUEST)
        
        logger.info(f"Final data being sent to serializer: {data}")
        
        serializer = RegisterAcademySerializer(data=data)
        if serializer.is_valid():
            organization = serializer.save()
            return Response({
                "message": "Academy registered successfully. Academy Admin user created.",
                "academy_id": organization.id,
                "academy_name": organization.academy_name,
                "admin_username": serializer.validated_data['admin_username']
            }, status=status.HTTP_201_CREATED)
        
        logger.error(f"Registration validation errors: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    """
    API endpoint for all user types to log in.
    Returns user details and an authentication token.
    """
    permission_classes = [AllowAny] # Allow anyone to attempt login

    def post(self, request):
        serializer = LoginSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            user = serializer.validated_data['user']
            # If using session authentication (for web admin), uncomment:
            # login(request, user)

            # For token authentication (common for APIs/Flutter)
            token, created = Token.objects.get_or_create(user=user)

            # Get associated profile details based on user_type
            profile_data = {}
            if user.user_type == 'ACADEMY_ADMIN':
                if hasattr(user, 'academy_admin_profile'):
                    profile_data = {
                        'organization_id': user.academy_admin_profile.organization.id,
                        'organization_name': user.academy_admin_profile.organization.academy_name,
                        'slug': user.academy_admin_profile.organization.slug
                    }
            elif user.user_type == 'COACH':
                if hasattr(user, 'coach_profile'):
                    profile_data = {
                        'organization_id': user.coach_profile.organization.id,
                        'organization_name': user.coach_profile.organization.academy_name,
                        'assigned_branches': [branch.id for branch in user.coach_profile.branches.all()]
                    }
            elif user.user_type == 'STUDENT':
                if hasattr(user, 'student_profile'):
                    profile_data = {
                        'organization_id': user.student_profile.organization.id,
                        'organization_name': user.student_profile.organization.academy_name,
                        'student_id': user.student_profile.id
                    }
            elif user.user_type == 'STAFF':
                if hasattr(user, 'staff_profile'):
                    profile_data = {
                        'organization_id': user.staff_profile.organization.id,
                        'organization_name': user.staff_profile.organization.academy_name
                    }
            
            return Response({
                "token": token.key,
                "user": UserSerializer(user).data,
                "profile_details": profile_data,
                "must_change_password": user.must_change_password
            }, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class RegisterCoachStudentStaffView(APIView):
    """
    API endpoint for an authenticated Academy Admin to register Coaches, Students, or Staff
    within their organization.
    """
    permission_classes = [IsAuthenticated] # Only authenticated users can access this
    # You might add a custom permission here to ensure only Academy Admins can use this
    # e.g., permission_classes = [IsAuthenticated, IsAcademyAdmin]

    def post(self, request):
        # Log incoming data for debugging
        logger.info(f"User registration request data: {request.data}")
        
        # Ensure the logged-in user is an Academy Admin
        if not hasattr(request.user, 'academy_admin_profile'):
            return Response({"detail": "Only Academy Admins can register other users."},
                            status=status.HTTP_403_FORBIDDEN)

        serializer = RegisterCoachStudentStaffSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            try:
                user = serializer.save()
                logger.info(f"User {user.username} registered successfully as {user.user_type}")
                return Response({
                    "message": f"{user.user_type} user registered successfully.",
                    "user_id": user.id,
                    "username": user.username
                }, status=status.HTTP_201_CREATED)
            except Exception as e:
                logger.error(f"Error creating user: {str(e)}")
                return Response({
                    "detail": f"Error creating user: {str(e)}"
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        else:
            logger.error(f"User registration validation errors: {serializer.errors}")
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class PasswordResetRequestView(APIView):
    """
    API endpoint to request password reset via email.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        
        if not email:
            return Response({
                'error': 'Email is required'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = CustomUser.objects.get(email=email)
        except CustomUser.DoesNotExist:
            # For security, don't reveal if email exists or not
            return Response({
                'message': 'If your email is registered, you will receive a password reset link.'
            }, status=status.HTTP_200_OK)

        # Generate token
        token = default_token_generator.make_token(user)
        uid = urlsafe_base64_encode(force_bytes(user.pk))

        # Create reset link
        reset_link = f"http://localhost:3000/reset-password/{uid}/{token}/"

        # For testing purposes, let's just return the reset link
        # In production, you would send an email
        try:
            # Attempt to send email (this might fail if email settings are not configured)
            subject = 'Password Reset - SportsVerse'
            message = f'''
Hello {user.first_name},

You requested a password reset for your SportsVerse account.

Click the link below to reset your password:
{reset_link}

If you did not request this reset, please ignore this email.

The SportsVerse Team
            '''
            
            # Try to send email, but don't fail if it doesn't work
            try:
                send_mail(
                    subject,
                    message,
                    settings.DEFAULT_FROM_EMAIL,
                    [email],
                    fail_silently=False,
                )
                email_sent = True
            except Exception as e:
                logger.warning(f"Failed to send email: {e}")
                email_sent = False

            return Response({
                'message': 'If your email is registered, you will receive a password reset link.',
                'reset_link': reset_link if not email_sent else None,  # Only return link if email failed
                'note': 'Since email is not configured, use the reset_link above' if not email_sent else None
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Password reset error: {e}")
            return Response({
                'error': 'An error occurred while processing your request'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class PasswordResetConfirmView(APIView):
    """
    API endpoint to confirm password reset with token.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        uid = request.data.get('uid')
        token = request.data.get('token')
        new_password = request.data.get('new_password')

        if not all([uid, token, new_password]):
            return Response({
                'error': 'UID, token, and new password are required'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Validate password strength
        if len(new_password) < 8:
            return Response({
                'error': 'Password must be at least 8 characters long'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Decode the user ID
            user_id = force_str(urlsafe_base64_decode(uid))
            user = CustomUser.objects.get(pk=user_id)

            # Verify the token
            if default_token_generator.check_token(user, token):
                # Set the new password
                user.set_password(new_password)
                user.save()

                return Response({
                    'message': 'Password has been reset successfully. You can now log in with your new password.'
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'error': 'Invalid or expired token'
                }, status=status.HTTP_400_BAD_REQUEST)

        except (TypeError, ValueError, OverflowError, CustomUser.DoesNotExist):
            return Response({
                'error': 'Invalid reset link'
            }, status=status.HTTP_400_BAD_REQUEST)


class ChangePasswordView(APIView):
    """
    API endpoint for authenticated users to change their password.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        current_password = request.data.get('current_password')
        new_password = request.data.get('new_password')

        if not all([current_password, new_password]):
            return Response({
                'error': 'Current password and new password are required'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Validate current password
        if not request.user.check_password(current_password):
            return Response({
                'error': 'Current password is incorrect'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Validate new password strength
        if len(new_password) < 8:
            return Response({
                'error': 'New password must be at least 8 characters long'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Check if new password is different from current
        if current_password == new_password:
            return Response({
                'error': 'New password must be different from current password'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Set the new password and reset must_change_password flag
        request.user.set_password(new_password)
        request.user.must_change_password = False
        request.user.save()

        return Response({
            'message': 'Password changed successfully'
        }, status=status.HTTP_200_OK)

class CoachListView(APIView):
    """
    API endpoint for Academy Admin to list coaches in their organization.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not hasattr(request.user, 'academy_admin_profile'):
            return Response({"detail": "Only Academy Admins can access this endpoint."}, status=status.HTTP_403_FORBIDDEN)

        organization = request.user.academy_admin_profile.organization
        coaches = CoachProfile.objects.filter(organization=organization).select_related('user')
        
        serializer = CoachAssignmentSerializer(coaches, many=True, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)


class CoachAssignmentView(APIView):
    """
    API endpoint for Academy Admin to assign branches to coaches.
    PUT: Update coach's branch assignments
    """
    permission_classes = [IsAuthenticated]

    def put(self, request, coach_id):
        if not hasattr(request.user, 'academy_admin_profile'):
            return Response({"detail": "Only Academy Admins can assign coaches."}, status=status.HTTP_403_FORBIDDEN)

        organization = request.user.academy_admin_profile.organization
        
        try:
            coach_profile = CoachProfile.objects.get(id=coach_id, organization=organization)
        except CoachProfile.DoesNotExist:
            return Response({"detail": "Coach not found in your organization."}, status=status.HTTP_404_NOT_FOUND)

        serializer = CoachAssignmentSerializer(coach_profile, data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response({
                "message": "Coach branch assignments updated successfully.",
                "coach": serializer.data
            }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)