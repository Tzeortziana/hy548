from django.http import HttpResponse

from django.conf import settings


def index(request):
    return HttpResponse('Hello world!' + (' (DEBUG is on)' if settings.DEBUG else ''))
