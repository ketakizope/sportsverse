# sportsverse/backend/accounts/serializers.py

from rest_framework import serializers
from django.db import transaction
from django.contrib.auth import authenticate
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError

from .models import CustomUser, AcademyAdminProfile, CoachProfile, StudentProfile, StaffProfile
from organizations.models import Organization, Sport, Branch, Batch, Enrollment # Import necessary models

class UserSerializer(serializers.ModelSerializer):
    """Serializer for the CustomUser model."""
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'phone_number', 'gender', 'date_of_birth', 'user_type']
        read_only_fields = ['id', 'user_type'] # User type is set during creation, not by user directly

class RegisterAcademySerializer(serializers.Serializer):
    """
    Serializer for registering a new Organization and its Academy Admin.
    This is used by the Platform Admin or a public registration page.
    """
    # Organization fields
    organization_full_name = serializers.CharField(max_length=255, write_only=True, help_text="Legal name of the academy/organization")
    organization_academy_name = serializers.CharField(max_length=255, write_only=True, help_text="Display name for the academy")
    organization_location = serializers.CharField(style={'base_template': 'textarea.html'}, write_only=True, help_text="Physical address of the academy")
    organization_mobile_number = serializers.CharField(max_length=20, write_only=True, help_text="Official contact number for the academy")
    organization_email_address = serializers.EmailField(write_only=True, help_text="Official business email for the academy (e.g., info@youracademy.com)")
    organization_slug = serializers.SlugField(max_length=100, write_only=True, help_text="URL identifier (e.g., 'elite-tennis' for elite-tennis.sportsverse.com)")
    sports_offered_ids = serializers.ListField(
        child=serializers.IntegerField(), write_only=True,
        help_text="List of Sport IDs that this organization offers."
    )
    # Admin user fields for the new academy
    admin_username = serializers.CharField(max_length=150, write_only=True, help_text="Username for the academy admin to login")
    admin_email = serializers.EmailField(write_only=True, required=False, allow_blank=True, help_text="Personal email of the admin user (optional - if not provided, organization email will be used)")
    admin_first_name = serializers.CharField(max_length=150, write_only=True, help_text="First name of the admin user")
    admin_last_name = serializers.CharField(max_length=150, write_only=True, help_text="Last name of the admin user")
    admin_password = serializers.CharField(write_only=True, style={'input_type': 'password'}, help_text="Password for the admin user account")

    def validate_organization_email_address(self, value):
        if Organization.objects.filter(email_address=value).exists():
            raise serializers.ValidationError("An organization with this email already exists.")
        return value

    def validate_organization_slug(self, value):
        if Organization.objects.filter(slug=value).exists():
            raise serializers.ValidationError("This academy URL identifier is already taken.")
        return value

    def validate_admin_username(self, value):
        if CustomUser.objects.filter(username=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        return value

    def validate_admin_email(self, value):
        # If admin email is provided and not empty
        if value:
            # Get organization email from the data
            org_email = self.initial_data.get('organization_email_address')
            
            # Allow admin email to be the same as organization email
            if value != org_email and CustomUser.objects.filter(email=value).exists():
                raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_admin_password(self, value):
        try:
            validate_password(value)
        except DjangoValidationError as e:
            raise serializers.ValidationError(list(e.messages))
        return value

    def create(self, validated_data):
        with transaction.atomic():
            # Create Organization
            organization = Organization.objects.create(
                full_name=validated_data['organization_full_name'],
                academy_name=validated_data['organization_academy_name'],
                location=validated_data['organization_location'],
                mobile_number=validated_data['organization_mobile_number'],
                email_address=validated_data['organization_email_address'],
                slug=validated_data['organization_slug'],
                is_active=True, # New academies are active by default
                subscription_plan='FREE_TRIAL' # Default to free trial
            )
            # Add sports offered
            sports_ids = validated_data.get('sports_offered_ids', [])
            sports = Sport.objects.filter(id__in=sports_ids)
            organization.sports_offered.set(sports)

            # Create Academy Admin User
            # Use organization email if admin email is not provided
            admin_email = validated_data.get('admin_email') or validated_data['organization_email_address']
            
            admin_user = CustomUser.objects.create_user(
                username=validated_data['admin_username'],
                email=admin_email,
                password=validated_data['admin_password'],
                first_name=validated_data['admin_first_name'],
                last_name=validated_data['admin_last_name'],
                user_type='ACADEMY_ADMIN',
                is_staff=True # Academy admins can access their part of Django admin
            )
            # Create Academy Admin Profile
            AcademyAdminProfile.objects.create(user=admin_user, organization=organization)

        return organization

class LoginSerializer(serializers.Serializer):
    """Serializer for user login."""
    username = serializers.CharField()
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})

    def validate(self, data):
        username = data.get('username')
        password = data.get('password')

        if username and password:
            user = authenticate(request=self.context.get('request'),
                                username=username, password=password)
            if not user:
                raise serializers.ValidationError("Invalid credentials.")
        else:
            raise serializers.ValidationError("Must include 'username' and 'password'.")

        data['user'] = user
        return data

