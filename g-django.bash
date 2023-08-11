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

# cd into project directory
cd "$projectname" || exit

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
cat > temp_content.txt <<EOL
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES' : [
        'rest_framework.authentication.SessionAuthentication',
        # 'rest_framework_simplejwt.authentication.JWTAuthentication',
        # 'knox.auth.TokenAuthentication',

    ],
    'DEFAULT_PERMISSION_CLASSES' : [
        'rest_framework.permissions.IsAuthenticatedOrReadOnly'
    ], 

    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.LimitOffsetPagination',
    'PAGE_SIZE': 100
}
EOL

awk -v file=temp_content.txt '/DEFAULT_AUTO_FIELD = '\''django.db.models.BigAutoField'\''/ {print; while (getline < file) print; next} 1' "$projectname/settings.py" > "$projectname/settings.tmp"
mv "$projectname/settings.tmp" "$projectname/settings.py"
rm temp_content.txt


# add SIMPLE_JWT to settings.py
cat > temp_content.txt <<EOL
SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(days=30),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=100),
    "ROTATE_REFRESH_TOKENS": False,
    "BLACKLIST_AFTER_ROTATION": False,
    "UPDATE_LAST_LOGIN": False,

    "ALGORITHM": "HS256",

    "VERIFYING_KEY": "",
    "AUDIENCE": None,
    "ISSUER": None,
    "JSON_ENCODER": None,
    "JWK_URL": None,
    "LEEWAY": 0,

    "AUTH_HEADER_TYPES": ("Bearer",),
    "AUTH_HEADER_NAME": "HTTP_AUTHORIZATION",
    "USER_ID_FIELD": "id",
    "USER_ID_CLAIM": "user_id",
    "USER_AUTHENTICATION_RULE": "rest_framework_simplejwt.authentication.default_user_authentication_rule",

    "AUTH_TOKEN_CLASSES": ("rest_framework_simplejwt.tokens.AccessToken",),
    "TOKEN_TYPE_CLAIM": "token_type",
    "TOKEN_USER_CLASS": "rest_framework_simplejwt.models.TokenUser",

    "JTI_CLAIM": "jti",

    "SLIDING_TOKEN_REFRESH_EXP_CLAIM": "refresh_exp",
    "SLIDING_TOKEN_LIFETIME": timedelta(minutes=5),
    "SLIDING_TOKEN_REFRESH_LIFETIME": timedelta(days=1),

    "TOKEN_OBTAIN_SERIALIZER": "rest_framework_simplejwt.serializers.TokenObtainPairSerializer",
    "TOKEN_REFRESH_SERIALIZER": "rest_framework_simplejwt.serializers.TokenRefreshSerializer",
    "TOKEN_VERIFY_SERIALIZER": "rest_framework_simplejwt.serializers.TokenVerifySerializer",
    "TOKEN_BLACKLIST_SERIALIZER": "rest_framework_simplejwt.serializers.TokenBlacklistSerializer",
    "SLIDING_TOKEN_OBTAIN_SERIALIZER": "rest_framework_simplejwt.serializers.TokenObtainSlidingSerializer",
    "SLIDING_TOKEN_REFRESH_SERIALIZER": "rest_framework_simplejwt.serializers.TokenRefreshSlidingSerializer",
}
EOL

awk -v file=temp_content.txt '/DEFAULT_AUTO_FIELD = '\''django.db.models.BigAutoField'\''/ {print; while (getline < file) print; next} 1' "$projectname/settings.py" > "$projectname/settings.tmp"
mv "$projectname/settings.tmp" "$projectname/settings.py"
rm temp_content.txt



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

# Prompt for setting up channels
read -p "Set up channels for websockets? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # add channels, daphne, channels-redis, django_celery_results, django_celery_beat, celery and django-channels to requirements.txt
    # cd ..
    cd ..
    echo "channels" >>requirements.txt
    echo "daphne" >>requirements.txt
    echo "channels-redis" >>requirements.txt
    echo "django_celery_results" >>requirements.txt
    echo "django_celery_beat" >>requirements.txt
    echo "celery" >>requirements.txt
    echo "django-channels" >>requirements.txt

    # install channels
    pip install channels daphne channels-redis django_celery_results django_celery_beat celery django-channels

    # cd back to project
    cd "$projectname"

    # add channels to INSTALLED_APPS
    cat > temp_content.txt <<EOL
        # Channels
        'daphne',
        'django_celery_results',
        'django_celery_beat',
        'celery',
        'channels',
EOL

    awk -v file=temp_content.txt '/django.contrib.staticfiles/ {print; while (getline < file) print; next} 1' "$projectname/settings.py" > "$projectname/settings.tmp"
    mv "$projectname/settings.tmp" "$projectname/settings.py"
    rm temp_content.txt

    # 