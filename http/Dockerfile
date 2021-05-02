FROM docker.io/php:8.0.3-apache
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get -q update && \
	apt-get -qy install --no-install-recommends \
		libpq-dev && \
	docker-php-ext-install pgsql && \
	apt-get -qy autoremove && \
	apt-get clean && \
	rm -r /var/lib/apt/lists/*
COPY build /var/www/html
