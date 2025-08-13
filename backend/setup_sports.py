# setup_sports.py - Initial sports data setup

from organizations.models import Sport

# Create sports if they don't exist
sports_data = [
    {"name": "Cricket", "description": "Cricket training and coaching"},
    {"name": "Football", "description": "Football training and coaching"},
    {"name": "Tennis", "description": "Tennis training and coaching"},
    {"name": "Basketball", "description": "Basketball training and coaching"},
    {"name": "Swimming", "description": "Swimming training and coaching"},
    {"name": "Badminton", "description": "Badminton training and coaching"},
    {"name": "Volleyball", "description": "Volleyball training and coaching"},
    {"name": "Table Tennis", "description": "Table tennis training and coaching"},
    {"name": "Golf", "description": "Golf training and coaching"},
    {"name": "Boxing", "description": "Boxing training and coaching"},
]

print("Setting up initial sports data...")

for sport_data in sports_data:
    sport, created = Sport.objects.get_or_create(
        name=sport_data["name"],
        defaults={"description": sport_data["description"]}
    )
    if created:
        print(f"✅ Created sport: {sport.name}")
    else:
        print(f"ℹ️  Sport already exists: {sport.name}")

print("🎉 Initial sports data setup complete!")
