# SportsVerse - Academy Management System

A comprehensive academy management system with **Django REST Framework** backend and **Flutter** frontend. Supports multi-tenant organizations with complete student enrollment, batch management, coach assignment, and attendance-based enrollment tracking.

## 🌟 Features

### ✅ **Completed & Working**
- **🔐 Authentication System**: Token-based authentication with password reset
- **🏢 Multi-tenant Organizations**: Complete organization isolation
- **🏫 Branch Management**: CRUD operations for academy branches
- **📚 Batch Management**: Schedule management with day/time selection
- **👨‍🏫 Coach Assignment**: Assign coaches to multiple branches
- **👨‍🎓 Student Enrollment**: Combined student creation + enrollment workflow
- **📊 Attendance-Based Enrollment**: Enrollment starts when first attendance is taken

### 📱 **Admin Dashboard**
- **🔵 Manage Branches** - Create and manage academy locations
- **🟢 Manage Batches** - Schedule and organize training sessions  
- **🟠 Assign Coaches** - Assign instructors to branches
- **🟣 Manage Enrollments** - Track student enrollment status
- **🟦 Add New Student** - 3-step wizard for student onboarding

---

## 🛠️ Setup Instructions

### 1️⃣ **Backend (Django) Setup**

#### 1.1 Clone the Repository
```bash
git clone https://github.com/HIronF/sportsverse.git
cd sportsverse/backend
```

#### 1.2 Create Virtual Environment & Install Dependencies
```bash
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

#### 1.3 Configure Database
Create a MySQL database named `sportsverse` and update your database settings in `sportsverse_project/settings.py`:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'sportsverse',
        'USER': 'your_db_user',
        'PASSWORD': 'your_db_password',
        'HOST': 'localhost',
        'PORT': '3306',
    }
}
```

#### 1.4 Apply Database Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

#### 1.5 Create Superuser (Optional)
```bash
python manage.py createsuperuser
```

#### 1.6 Load Initial Data (Optional)
```bash
# Create some sports data
python manage.py shell
>>> from organizations.models import Sport
>>> Sport.objects.create(name="Cricket", description="Cricket training")
>>> Sport.objects.create(name="Football", description="Football training")
>>> Sport.objects.create(name="Tennis", description="Tennis training")
>>> exit()
```

#### 1.7 Run the Django Server
```bash
python manage.py runserver
```
**Backend runs on:** `http://127.0.0.1:8000/`

---

### 2️⃣ **Frontend (Flutter) Setup**

#### 2.1 Install Flutter Dependencies
```bash
cd ../frontend/sportsverse_app
flutter pub get
```

#### 2.2 Configure API Endpoint
**For Android Emulator** (recommended):
- The app is already configured to use `http://10.0.2.2:8000` 
- **Do NOT change this** unless using Windows emulator or physical device

**For iOS Simulator or Physical Device**:
Update `lib/api/api_client.dart`:
```dart
static const String baseUrl = 'http://127.0.0.1:8000'; // or your computer's IP
```

#### 2.3 Run the Flutter App
```bash
flutter run
```
**Make sure your emulator/device is running before executing this command.**

---

## 🔌 API Endpoints

### **Authentication**
- `POST /api/auth/register/` → Register new user
- `POST /api/auth/login/` → Login and get token
- `POST /api/auth/logout/` → Logout and invalidate token
- `POST /api/auth/password-reset/` → Request password reset
- `POST /api/auth/password-reset-confirm/` → Confirm password reset

### **Organizations**
- `GET /api/organizations/sports/` → List all sports
- `GET/POST /api/organizations/branches/` → Branch management
- `GET/POST /api/organizations/batches/` → Batch management
- `GET/POST /api/organizations/students/` → Student management
- `GET/POST /api/organizations/enrollments/` → Enrollment management
- `POST /api/organizations/student-enrollments/` → Combined student + enrollment creation

---

## 🎯 Usage Workflow

### **For Academy Admin:**

