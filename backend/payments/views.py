from django.shortcuts import render

# Create your views here.
# backend/accounts/views.py

from django.http import HttpResponse

def dummy_view(request):
    return HttpResponse("Accounts app is working!")
