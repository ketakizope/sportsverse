# SportsVerse Project Documentation

## 1. Project Overview

SportsVerse is a comprehensive, multi-tenant Academy Management System designed for sports academies (e.g., cricket, football, tennis). It provides tools for Academy Admins, Coaches, and Students to manage and track daily academy operations efficiently. 

Key capabilities include:
- **Academy Registration**: Academies can register their organization and create an admin user in a single workflow.
- **Facility Management**: Create and manage physical branches.
- **Batch Management**: Organize training batches according to schedule, sport, and capacity.
- **Student Enrollment**: Add students via a 3-step wizard and assign them to batches.
- **Coach Management**: Assign coaches to branches and specific batches.
- **Attendance Tracking**: Monitor student attendance manually or via an AI-powered face recognition system.
- **Financial Tracking**: Track fee payments (session-based or duration-based) and coach salaries.
- **Dashboards**: Role-specific dashboards for Academy Admins, Coaches, and Students accessible via the mobile app.

The architecture ensures strict data isolation; every piece of data is scoped to an `Organization` via ForeignKey, allowing a single backend instance to serve multiple academies securely.

---

## 2. Technology Stack

### Backend Stack
- **Framework**: Python 3.x, Django 5.2.4
- **API**: Django REST Framework (DRF) 3.14+
- **Database**: MySQL (`sportsverse_db`)
- **Authentication**: Token-based authentication (`rest_framework.authtoken`)
- **Other Tools**: Pillow (image handling), django-cors-headers, django-extensions

### Frontend Stack
- **Framework**: Flutter (Dart)
- **State Management**: Provider package (`AuthProvider`, `StudentProvider`)
- **Networking**: `http` package
- **Storage**: `shared_preferences` for token persistence

### Digital Face Recognition Module
- **Framework**: Flask (Python)
- **Database**: SQLite (`attendance.db`)
- **Machine Learning**: Scikit-Learn/OpenCV (via `model.py`) for face embedding extraction and classification.

---

## 3. General Project Structure

The root directory contains three main components:
1. `backend/`: The Django REST API backend.
2. `frontend/`: The Flutter mobile application.
3. `Digital-Facial-Recognisation-Attendance-System-main/`: The standalone Flask application for face recognition-based attendance.

---

## 4. Backend Architecture & Functions

### Django Apps Overview
The backend relies on several distinct apps to segregate business logic:
- **`accounts`**: Manages the custom user model (`CustomUser`), profiles (`AcademyAdminProfile`, `StudentProfile`), authentication, and core API views.
- **`organizations`**: Houses core tenant models (`Organization`, `Branch`, `Batch`, `Enrollment`, `Attendance`).
- **`coaches`**: Manages `CoachProfile` and `CoachAssignment`.
- **`payments`**: Handles financial records (`FeeTransaction`, `CoachSalaryTransaction`).
- **`ratings`**: Contains the DUPR-style ELO rating engine for player integrity and ranking.
- **`communications`**, **`content`**, **`academy_contents`**, **`academy_reports`**: Handle notifications, CMS, and reporting.

### Key API Endpoints
- **Authentication**: 
  - `POST /api/accounts/login/`: Validates email/username and returns a token.
  - `POST /api/accounts/register/`: Creates a new organization, admin user, and admin profile atomically.
  - `POST /api/accounts/password-reset/`: Initiates password recovery.
- **Organizations**:
  - `GET/POST /api/organizations/branches/`: Branch CRUD operations.
  - `GET/POST /api/organizations/batches/`: Batch CRUD operations.
  - `GET/POST /api/organizations/students/`: Manage student profiles.
  - `GET/POST /api/organizations/enrollments/`: Enroll students into batches.
- **Student Dashboard**:
  - `GET /api/student/student-dashboard/`: Fetches enrolled batches, attendance history, and remaining sessions.

### Backend Control Flow & Business Logic
- **Multi-Tenancy**: View querysets automatically filter data based on the logged-in user's `AcademyAdminProfile.organization`.
- **Atomic Registration**: Academy registration creates multiple linked DB records (User, Organization, Profile) inside a database transaction (`transaction.atomic`) to prevent partial creation.
- **Automated Workflows**: 
  - When the first `Attendance` is saved for a student, the `Enrollment` automatically activates (start date set).
  - For `POST_PAID` batches, marking attendance automatically generates an unpaid `FeeTransaction` record.

---

## 5. Database Structure (MySQL)