1. **Register/Login** → Create your academy account
2. **Create Branches** → Add your academy locations
3. **Create Batches** → Set up training schedules
4. **Add Students** → Use 3-step wizard to enroll students
5. **Assign Coaches** → Assign instructors to branches
6. **Track Enrollments** → Monitor student progress

### **Student Enrollment Process:**
1. Admin creates student → Enrollment status: **"Not Started"**
2. Coach marks first attendance → Status changes to **"Active"**
3. System automatically sets start date and tracks progress
4. Enrollment completes based on sessions or duration

---

## 📱 Mobile App Features

### **Authentication Screens**
- Login with email/username
- Registration with organization creation
- Password reset functionality

### **Admin Dashboard**
- Clean, intuitive interface
- 5 main management sections
- Real-time status updates

### **Management Screens**
- **Branch Management**: Add/edit academy locations
- **Batch Management**: Schedule with time pickers
- **Student Enrollment**: 3-step creation wizard
- **Coach Assignment**: Multi-select branch assignment
- **Enrollment Tracking**: Progress monitoring

---

## 🗂️ Project Structure

```
sportsverse/
├── backend/                          # Django REST Framework
│   ├── manage.py
│   ├── requirements.txt
│   ├── sportsverse_project/          # Django settings
│   ├── accounts/                     # User management
│   ├── organizations/                # Main app (branches, batches, enrollments)
│   ├── communications/               # Email/notifications
│   ├── content/                      # Content management
│   └── payments/                     # Payment processing (future)
├── frontend/sportsverse_app/         # Flutter app
│   ├── lib/
│   │   ├── api/                      # API clients
│   │   ├── models/                   # Data models
│   │   ├── providers/                # State management
│   │   ├── screens/                  # UI screens
│   │   └── main.dart
│   └── pubspec.yaml
├── DEVELOPMENT_PROGRESS.md           # Complete development history
├── TECHNICAL_IMPLEMENTATION.md      # Technical documentation
└── README.md                        # This file
```

---

## 🚨 Troubleshooting

### **Common Issues:**

**1. Backend not connecting:**
- Ensure Django server is running on `http://127.0.0.1:8000`
- Check database connection settings
- Verify all migrations are applied

**2. Flutter build issues:**
- Run `flutter clean && flutter pub get`
- Ensure Flutter SDK is properly installed
- Check Android/iOS emulator is running

**3. API connection failed:**
- For Android emulator, use `http://10.0.2.2:8000`
- For physical device, use your computer's IP address
- Ensure no firewall blocking the connection

**4. Database errors:**
- Create MySQL database `sportsverse` manually
- Check database credentials in `settings.py`
- Run migrations: `python manage.py migrate`

---

## 🔧 Development Notes

### **Key Technologies:**
- **Backend**: Django 4.2, Django REST Framework, MySQL
- **Frontend**: Flutter 3.x, Provider (State Management)
- **Authentication**: Token-based authentication
- **Database**: Multi-tenant with organization scoping

### **Important Files to Review:**
- `backend/sportsverse_project/settings.py` - Database configuration
- `frontend/sportsverse_app/lib/api/api_client.dart` - API endpoint configuration
- `DEVELOPMENT_PROGRESS.md` - Complete feature documentation
- `TECHNICAL_IMPLEMENTATION.md` - Code implementation details

---

## 🚀 Next Development Phase

### **Planned Features:**
- **📋 Attendance Management**: Interface for marking student attendance
- **📊 Reports & Analytics**: Dashboard statistics and progress reports
- **💳 Payment Integration**: Fee collection and payment tracking
- **📧 Notifications**: Email/SMS for attendance and payments
- **📱 Mobile App for Students**: Student portal with progress tracking

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

If you encounter any issues during setup:
1. Check the troubleshooting section above
2. Review `DEVELOPMENT_PROGRESS.md` for detailed context
3. Create an issue in the GitHub repository

**Happy Coding! 🎉**
