#!/bin/bash
# entrypoint.sh

# Load environment variables if .env file exists
if [ -f "/var/www/html/.env" ]; then
    echo "Loading environment variables from .env file..."
    set -a  # automatically export all variables
    source /var/www/html/.env
    set +a
fi

# Set default values if environment variables are not set
MEDIAWIKI_ADMIN_PASSWORD=${MEDIAWIKI_ADMIN_PASSWORD:-"admin123"}
MEDIAWIKI_PROD_PASSWORD=${MEDIAWIKI_PROD_PASSWORD:-"WikiLuaTestAdmin2024#"}
MEDIAWIKI_DB_TYPE=${MEDIAWIKI_DB_TYPE:-"sqlite"}
MEDIAWIKI_DB_PATH=${MEDIAWIKI_DB_PATH:-"/var/www/html/data"}
MEDIAWIKI_DB_NAME=${MEDIAWIKI_DB_NAME:-"my_wiki"}
MEDIAWIKI_SITE_NAME=${MEDIAWIKI_SITE_NAME:-"Wiki Lua Test"}
MEDIAWIKI_ADMIN_USER=${MEDIAWIKI_ADMIN_USER:-"Admin"}
MEDIAWIKI_SERVER_URL=${MEDIAWIKI_SERVER_URL:-"http://localhost:8080"}

if [ "$1" = "test" ]; then
    echo "Running in test mode with mocks..."
    if [ -n "$2" ]; then
        # Copy environment files if they exist
        if [ -f /var/www/html/modules/custom/module-loader.lua ]; then
            cp /var/www/html/modules/custom/module-loader.lua /var/www/html/module-loader.lua
        fi
        if [ -f /var/www/html/modules/custom/wiki-lua-env.lua ]; then
            cp /var/www/html/modules/custom/wiki-lua-env.lua /var/www/html/wiki-lua-env.lua
        fi
        
        # Use the simplified script
        php -d display_errors=1 /var/www/html/test-script-simple.php "/var/www/html/modules/custom/$2"
    else
        echo "ERROR: No test module specified"
        echo "Usage: docker run ... test MODULE_NAME.lua"
        exit 1
    fi
elif [ "$1" = "real-test" ]; then
    echo "Running with real Scribunto..."
    if [ -n "$2" ]; then
        # Initialize database if needed
        if [ ! -f "/var/www/html/data/my_wiki.sqlite" ]; then
            echo "Setting up database..."
            cd /var/www/html/maintenance
            php install.php --dbtype="$MEDIAWIKI_DB_TYPE" --dbpath="$MEDIAWIKI_DB_PATH" --dbname="$MEDIAWIKI_DB_NAME" \
                --scriptpath="" --server="http://localhost" \
                --pass="$MEDIAWIKI_ADMIN_PASSWORD" "$MEDIAWIKI_SITE_NAME" "$MEDIAWIKI_ADMIN_USER"
            php update.php --quick
        fi
        
        # Run with real MediaWiki
        cd /var/www/html/maintenance
        php /var/www/html/unmocked-test.php --file="/var/www/html/modules/custom/$2"
    else
        echo "ERROR: No test module specified"
        echo "Usage: docker run ... real-test MODULE_NAME.lua"
        exit 1
    fi
else
    echo "Running in web server mode..."
    
    # Initialize database if needed
    if [ ! -f "/var/www/html/data/my_wiki.sqlite" ]; then
        echo "Setting up database..."
        mkdir -p /var/www/html/data
        chown www-data:www-data /var/www/html/data
        
        # Temporarily remove LocalSettings.php if it exists to allow fresh installation
        if [ -f "/var/www/html/LocalSettings.php" ]; then
            mv /var/www/html/LocalSettings.php /var/www/html/LocalSettings.backup.php
        fi
        
        cd /var/www/html/maintenance
        php install.php --dbtype="$MEDIAWIKI_DB_TYPE" --dbpath="$MEDIAWIKI_DB_PATH" --dbname="$MEDIAWIKI_DB_NAME" \
            --scriptpath="" --server="$MEDIAWIKI_SERVER_URL" \
            --pass="$MEDIAWIKI_PROD_PASSWORD" "$MEDIAWIKI_SITE_NAME" "$MEDIAWIKI_ADMIN_USER"
        echo "Database setup completed"
        
        # Apply our custom LocalSettings.php with Scribunto configuration
        if [ -f "/var/www/html/LocalSettings.template.php" ]; then
            echo "Applying custom LocalSettings.php with Scribunto support..."
            cp /var/www/html/LocalSettings.template.php /var/www/html/LocalSettings.php
            
            # Run database update to install Scribunto tables
            echo "Installing Scribunto extension..."
            php update.php --quick
            echo "Scribunto installation completed"
        else
            echo "⚠ LocalSettings template not found, using default installation"
        fi
        
        # Check if database was actually created
        if [ -f "/var/www/html/data/my_wiki.sqlite" ]; then
            echo "✓ Database file created successfully"
            chown www-data:www-data /var/www/html/data/my_wiki*.sqlite
        else
            echo "⚠ Database file not found, but continuing..."
        fi
    else
        echo "Database already exists, ensuring LocalSettings.php is properly configured..."
        # Apply our custom LocalSettings.php if template exists and current doesn't have Scribunto
        if [ -f "/var/www/html/LocalSettings.template.php" ]; then
            if ! grep -q "Scribunto" /var/www/html/LocalSettings.php 2>/dev/null; then
                echo "Applying Scribunto configuration..."
                cp /var/www/html/LocalSettings.template.php /var/www/html/LocalSettings.php
                cd /var/www/html/maintenance
                php update.php --quick
            fi
        fi
    fi
    
    apache2-foreground
fi
