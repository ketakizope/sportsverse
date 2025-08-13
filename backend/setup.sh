#!/bin/bash
# SportsVerse Backend Setup Script

echo "🚀 Setting up SportsVerse Backend..."

# Create virtual environment
echo "📦 Creating virtual environment..."
python -m venv venv

# Activate virtual environment
echo "🔧 Activating virtual environment..."
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    source venv/Scripts/activate
else
    # macOS/Linux
    source venv/bin/activate
fi

# Install dependencies
echo "📚 Installing dependencies..."
pip install -r requirements.txt

# Create database migrations
echo "🗄️ Creating database migrations..."
python manage.py makemigrations

# Apply migrations
echo "🔄 Applying database migrations..."
python manage.py migrate

# Create initial sports data (optional)
echo "🏀 Creating initial sports data..."
python manage.py shell << EOF
from organizations.models import Sport

# Create sports if they don't exist
sports_data = [
    {"name": "Cricket", "description": "Cricket training and coaching"},
    {"name": "Football", "description": "Football training and coaching"},
    {"name": "Tennis", "description": "Tennis training and coaching"},
    {"name": "Basketball", "description": "Basketball training and coaching"},
    {"name": "Swimming", "description": "Swimming training and coaching"},
    {"name": "Badminton", "description": "Badminton training and coaching"},
]

for sport_data in sports_data:
    sport, created = Sport.objects.get_or_create(
        name=sport_data["name"],
        defaults={"description": sport_data["description"]}
    )
    if created:
        print(f"Created sport: {sport.name}")
    else:
        print(f"Sport already exists: {sport.name}")

print("Initial sports data setup complete!")
EOF

echo "✅ Backend setup complete!"
echo ""
echo "🚀 To run the server:"
echo "   python manage.py runserver"
echo ""
echo "🔧 To create a superuser:"
echo "   python manage.py createsuperuser"
echo ""
echo "📊 Admin panel will be available at:"
echo "   http://127.0.0.1:8000/admin/"
