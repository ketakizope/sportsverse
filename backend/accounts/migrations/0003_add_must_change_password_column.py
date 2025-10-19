from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0002_initial"),
    ]

    operations = [
        migrations.RunSQL(
            sql=(
                "ALTER TABLE `accounts_customuser` "
                "ADD COLUMN `must_change_password` TINYINT(1) NOT NULL DEFAULT 0;"
            ),
            reverse_sql=(
                "ALTER TABLE `accounts_customuser` "
                "DROP COLUMN `must_change_password`;"
            ),
        ),
    ]


