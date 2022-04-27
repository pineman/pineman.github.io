FROM docker.io/node:16.3.0-slim AS builder
WORKDIR /homepage
COPY package*.json build.sh ./
RUN npm ci
COPY . .
RUN ./build.sh

FROM docker.io/php:8.1.2-apache
COPY --from=builder /homepage/bundle /var/www/html
RUN curl -L https://github.com/chmln/sd/releases/download/v0.7.6/sd-v0.7.6-x86_64-unknown-linux-gnu > /usr/bin/sd
RUN chmod +x /usr/bin/sd
RUN sd -s 'Listen 80' 'Listen 8081' /etc/apache2/ports.conf
RUN sd -s 'VirtualHost *:80' 'VirtualHost *:8081' /etc/apache2/sites-available/000-default.conf
RUN sd -s '#ServerName www.example.com' 'ServerName www.pineman.eu' /etc/apache2/sites-available/000-default.conf
EXPOSE 8081
