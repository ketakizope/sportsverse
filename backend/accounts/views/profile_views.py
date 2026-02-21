# accounts/views/profile_views.py — Student profile management, photo upload, face encoding

import json
import logging
import os
import traceback
from datetime import datetime

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

logger = logging.getLogger(__name__)


class StudentProfileUpdateView(APIView):
    """PUT /api/accounts/profile/ — update the authenticated student's profile fields."""
    permission_classes = [IsAuthenticated]

    def put(self, request):
        if not hasattr(request.user, 'student_profile'):
            return Response(
                {'error': 'Access denied. Student profile required.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        student = request.user.student_profile
        logger.debug(
            "StudentProfileUpdateView: user_id=%s email=%s updating profile",
            request.user.pk, request.user.email,
        )

        try:
            updatable_fields = [
                'first_name', 'last_name', 'email', 'phone_number',
                'address', 'gender', 'parent_name', 'parent_phone_number', 'parent_email',
            ]
            for field in updatable_fields:
                if field in request.data:
                    logger.debug(
                        "StudentProfileUpdateView: updating %s → %s", field, request.data[field]
                    )
                    setattr(student, field, request.data[field])

            if 'date_of_birth' in request.data:
                student.date_of_birth = datetime.strptime(request.data['date_of_birth'], '%Y-%m-%d').date()

            student.save()
            student.refresh_from_db()
            logger.info("StudentProfileUpdateView: student_id=%s profile saved", student.pk)

            profile_data = {
                'id': student.pk,
                'username': request.user.username,
                'first_name': student.first_name,
                'last_name': student.last_name,
                'email': student.email,
                'phone_number': student.phone_number,
                'date_of_birth': student.date_of_birth.isoformat() if student.date_of_birth else None,
                'gender': student.gender,
                'user_type': request.user.user_type,
                'address': student.address,
                'parent_name': student.parent_name,
                'parent_phone_number': student.parent_phone_number,
                'parent_email': student.parent_email,
                'profile_photo': (
                    f"{request.build_absolute_uri('/')[:-1]}{student.profile_photo.url}"
                    if student.profile_photo else None
                ),
                'organization': (
                    {'id': student.organization.pk, 'academy_name': student.organization.academy_name}
                    if student.organization else None
                ),
            }
            return Response(profile_data, status=status.HTTP_200_OK)

        except Exception as exc:
            logger.error("StudentProfileUpdateView: error — %s\n%s", exc, traceback.format_exc())
            return Response({'error': f'Error updating profile: {exc}'}, status=status.HTTP_400_BAD_REQUEST)


class StudentProfileDebugView(APIView):
    """
    GET /api/accounts/profile/debug/ — compare ORM vs raw DB values for a student profile.
    Useful for troubleshooting caching issues.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not hasattr(request.user, 'student_profile'):
            return Response({'error': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)
        student = request.user.student_profile

        from django.db import connection
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT first_name, last_name, email, phone_number, address, "
                "gender, parent_name, parent_phone_number, parent_email "
                "FROM accounts_studentprofile WHERE id = %s",
                [student.pk],
            )
            row = cursor.fetchone()

        return Response(
            {
                'student_id': student.pk,
                'django_orm_data': {
                    'first_name': student.first_name,
                    'last_name': student.last_name,
                    'email': student.email,
                    'phone_number': student.phone_number,
                    'address': student.address,
                    'gender': student.gender,
                    'parent_name': student.parent_name,
                    'parent_phone_number': student.parent_phone_number,
                    'parent_email': student.parent_email,
                },
                'raw_db_data': dict(
                    zip(
                        ['first_name', 'last_name', 'email', 'phone_number',
                         'address', 'gender', 'parent_name', 'parent_phone_number', 'parent_email'],
                        row or [None] * 9,
                    )
                ),
            }
        )


class StudentProfilePhotoUploadView(APIView):
    """POST /api/accounts/profile/photo/ — upload a new profile photo."""
    permission_classes = [IsAuthenticated]

    ALLOWED_TYPES = {'image/jpeg', 'image/png', 'image/gif', 'application/octet-stream'}
    ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png', 'gif'}
    MAX_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB

    def post(self, request):
        if not hasattr(request.user, 'student_profile'):
            return Response({'error': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)

        student = request.user.student_profile
        logger.debug("StudentProfilePhotoUploadView: student_id=%s upload started", student.pk)

        try:
            if 'profile_photo' not in request.FILES:
                return Response({'error': 'No profile_photo in request'}, status=status.HTTP_400_BAD_REQUEST)

            photo = request.FILES['profile_photo']
            ext = photo.name.lower().rsplit('.', 1)[-1] if '.' in photo.name else ''

            if photo.content_type not in self.ALLOWED_TYPES and ext not in self.ALLOWED_EXTENSIONS:
                return Response(
                    {'error': 'Invalid file type. Only JPEG, PNG, and GIF are allowed.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if photo.size > self.MAX_SIZE_BYTES:
                return Response(
                    {'error': 'File too large. Maximum size is 5 MB.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            student.profile_photo = photo
            student.save()
            student.refresh_from_db()

            photo_url = None
            if student.profile_photo:
                photo_url = f"{request.build_absolute_uri('/')[:-1]}{student.profile_photo.url}"
                logger.info("StudentProfilePhotoUploadView: student_id=%s photo saved → %s", student.pk, photo_url)

            return Response(
                {'profile_photo': photo_url, 'message': 'Profile photo uploaded successfully'},
                status=status.HTTP_200_OK,
            )

        except Exception as exc:
            logger.error("StudentProfilePhotoUploadView: error — %s\n%s", exc, traceback.format_exc())
            return Response({'error': f'Error uploading photo: {exc}'}, status=status.HTTP_400_BAD_REQUEST)


class StudentFaceEncodingView(APIView):
    """POST /api/accounts/face-encoding/ — generate + store face encoding for a student."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not hasattr(request.user, 'student_profile'):
            return Response({'error': 'Access denied'}, status=status.HTTP_403_FORBIDDEN)

        student = request.user.student_profile
        logger.debug("StudentFaceEncodingView: student_id=%s encoding request", student.pk)

        try:
            if 'face_image' not in request.FILES:
                return Response({'error': 'No face_image provided'}, status=status.HTTP_400_BAD_REQUEST)

            from accounts.facial_recognition import extract_embedding_from_bytes
            face_encoding = extract_embedding_from_bytes(request.FILES['face_image'].read())

            if face_encoding is None:
                return Response(
                    {'error': 'No face detected. Ensure your face is clearly visible.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            student.face_encoding = json.dumps(face_encoding.tolist())
            student.save()
            logger.info("StudentFaceEncodingView: encoding stored for student_id=%s", student.pk)

            return Response(
                {
                    'message': 'Face encoding generated successfully',
                    'encoding_length': len(face_encoding),
                    'student_id': student.pk,
                    'student_name': f"{student.first_name} {student.last_name}",
                },
                status=status.HTTP_200_OK,
            )

        except Exception as exc:
            logger.error("StudentFaceEncodingView: error — %s\n%s", exc, traceback.format_exc())
            return Response({'error': f'Face encoding error: {exc}'}, status=status.HTTP_400_BAD_REQUEST)