class RegisterCoachStudentStaffSerializer(serializers.Serializer):
    """
    Serializer for Academy Admin to register Coach, Student, or other Staff.
    This serializer will be used by an authenticated Academy Admin.
    """
    user_type = serializers.ChoiceField(choices=[('COACH', 'Coach'), ('STUDENT', 'Student'), ('STAFF', 'Staff')])
    
    # Common user fields
    username = serializers.CharField(max_length=150)
    email = serializers.EmailField(required=False, allow_blank=True) # Email can be optional for students
    password = serializers.CharField(write_only=True, style={'input_type': 'password'})
    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150)
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    gender = serializers.ChoiceField(choices=[('M', 'Male'), ('F', 'Female'), ('O', 'Other')], required=False)
    date_of_birth = serializers.DateField(required=False, allow_null=True)

    # Student-specific fields
    parent_name = serializers.CharField(max_length=200, required=False, allow_blank=True)
    parent_phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True)
    parent_email = serializers.EmailField(required=False, allow_blank=True)

    def validate_username(self, value):
        if CustomUser.objects.filter(username=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        return value

    def validate_email(self, value):
        if value and CustomUser.objects.filter(email=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_password(self, value):
        try:
            validate_password(value)
        except DjangoValidationError as e:
            raise serializers.ValidationError(list(e.messages))
        return value

    def validate(self, data):
        user_type = data.get('user_type')
        email = data.get('email')
        phone_number = data.get('phone_number')

        # Ensure at least email or phone for loginable users (Coaches/Staff)
        if user_type in ['COACH', 'STAFF'] and not (email or phone_number):
            raise serializers.ValidationError("Email or Phone Number is required for Coach/Staff users.")
        
        # Ensure DOB for students
        if user_type == 'STUDENT' and not data.get('date_of_birth'):
            raise serializers.ValidationError("Date of birth is required for students.")

        return data

    def create(self, validated_data):
        user_type = validated_data.pop('user_type')
        organization = self.context['request'].user.academy_admin_profile.organization # Get organization from logged-in admin

        with transaction.atomic():
            # Create CustomUser
            user_data = {
                'username': validated_data['username'],
                'email': validated_data.get('email'),
                'password': validated_data['password'],
                'first_name': validated_data['first_name'],
                'last_name': validated_data['last_name'],
                'phone_number': validated_data.get('phone_number'),
                'gender': validated_data.get('gender'),
                'date_of_birth': validated_data.get('date_of_birth'),
                'user_type': user_type,
                'is_staff': user_type in ['COACH', 'STAFF'] # Coaches/Staff can access admin if needed
            }
            # Remove None values to avoid errors with non-nullable fields if they are optional
            user_data = {k: v for k, v in user_data.items() if v is not None and v != ''}

            user = CustomUser.objects.create_user(**user_data)

            # Create specific profile based on user_type
            if user_type == 'COACH':
                CoachProfile.objects.create(user=user, organization=organization)
            elif user_type == 'STUDENT':
                StudentProfile.objects.create(
                    user=user,
                    organization=organization,
                    first_name=validated_data['first_name'],
                    last_name=validated_data['last_name'],
                    email=validated_data.get('email'),
                    phone_number=validated_data.get('phone_number'),
                    date_of_birth=validated_data['date_of_birth'],
                    gender=validated_data.get('gender'),
                    parent_name=validated_data.get('parent_name'),
                    parent_phone_number=validated_data.get('parent_phone_number'),
                    parent_email=validated_data.get('parent_email')
                )
            elif user_type == 'STAFF':
                StaffProfile.objects.create(user=user, organization=organization)
            
        return user


class CoachAssignmentSerializer(serializers.ModelSerializer):
    """
    Serializer for managing coach branch assignments.
    """
    coach_name = serializers.CharField(source='user.get_full_name', read_only=True)
    assigned_branch_names = serializers.SerializerMethodField()
    
    class Meta:
        model = CoachProfile
        fields = ['id', 'coach_name', 'branches', 'assigned_branch_names']
        
    def get_assigned_branch_names(self, obj):
        return [branch.name for branch in obj.branches.all()]
    
    def validate_branches(self, value):
        """Ensure branches belong to the admin's organization."""
        request = self.context.get('request')
        if request and hasattr(request.user, 'academy_admin_profile'):
            organization = request.user.academy_admin_profile.organization
            
            for branch in value:
                if branch.organization != organization:
                    raise serializers.ValidationError(
                        f"Branch '{branch.name}' does not belong to your organization."
                    )
        return value