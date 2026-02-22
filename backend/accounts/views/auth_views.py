# accounts/views/auth_views.py — Authentication, registration, password management, /me/

import json
import logging
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from django.conf import settings
from django.utils.http import urlsafe_base64_encode, urlsafe_base64_decode
from django.utils.encoding import force_bytes, force_str
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import CustomUser, AcademyAdminProfile
from accounts.serializers import RegisterAcademySerializer, LoginSerializer, UserSerializer

logger = logging.getLogger(__name__)


class MeView(APIView):
    """
    GET /api/accounts/me/
    Validates the supplied token and returns minimal user + profile info.
    Returns 401 if no token, expired token, or invalid token.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        data = {
            'id': user.pk,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name,
            'last_name': user.last_name,
            'user_type': user.user_type,
            'must_change_password': user.must_change_password,
            'profile_details': {},
        }

        if user.user_type == 'ACADEMY_ADMIN' and hasattr(user, 'academy_admin_profile'):
            org = user.academy_admin_profile.organization
            data['profile_details'] = {
                'organization_id': org.pk,
                'organization_name': org.academy_name,
                'slug': org.slug,
            }
        elif user.user_type == 'COACH' and hasattr(user, 'coach_profile'):
            org = user.coach_profile.organization
            data['profile_details'] = {
                'organization_id': org.pk,
                'organization_name': org.academy_name,
            }
        elif user.user_type == 'STUDENT' and hasattr(user, 'student_profile'):
            student = user.student_profile
            data['profile_details'] = {
                'organization_id': student.organization.pk,
                'organization_name': student.organization.academy_name,
                'student_id': student.pk,
            }

        logger.debug("MeView: token validated for user_id=%s type=%s", user.pk, user.user_type)
        return Response(data, status=status.HTTP_200_OK)


class RegisterAcademyView(APIView):
    """POST /api/accounts/register-academy/ — public registration for a new academy."""
    permission_classes = [AllowAny]

    def post(self, request):
        logger.info("RegisterAcademyView: registration request received")
        data = dict(request.data.lists())

        for key, value_list in data.items():
            if not key.startswith('sports_offered_ids[') and len(value_list) == 1:
                data[key] = value_list[0]

        if any(key.startswith('sports_offered_ids[') for key in data.keys()):
            sports_ids = []
            for key in list(data.keys()):
                if key.startswith('sports_offered_ids['):
                    try:
                        value = data[key][0] if isinstance(data[key], list) else data[key]
                        sports_ids.append(int(value))
                        del data[key]
                    except (ValueError, TypeError, IndexError):
                        logger.error("RegisterAcademyView: invalid sports ID: %s", data[key])
                        return Response(
                            {'sports_offered_ids': [f'Invalid sports ID: {data[key]}']},
                            status=status.HTTP_400_BAD_REQUEST,
                        )
            data['sports_offered_ids'] = sports_ids
        elif 'sports_offered_ids' in data and isinstance(data['sports_offered_ids'], str):
            try:
                data['sports_offered_ids'] = json.loads(data['sports_offered_ids'])
            except json.JSONDecodeError:
                return Response(
                    {'sports_offered_ids': ['Invalid JSON format for sports_offered_ids']},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        serializer = RegisterAcademySerializer(data=data)
        if serializer.is_valid():
            organization = serializer.save()
            logger.info("RegisterAcademyView: academy '%s' registered", organization.academy_name)
            return Response(
                {
                    "message": "Academy registered successfully. Academy Admin user created.",
                    "academy_id": organization.id,
                    "academy_name": organization.academy_name,
                    "admin_username": serializer.validated_data['admin_username'],
                },
                status=status.HTTP_201_CREATED,
            )

        logger.warning("RegisterAcademyView: validation errors: %s", serializer.errors)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    """POST /api/accounts/login/ — all user types."""
    permission_classes = [AllowAny]

    def post(self, request):
        logger.info("LoginView: login attempt received")
        serializer = LoginSerializer(data=request.data, context={'request': request})

        if not serializer.is_valid():
            logger.warning("LoginView: validation failed: %s", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        user = serializer.validated_data['user']
        token, _ = Token.objects.get_or_create(user=user)

        profile_data = {}
        if user.user_type == 'ACADEMY_ADMIN' and hasattr(user, 'academy_admin_profile'):
            profile_data = {
                'organization_id': user.academy_admin_profile.organization.id,
                'organization_name': user.academy_admin_profile.organization.academy_name,
                'slug': user.academy_admin_profile.organization.slug,
            }
        elif user.user_type == 'COACH' and hasattr(user, 'coach_profile'):
            profile_data = {
                'organization_id': user.coach_profile.organization.id,
                'organization_name': user.coach_profile.organization.academy_name,
                'assigned_branches': list(
                    user.coach_profile.assignments
                    .values_list('branch_id', flat=True)
                    .distinct()
                ),
            }
        elif user.user_type == 'STUDENT' and hasattr(user, 'student_profile'):
            student = user.student_profile
            profile_data = {
                'organization_id': student.organization.id,
                'organization_name': student.organization.academy_name,
                'student_id': student.id,
            }

        if user.user_type == 'STUDENT' and hasattr(user, 'student_profile'):
            student = user.student_profile
            user_data = {
                'id': student.id,
                'username': user.username,
                'email': student.email,
                'first_name': student.first_name,
                'last_name': student.last_name,
                'phone_number': student.phone_number,
                'gender': student.gender,
                'date_of_birth': student.date_of_birth.isoformat() if student.date_of_birth else None,
                'user_type': user.user_type,
                'address': student.address,
                'parent_name': student.parent_name,
                'parent_phone_number': student.parent_phone_number,
                'parent_email': student.parent_email,
                'profile_photo': (
                    f"{request.build_absolute_uri('/')[:-1]}{student.profile_photo.url}"
                    if student.profile_photo else None
                ),
            }
        else:
            user_data = UserSerializer(user).data

        logger.info("LoginView: user_id=%s type=%s logged in", user.pk, user.user_type)
        return Response(
            {
                "token": token.key,
                "user": user_data,
                "profile_details": profile_data,
                "must_change_password": user.must_change_password,
            },
            status=status.HTTP_200_OK,
        )


class PasswordResetRequestView(APIView):
    """POST /api/accounts/password-reset/ — request password reset email."""
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = CustomUser.objects.get(email=email)
        except CustomUser.DoesNotExist:
            # Don't reveal whether the email exists
            return Response(
                {'message': 'If your email is registered, you will receive a password reset link.'},
                status=status.HTTP_200_OK,
            )

        token = default_token_generator.make_token(user)
        uid = urlsafe_base64_encode(force_bytes(user.pk))
        reset_link = f"sportsverse://reset-password/{uid}/{token}/"

        subject = 'Password Reset — SportsVerse'
        message = (
            f"Hello {user.first_name},\n\n"
            f"Click the link below to reset your password:\n{reset_link}\n\n"
            "If you did not request this, please ignore this email.\n\n"
            "— The SportsVerse Team"
        )

        email_sent = False
        try:
            send_mail(subject, message, settings.DEFAULT_FROM_EMAIL, [email], fail_silently=False)
            email_sent = True
            logger.info("PasswordResetRequestView: reset email sent to %s", email)
        except Exception as exc:
            logger.warning("PasswordResetRequestView: failed to send email — %s", exc)

        return Response(
            {
                'message': 'If your email is registered, you will receive a password reset link.',
                'reset_link': reset_link if not email_sent else None,
                'note': 'Email not configured; use the reset_link above' if not email_sent else None,
            },
            status=status.HTTP_200_OK,
        )


class PasswordResetConfirmView(APIView):
    """POST /api/accounts/password-reset-confirm/ — confirm password reset."""
    permission_classes = [AllowAny]

    def post(self, request):
        uid = request.data.get('uid')
        token = request.data.get('token')
        new_password = request.data.get('new_password')

        if not all([uid, token, new_password]):
            return Response(
                {'error': 'UID, token, and new password are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if len(new_password) < 8:
            return Response(
                {'error': 'Password must be at least 8 characters long'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user_id = force_str(urlsafe_base64_decode(uid))
            user = CustomUser.objects.get(pk=user_id)
            if default_token_generator.check_token(user, token):
                user.set_password(new_password)
                user.save()
                logger.info("PasswordResetConfirmView: password reset for user_id=%s", user.pk)
                return Response(
                    {'message': 'Password has been reset successfully.'},
                    status=status.HTTP_200_OK,
                )
            return Response({'error': 'Invalid or expired token'}, status=status.HTTP_400_BAD_REQUEST)

        except (TypeError, ValueError, OverflowError, CustomUser.DoesNotExist):
            return Response({'error': 'Invalid reset link'}, status=status.HTTP_400_BAD_REQUEST)


class ChangePasswordView(APIView):
    """POST /api/accounts/change-password/ — authenticated password change."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        current_password = request.data.get('current_password')
        new_password = request.data.get('new_password')

        if not all([current_password, new_password]):
            return Response(
                {'error': 'Current password and new password are required'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if not request.user.check_password(current_password):
            return Response({'error': 'Current password is incorrect'}, status=status.HTTP_400_BAD_REQUEST)
        if len(new_password) < 8:
            return Response({'error': 'Password must be at least 8 characters'}, status=status.HTTP_400_BAD_REQUEST)
        if current_password == new_password:
            return Response(
                {'error': 'New password must be different from current password'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        request.user.set_password(new_password)
        request.user.must_change_password = False
        request.user.save()
        logger.info("ChangePasswordView: password changed for user_id=%s", request.user.pk)
        return Response({'message': 'Password changed successfully'}, status=status.HTTP_200_OK)
