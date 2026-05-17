#!/bin/bash
set -e

echo "🚀 Starting Symfony Production Deployment..."

# Load environment variables
set -a
source /var/www/html/.env
set +a

# Wait for database
echo "⏳ Waiting for database..."
until php -r "new PDO('mysql:host=mysql', '${MYSQL_USER}', '${MYSQL_PASSWORD}');" 2>/dev/null; do
    echo "Still waiting..."
    sleep 2
done
echo "✅ Database is ready!"

# Fix permissions FIRST
echo "🔧 Fixing permissions..."
mkdir -p var/cache var/log
chown -R www-data:www-data var
chmod -R 775 var

# Run migrations
echo "📦 Running database migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration || true

# Clear cache
echo "🧹 Clearing cache..."
php bin/console cache:clear --env=prod --no-debug || true

# Fix permissions AGAIN after cache clear
chown -R www-data:www-data var
chmod -R 775 var

# Start services
echo "🌐 Starting Nginx & PHP-FPM..."
service nginx start
php-fpm -F