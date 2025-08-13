from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    # Include URLs from your custom apps
    path('api/accounts/', include('accounts.urls')),
    path('api/organizations/', include('organizations.urls')),
    path('api/communications/', include('communications.urls')),
    path('api/payments/', include('payments.urls')),
    path('api/content/', include('content.urls')),
]

# Serve media files in development. In production, a web server (Nginx/Apache) handles this.
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)