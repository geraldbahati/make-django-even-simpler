# !/bin/bash

projectname=$1

# Check if project name is provided
if [[ -z "$projectname" ]]; then
    echo "Usage: g-django <projectname>"
    exit 1
fi

# Create a virtual environment
python3 -m venv "$projectname"_env
source "$projectname"_env/bin/activate

# Create requirements.txt with specified packages
cat >requirements.txt <<EOL
djangorestframework
djangorestframework-simplejwt
pyyaml
requests
django-cors-headers
channels-redis
django_celery_results
django_celery_beat
celery
django>=4.2.0
selenium
python-dotenv
EOL

# Install requirements
pip install -r requirements.txt

# Create a Django project
django-admin startproject "$projectname" .

# add .gitignore file
cat ../gitignore.txt >.gitignore

# add virtual environment to .gitignore
echo "$projectname"_env/ >>.gitignore

# add .env file
cat >.env <<EOL
SECRET_KEY=secret
DEBUG=True
ALLOWED_HOSTS=*
EOL

# update STATIC_URL in settings.py
sed -i "s/STATIC_URL = '\/static\/'/STATIC_URL = '\/static\/'\nSTATIC_ROOT = os.path.join(BASE_DIR, 'static')/g" "$projectname"/settings.py

# add MEDIA_URL to settings.py
sed -i "s/STATIC_ROOT = os.path.join(BASE_DIR, 'static')/STATIC_ROOT = os.path.join(BASE_DIR, 'static')\nMEDIA_URL = '\/media\/'\nMEDIA_ROOT = os.path.join(BASE_DIR, 'media')/g" "$projectname"/settings.py

# add STATICFILES_DIRS to settings.py
sed -i "s/MEDIA_ROOT = os.path.join(BASE_DIR, 'media')/MEDIA_ROOT = os.path.join(BASE_DIR, 'media')\nSTATICFILES_DIRS = \(\n    os.path.join(BASE_DIR, 'staticfiles'),\n\)/g" "$projectname"/settings.py

# setup django rest framework
# add rest_framework to INSTALLED_APPS
sed -i "s/'django.contrib.staticfiles',/'django.contrib.staticfiles',\n    'rest_framework',/g" "$projectname"/settings.py

# add rest_framework_simplejwt to INSTALLED_APPS
sed -i "s/'django.contrib.staticfiles',/'django.contrib.staticfiles',\n    'rest_framework_simplejwt',/g" "$projectname"/settings.py

# add REST_FRAMEWORK to settings.py
sed 
# setting up the packages
# add corsheaders to INSTALLED_APPS
sed -i "s/'django.contrib.staticfiles',/'django.contrib.staticfiles',\n    'corsheaders',/g" "$projectname"/settings.py

# add corsheaders to MIDDLEWARE
sed -i "s/'django.middleware.security.SecurityMiddleware',/'django.middleware.security.SecurityMiddleware',\n    'corsheaders.middleware.CorsMiddleware',/g" "$projectname"/settings.py

# add the CORS_ORIGIN_ALLOW_ALL to settings.py
sed -i "s/# CORS_ORIGIN_ALLOW_ALL = False/CORS_ORIGIN_ALLOW_ALL = True/g" "$projectname"/settings.py

# add the CORS_ORIGIN_WHITELIST to settings.py
sed -i "s/# CORS_ORIGIN_WHITELIST = \(/CORS_ORIGIN_WHITELIST = \(\n    'http:\/\/localhost:3000',/g" "$projectname"/settings.py

# add dotenv
# import dotenv to settings.py
sed -i "s/import os/import os\nfrom dotenv import load_dotenv/g" "$projectname"/settings.py

# add dotenv.load_dotenv() to settings.py
sed -i "s/from dotenv import load_dotenv/load_dotenv\(\)/g" "$projectname"/settings.py


# Prompt for creating a custom user model
read -p "Create a custom user model? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create a custom user model
    python manage.py startapp users
    
    cat ../user/models.txt >>"$projectname"/users/models.py
    cat ../user/admin.txt >>"$projectname"/users/admin.py

    # Add users app to INSTALLED_APPS
    sed -i "s/'django.contrib.staticfiles',/'django.contrib.staticfiles',\n    'users',/g" "$projectname"/settings.py

    # Add custom user model to settings.py
    sed -i "s/'django.contrib.auth.models.User',/'users.models.User',/g" "$projectname"/settings.py

    # Add AUTH_USER_MODEL to settings.py
    sed -i "s/# AUTH_USER_MODEL = 'users.User'/AUTH_USER_MODEL = 'users.User'/g" "$projectname"/settings.py

    # Add users app to urls.py
    sed -i "s/from django.urls import path/from django.urls import path, include/g" "$projectname"/urls.py
    sed -i "s/urlpatterns = \[/urlpatterns = \[\n    path('', include('users.urls')),/g" "$projectname"/urls.py

    # Create users/urls.py
    cat ../user/urls.txt >"$projectname"/users/urls.py

    # Create users/serializers.py
    cat ../user/serializers.txt >"$projectname"/users/serializers.py

    # Create users/views.py
    cat ../user/views.txt >"$projectname"/users/views.py
fi

