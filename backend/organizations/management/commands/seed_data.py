import random
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils.text import slugify
from django.db import transaction
from organizations.models import Organization, Sport, Branch, Batch, Enrollment
from accounts.models import AcademyAdminProfile, StudentProfile
from coaches.models import CoachProfile, CoachAssignment

User = get_user_model()

class Command(BaseCommand):
    help = 'Seed the database with sample data'

    def handle(self, *args, **kwargs):
        self.stdout.write('🌱 Seeding database...')
        
        # 1. Create Sports
        sports_data = [
            ('Cricket', 'Cricket coaching for all levels'),
            ('Football', 'Professional football training'),
            ('Tennis', 'Tennis classes for kids and adults'),
            ('Badminton', 'Indoor badminton sessions'),
        ]
        sports = []
        for name, desc in sports_data:
            sport, _ = Sport.objects.get_or_create(name=name, defaults={'description': desc})
            sports.append(sport)

        # 2. Academy Data
        academies_data = [
            ('Elite Sports Academy', 'Elite Academy', 'elite-sports'),
            ('Champions Cricket Club', 'Champions Club', 'champions-club'),
        ]

        credentials = []

        with transaction.atomic():
            for full_name, short_name, slug in academies_data:
                # Create Organization
                org, created = Organization.objects.get_or_create(
                    slug=slug,
                    defaults={
                        'full_name': full_name,
                        'academy_name': short_name,
                        'email_address': f'info@{slug}.com',
                        'mobile_number': '9876543210',
                        'location': f'Central {short_name} St, Mumbai',
                    }
                )
                if created:
                    org.sports_offered.set(random.sample(sports, 2))

                # Create Academy Admin
                admin_username = f'{slug}_admin'
                admin_pass = 'Admin123!'
                admin_user, admin_created = User.objects.get_or_create(
                    username=admin_username,
                    defaults={
                        'email': f'admin@{slug}.com',
                        'first_name': f'{short_name}',
                        'last_name': 'Admin',
                        'user_type': 'ACADEMY_ADMIN',
                        'is_staff': True
                    }
                )
                if admin_created:
                    admin_user.set_password(admin_pass)
                    admin_user.save()
                    AcademyAdminProfile.objects.get_or_create(user=admin_user, organization=org)
                    credentials.append({'username': admin_username, 'password': admin_pass, 'role': 'ACADEMY_ADMIN', 'org': short_name})

                # Create Branches
                branch_names = ['Main Branch', 'North Wing']
                branches = []
                for b_name in branch_names:
                    branch, _ = Branch.objects.get_or_create(
                        organization=org,
                        name=b_name,
                        defaults={'address': f'{b_name} Address, {short_name}'}
                    )
                    branches.append(branch)

                # Create Coaches
                for i in range(1, 3):
                    coach_username = f'{slug}_coach_{i}'
                    coach_pass = 'Coach123!'
                    coach_user, c_created = User.objects.get_or_create(
                        username=coach_username,
                        defaults={
                            'email': f'coach{i}@{slug}.com',
                            'first_name': f'Coach {i}',
                            'last_name': short_name,
                            'user_type': 'COACH'
                        }
                    )
                    if c_created:
                        coach_user.set_password(coach_pass)
                        coach_user.save()
                        coach_profile, _ = CoachProfile.objects.get_or_create(
                            user=coach_user,
                            organization=org,
                            defaults={'specialization': random.choice(sports).name}
                        )
                        credentials.append({'username': coach_username, 'password': coach_pass, 'role': 'COACH', 'org': short_name})

                        # Create a Batch for this coach in one of the branches
                        branch = random.choice(branches)
                        sport = random.choice(org.sports_offered.all())
                        batch_name = f'Evening {sport.name} {i}'
                        batch, _ = Batch.objects.get_or_create(
                            organization=org,
                            branch=branch,
                            sport=sport,
                            name=batch_name,
                            defaults={
                                'max_students': 20,
                                'fee_per_session': 500,
                                'payment_policy': 'POST_PAID'
                            }
                        )
                        # Assign coach to batch
                        CoachAssignment.objects.get_or_create(coach=coach_profile, branch=branch, sport=sport, batch=batch)

                        # Create some Students for this batch
                        for j in range(1, 4):
                            student_username = f'{slug}_std_{i}_{j}'
                            student_pass = 'Student123!'
                            student_user, s_created = User.objects.get_or_create(
                                username=student_username,
                                defaults={
                                    'email': f'student_{i}_{j}@{slug}.com',
                                    'first_name': f'Student {i}{j}',
                                    'last_name': short_name,
                                    'user_type': 'STUDENT'
                                }
                            )
                            if s_created:
                                student_user.set_password(student_pass)
                                student_user.save()
                                
                                student_profile, _ = StudentProfile.objects.get_or_create(
                                    user=student_user,
                                    organization=org,
                                    defaults={
                                        'first_name': student_user.first_name,
                                        'last_name': student_user.last_name,
                                        'phone_number': f'9000000{i}{j}',
                                        'date_of_birth': '2010-01-01'
                                    }
                                )
                                
                                # Enroll student in batch
                                Enrollment.objects.get_or_create(
                                    student=student_profile,
                                    batch=batch,
                                    organization=org,
                                    defaults={
                                        'enrollment_type': 'SESSION_BASED',
                                        'total_sessions': 20
                                    }
                                )
                                credentials.append({'username': student_username, 'password': student_pass, 'role': 'STUDENT', 'org': short_name})

        self.stdout.write(self.style.SUCCESS('✅ Database seeded successfully!'))
        self.stdout.write('\n--- SAMPLE CREDENTIALS ---')
        self.stdout.write(f'{"User Name":<25} | {"Password":<15} | {"Role":<15} | {"Academy"}')
        self.stdout.write('-' * 75)
        for cred in credentials:
            self.stdout.write(f'{cred["username"]:<25} | {cred["password"]:<15} | {cred["role"]:<15} | {cred["org"]}')
