FROM docker.io/php:8.0.3-apache
RUN apt-get update && apt-get install -y libpq-dev && docker-php-ext-install pgsql
COPY build /var/www/html
