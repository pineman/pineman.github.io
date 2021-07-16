FROM docker.io/node:16.3.0-slim AS builder
WORKDIR /homepage
COPY package*.json build.sh ./
RUN npm ci
COPY src src
RUN ./build.sh

FROM docker.io/php:8.0.8-apache
COPY --from=builder /homepage/bundle /var/www/html
EXPOSE 80
