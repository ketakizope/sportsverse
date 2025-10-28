# Student Dashboard Features

## Overview
The Student Dashboard provides a comprehensive interface for students to manage their enrollments, track attendance, and handle payments.

## Features Implemented

### 1. Student Home Screen (`student_home_screen.dart`)
- **Sidebar Navigation**: Drawer with Dashboard, View Attendance, and Payment options
- **Bottom Navigation**: Quick access to main sections
- **Responsive Design**: Works on both mobile and tablet devices
- **User Profile**: Header with user information and notifications

### 2. Student Dashboard (`student_dashboard_screen.dart`)
- **4 Info Boxes Overview**:
  - Current Enrollment status
  - Sessions Completed count
  - Sessions Remaining count
  - Enrollment Cycle dates
- **Enrollment Details**:
  - Current Enrollment Sessions with progress tracking
  - Previous Enrollment Records with completion status
- **Real-time Data**: Uses Provider for state management

### 3. View Attendance (`view_attendance_screen.dart`)
- **Expandable Enrollment Cycles**: Each enrollment can be expanded/collapsed
- **Attendance Summary**: Overall statistics and progress
- **Session-wise Records**: Detailed attendance for each enrollment
- **Visual Indicators**: Present/Absent status with color coding
- **Date Range Support**: Filter attendance by date ranges

### 4. Payment Screen (`payment_screen.dart`)
- **Payment Summary**: Total paid, pending amounts, transaction counts
- **Enrollment-based Payments**: Grouped by enrollment cycles
- **Pay Button**: Process payments for pending amounts
- **Payment History**: Complete transaction history
- **Status Tracking**: Real-time payment status updates

## Technical Implementation

### Models (`student_models.dart`)
- `StudentEnrollment`: Complete enrollment data structure
- `StudentAttendance`: Attendance record model
- `StudentPayment`: Payment transaction model
- `StudentDashboardData`: Aggregated dashboard data

### API Client (`student_api.dart`)
- RESTful API integration
- Error handling and response parsing
- Support for filtering and pagination
- Payment processing endpoints

### State Management (`student_provider.dart`)
- Provider-based state management
- Loading states and error handling
- Data caching and refresh capabilities
- Business logic for calculations

## Usage

### Navigation
```dart
// Access student home screen
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const StudentHomeScreen(),
));
```

### Data Loading
```dart
// Load dashboard data
final studentProvider = Provider.of<StudentProvider>(context, listen: false);
await studentProvider.loadDashboardData();
```

### Payment Processing
```dart
// Process payment
final success = await studentProvider.processPayment(
  enrollmentId: enrollmentId,
  amount: amount,
  paymentMethod: 'online',
);
```

## API Endpoints Required

The following backend endpoints need to be implemented:

- `GET /api/student/dashboard/` - Dashboard summary data
- `GET /api/student/enrollments/` - Student enrollments
- `GET /api/student/attendance/` - Attendance records
- `GET /api/student/payments/` - Payment history
- `POST /api/student/payments/process/` - Process payment
- `GET /api/student/attendance/summary/` - Attendance summary
- `GET /api/student/payments/summary/` - Payment summary

## Styling

- **Color Scheme**: Primary green (#006C62), secondary colors for status
- **Typography**: Inter font family for modern look
- **Cards**: Rounded corners with subtle shadows
- **Responsive**: Adapts to different screen sizes
- **Accessibility**: High contrast and readable text

## Future Enhancements

- Push notifications for attendance reminders
- QR code scanning for quick attendance
- Offline support for viewing data
- Export attendance reports
- Payment method management
- Profile editing capabilities
