# === PHP-FPM Stage ===
FROM php:8.3-fpm AS php

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    curl \
    libicu-dev \
    libzip-dev \
    nginx \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    intl \
    zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copy application files
COPY . .

# Install PHP dependencies
RUN COMPOSER_ALLOW_SUPERUSER=1 composer install --no-interaction --optimize-autoloader

# Set permissions and create log directory
RUN chown -R www-data:www-data /var/www/html/var /var/www/html/public
RUN mkdir -p var/log && chown -R www-data:www-data var/log
RUN mkdir -p var/cache/prod var/log && chown -R www-data:www-data var

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Remove default Nginx config and add ours
COPY nginx.conf /etc/nginx/sites-enabled/default
COPY nginx-main.conf /etc/nginx/nginx.conf

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]