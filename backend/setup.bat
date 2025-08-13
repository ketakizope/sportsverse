@echo off
REM SportsVerse Backend Setup Script for Windows

echo 🚀 Setting up SportsVerse Backend...

REM Create virtual environment
echo 📦 Creating virtual environment...
python -m venv venv

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call venv\Scripts\activate

REM Install dependencies
echo 📚 Installing dependencies...
pip install -r requirements.txt

REM Create database migrations
echo 🗄️ Creating database migrations...
python manage.py makemigrations

REM Apply migrations
echo 🔄 Applying database migrations...
python manage.py migrate

REM Create initial sports data
echo 🏀 Creating initial sports data...
python manage.py shell < setup_sports.py

echo ✅ Backend setup complete!
echo.
echo 🚀 To run the server:
echo    python manage.py runserver
echo.
echo 🔧 To create a superuser:
echo    python manage.py createsuperuser
echo.
echo 📊 Admin panel will be available at:
echo    http://127.0.0.1:8000/admin/

pause
