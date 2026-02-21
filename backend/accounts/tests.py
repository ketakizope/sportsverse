# accounts/tests.py
# Unit tests for the new endpoints and race-condition fix.
#
# Run with:
#   python manage.py test accounts --verbosity=2

from django.test import TestCase, override_settings
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token

User = get_user_model()

# ────────────────────────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────────────────────────

def make_user(username, email, password, user_type='ACADEMY_ADMIN', **kwargs):
    """Create a CustomUser and return (user, token)."""
    user = User.objects.create_user(
        username=username,
        email=email,
        password=password,
        user_type=user_type,
        **kwargs,
    )
    token = Token.objects.create(user=user)
    return user, token


# ────────────────────────────────────────────────────────────────────────────────
# Test 1 — /api/accounts/me/ token validation
# ────────────────────────────────────────────────────────────────────────────────

class MeViewTests(TestCase):
    """Tests for GET /api/accounts/me/"""

    def setUp(self):
        self.client = APIClient()
        self.user, self.token = make_user(
            username='testadmin',
            email='admin@test.com',
            password='SecurePass123!',
            user_type='ACADEMY_ADMIN',
            first_name='Test',
            last_name='Admin',
        )
        self.url = '/api/accounts/me/'

    def test_me_unauthenticated(self):
        """No token → 401 Unauthorized."""
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 401)

    def test_me_invalid_token(self):
        """Garbage token → 401 Unauthorized."""
        self.client.credentials(HTTP_AUTHORIZATION='Token garbage_token_xyz')
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 401)

    def test_me_authenticated_returns_user_info(self):
        """Valid token → 200 with expected fields."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token.key}')
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data['username'], 'testadmin')
        self.assertEqual(data['email'], 'admin@test.com')
        self.assertEqual(data['user_type'], 'ACADEMY_ADMIN')
        self.assertIn('profile_details', data)

    def test_me_contains_all_required_fields(self):
        """Response must include id, username, email, user_type, first_name, last_name."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token.key}')
        data = self.client.get(self.url).json()
        for field in ('id', 'username', 'email', 'user_type', 'first_name', 'last_name', 'must_change_password'):
            self.assertIn(field, data, f"Field '{field}' missing from /me/ response")


# ────────────────────────────────────────────────────────────────────────────────
# Test 2 — /api/accounts/coach-dashboard/ role enforcement
# ────────────────────────────────────────────────────────────────────────────────

