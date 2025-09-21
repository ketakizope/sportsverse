# 🚀 Quick Setup Guide for Team Members

## 📥 **Step 1: Clone Repository**
```bash
git clone https://github.com/HIronF/sportsverse.git
cd sportsverse
```

## 🐍 **Step 2: Backend Setup (5 minutes)**
```bash
cd backend

# Create virtual environment  
python -m venv venv

# Activate (Windows)
venv\Scripts\activate
# Activate (Mac/Linux)  
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Setup database (create 'sportsverse' database in MySQL first)
python manage.py migrate

# Run server
python manage.py runserver
```
✅ **Backend runs on**: `http://127.0.0.1:8000`

## 📱 **Step 3: Frontend Setup (3 minutes)**
```bash
cd ../frontend/sportsverse_app

# Install Flutter dependencies
flutter pub get

# Run app (ensure emulator/device is running)
flutter run
```

## ✅ **Step 4: Verify Setup**
1. **Backend**: Visit `http://127.0.0.1:8000/api/organizations/sports/`
2. **Frontend**: Login screen should appear on mobile app
3. **Test**: Create account → Add branch → Create batch → Enroll student

## 🎯 **Step 5: Choose Your Role**
- **Backend Developer**: Check `TEAM_WORK_DIVISION.md` - Developer 1
- **Frontend Developer**: Check `TEAM_WORK_DIVISION.md` - Developer 2  
- **Features Developer**: Check `TEAM_WORK_DIVISION.md` - Developer 3

## 📞 **Need Help?**
- 📖 **Full Setup**: `README.md`
- 🛠️ **Technical Details**: `TECHNICAL_IMPLEMENTATION.md`
- 📋 **Development History**: `DEVELOPMENT_PROGRESS.md`
- 👥 **Team Work Plan**: `TEAM_WORK_DIVISION.md`

**Ready to code! 🎉**