### Core Models
- **`CustomUser`**: Extends `AbstractUser`. Stores `user_type` (PLATFORM_ADMIN, ACADEMY_ADMIN, COACH, STUDENT), `phone_number`, etc.
- **`Organization`**: The tenant model representing an academy.
- **`AcademyAdminProfile`**: 1:1 link between a `CustomUser` and an `Organization`.
- **`StudentProfile`**: Full student details, including an optional `face_encoding` JSON field for AI attendance.
- **`Branch`**: Physical locations linked to an Organization.
- **`Batch`**: Training schedules linked to a Branch and Sport. Stores capacity and fee logic (`fee_per_session`).
- **`Enrollment`**: Links a `StudentProfile` to a `Batch`. Defines if billing is `SESSION_BASED` or `DURATION_BASED`.
- **`Attendance`**: Links an `Enrollment` to a date. Tracks sessions attended.
- **`FeeTransaction`**: Represents fee payments. Linked to `Organization`, `StudentProfile`, and `Batch`.
- **`CoachProfile`** & **`CoachAssignment`**: Defines a coach's specialization and assigns them to specific batches.

### Ratings Database
- **`PlayerRatingProfile`**: Stores ELO ratings for Singles/Doubles.
- **`RatingMatch`**: Match results containing JSON data for participants and scores. Includes a SHA-256 hash to prevent duplicates.
- **`RatingAudit`**: Immutable log of every ELO rating change.

---

## 6. Frontend Structure (Flutter)

### Routing & State Management
- **Entrypoint (`main.dart`)**: Uses a single-Navigator pattern. `AuthProvider` handles automatic routing based on the logged-in user's role:
  - `ACADEMY_ADMIN` → `AdminDashboardScreen`
  - `COACH` → `CoachDashboardScreen`
  - `STUDENT` → `StudentDashboardScreen`
- **API Client (`api_client.dart`)**: Singleton HTTP client that persists the Auth token via `shared_preferences` and injects it into all request headers.

### Key Pages / Screens
- **Authentication**: `LoginScreen`, `RegisterAcademyScreen`, `ChangePasswordScreen`.
- **Admin Dashboard**: `AdminDashboardScreen` with widgets for quick actions (Manage Branches, Batches, Coaches, Students).
- **Attendance Hub**: 
  - `AttendanceBranchSelectScreen`: Pick a branch.
  - `TakeAttendanceScreen`: Mark present/absent for enrolled students.
  - `ViewAttendanceScreen`: Review past attendance.
- **Student Dashboard**: `StudentDashboardScreen` displays personal enrollment progress, sessions left, and upcoming payments.

---

## 7. Digital Face Recognition Module

Located in `Digital-Facial-Recognisation-Attendance-System-main/`, this is a standalone Flask service designed to integrate with the main system or operate independently.

### Architecture
- **Web Server**: Flask (`app.py`) running on port 5000.
- **Database**: SQLite (`attendance.db`) containing `students` and `attendance` tables.
- **Machine Learning**: `model.py` utilizes computer vision models (likely dlib/OpenCV/face_recognition) to extract embeddings and classify faces.

### API Routes & Functionality
- **`/add_student` (GET/POST)**: Form to add a student's metadata to the database.
- **`/upload_face` (POST)**: Receives multiple images from the frontend/camera and saves them to a structured dataset directory (`dataset/<student_id>/`).
- **`/train_model` (GET)**: Triggers a background thread (`train_model_background`) to retrain the machine learning classifier using the latest images. Status is saved to a JSON file.
- **`/train_status` (GET)**: Polling endpoint to check training progress.
- **`/recognize_face` (POST)**: Receives a single image, extracts the face embedding, predicts the student ID via the trained model, and logs a timestamped attendance record if confidence is above a threshold (0.5).
- **`/attendance_record` & `/download_csv`**: Endpoints for admins to view and export the AI-captured attendance logs.

---

## 8. Development Setup Summary

**Backend (Django):**
1. Create a `.env` file (ensure `SECRET_KEY`, `DB_PASSWORD`, etc., are configured securely).
2. Install Python dependencies (`pip install -r requirements.txt`).
3. Set up MySQL database `sportsverse_db`.
4. Run `python manage.py migrate` and `python manage.py runserver`.

**Frontend (Flutter):**
1. Ensure the `baseUrl` in `api_client.dart` points to the correct backend IP (e.g., `http://10.0.2.2:8000` for Android Emulator).
2. Run `flutter pub get` and `flutter run`.

**Face Recognition Module:**
1. Run `python app.py` to start the Flask application.

---

## 9. Next Steps & Known Improvements
- **Security**: Remove hardcoded API keys and database credentials from code. Configure `CORS_ALLOWED_ORIGINS` strictly for production.
- **Performance**: Optimize N+1 queries in the Django views (e.g., `StudentDashboardView`). Add pagination for endpoints listing multiple records.
- **Reliability**: Add HTTP timeouts to the Flutter `api_client.dart`. Ensure the backend API correctly handles token validation on app start.
- **Integration**: Fully bridge the standalone Flask Face Recognition module with the Django backend so `StudentProfile` and `Attendance` records sync seamlessly.