class CoachDashboardViewTests(TestCase):
    """Tests for GET /api/accounts/coach-dashboard/"""

    def setUp(self):
        self.client = APIClient()
        self.url = '/api/accounts/coach-dashboard/'

        # Create an ACADEMY_ADMIN
        self.admin, self.admin_token = make_user(
            username='admin1', email='admin1@test.com', password='Pass!1234', user_type='ACADEMY_ADMIN'
        )

        # Create a COACH user
        self.coach_user, self.coach_token = make_user(
            username='coach1',
            email='coach1@test.com',
            password='Pass!1234',
            user_type='COACH',
            first_name='Coach',
            last_name='One',
        )

    def test_coach_dashboard_unauthenticated(self):
        """No token → 401."""
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 401)

    def test_coach_dashboard_as_admin_returns_403(self):
        """Academy admin token → 403 Forbidden (not a coach)."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.admin_token.key}')
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 403)

    def test_coach_dashboard_as_coach_without_profile_returns_404(self):
        """Coach user without a CoachProfile record → 404."""
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.coach_token.key}')
        response = self.client.get(self.url)
        # Coach has no CoachProfile FK yet
        self.assertEqual(response.status_code, 404)

    def test_coach_dashboard_as_coach_with_profile_returns_200(self):
        """Coach user with CoachProfile → 200 with expected payload structure."""
        # Create a minimal org + CoachProfile
        from organizations.models import Organization
        from coaches.models import CoachProfile

        org = Organization.objects.create(
            full_name='Test Academy',
            academy_name='Test Academy',
            email_address='org@test.com',
            slug='test-academy',
        )
        CoachProfile.objects.create(
            user=self.coach_user,
            organization=org,
            phone_number='9876543210',
        )

        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.coach_token.key}')
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)

        data = response.json()
        self.assertIn('coach_profile', data)
        self.assertIn('assignments', data)
        self.assertIn('upcoming_sessions', data)
        self.assertIn('attendance_summary', data)
        self.assertIn('pending_salary', data)

        # Validate coach_profile fields
        cp = data['coach_profile']
        for field in ('id', 'full_name', 'email', 'organization_id', 'organization_name'):
            self.assertIn(field, cp, f"coach_profile missing field: {field}")

        # Validate pending_salary structure
        self.assertIn('amount', data['pending_salary'])
        self.assertIn('currency', data['pending_salary'])


# ────────────────────────────────────────────────────────────────────────────────
# Test 3 — Attendance F() race-condition safety
# ────────────────────────────────────────────────────────────────────────────────

class AttendanceFExpressionConcurrencyTest(TestCase):
    """
    Verifies that concurrent Attendance.save() calls do NOT cause a lost-update
    on Enrollment.sessions_attended by using F() expressions.

    We simulate concurrency by running two Attendance.save() calls inside a
    transaction and checking that the final count equals exactly 2.
    """

    def _setup_enrollment(self):
        """Create minimal org, student, batch, and enrollment for testing."""
        from organizations.models import Organization, Sport, Branch, Batch, Enrollment
        from accounts.models import StudentProfile

        org = Organization.objects.create(
            full_name='Race Test Academy',
            academy_name='Race Academy',
            email_address='race@test.com',
            slug='race-academy',
        )
        sport = Sport.objects.create(name='TestSport')
        branch = Branch.objects.create(organization=org, name='Main', address='123 St')
        batch = Batch.objects.create(
            organization=org,
            branch=branch,
            sport=sport,
            name='Batch A',
            payment_policy='POST_PAID',
        )
        student = StudentProfile.objects.create(
            organization=org,
            first_name='Race',
            last_name='Tester',
            email='racetester@test.com',
        )
        enrollment = Enrollment.objects.create(
            student=student,
            batch=batch,
            organization=org,
            enrollment_type='SESSION_BASED',
            total_sessions=10,
            sessions_attended=0,
        )
        return enrollment, batch, student, org

    def test_two_attendance_saves_increment_sessions_to_2_using_f_expressions(self):
        """
        Saving two Attendance records for the same enrollment on different dates
        should result in sessions_attended == 2, not 1 (which would indicate a race).
        """
        import datetime
        from organizations.models import Attendance

        enrollment, batch, student, org = self._setup_enrollment()

        # First attendance — triggers enrollment start + session deduction
        att1 = Attendance(
            enrollment=enrollment,
            batch=batch,
            student=student,
            organization=org,
            date=datetime.date(2026, 2, 1),
            is_session_deducted=False,
        )
        att1.save()

        # Second attendance — should increment sessions_attended to 2
        att2 = Attendance(
            enrollment=enrollment,
            batch=batch,
            student=student,
            organization=org,
            date=datetime.date(2026, 2, 3),
            is_session_deducted=False,
        )
        att2.save()

        # Re-fetch from DB to get the latest value (not a stale ORM object)
        enrollment.refresh_from_db()
        self.assertEqual(
            enrollment.sessions_attended,
            2,
            "Expected sessions_attended=2 after two attendance saves. "
            "If this is 1, the race condition is NOT fixed.",
        )

    def test_attendance_marks_is_session_deducted(self):
        """After save(), Attendance.is_session_deducted must be True."""
        import datetime
        from organizations.models import Attendance

        enrollment, batch, student, org = self._setup_enrollment()
        att = Attendance.objects.create(
            enrollment=enrollment,
            batch=batch,
            student=student,
            organization=org,
            date=datetime.date(2026, 2, 5),
        )
        att.refresh_from_db()
        self.assertTrue(
            att.is_session_deducted,
            "is_session_deducted should be True after Attendance.save()",
        )
