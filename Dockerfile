ARG ALPINE_VERSION=3.16
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Janaki Mahapatra <mailme@mjanaki.com>"
LABEL Description="Lightweight container with Nginx 1.22 & PHP 8 based on Alpine Linux."

# Setup document root
WORKDIR /var/www/html

# Essentials
RUN echo "UTC" > /etc/timezone
RUN apk add --no-cache zip unzip curl sqlite nginx supervisor

# Installing bash
RUN apk add bash
RUN sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd

# Installing PHP
RUN apk add --no-cache \
    curl \
    nginx \
    php8 \
    php8-common \
    php8-fpm \
    php8-intl \
    php8-gd \
    php8-mysqli \
    php8-pdo \
    php8-opcache \
    php8-zip \
    php8-phar \
    php8-iconv \
    php8-cli \
    php8-curl \
    php8-openssl \
    php8-mbstring \
    php8-tokenizer \
    php8-fileinfo \
    php8-json \
    php8-xml \
    php8-xmlwriter \
    php8-simplexml \
    php8-dom \
    php8-pdo_mysql \
    php8-pdo_sqlite \
    php8-tokenizer \
    php8-pecl-redis \
    supervisor

# Create symlink so programs depending on `php` still function
# RUN ln -s /usr/bin/php8 /usr/bin/php

# Install composer from the official image
COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN mkdir /.composer

RUN chown -R nobody.nobody /.composer

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php8/php-fpm.d/www.conf

COPY config/php.ini /etc/php8/conf.d/custom.ini

# Configure supervisord
COPY config/supervisor.8.0.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
# COPY --chown=nobody ./ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 80

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping


# # Installing composer
# RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
# RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
# RUN rm -rf composer-setup.php

# # Configure supervisor
# RUN mkdir -p /etc/supervisor.d/
# COPY config/supervisor.8.0.conf /etc/supervisor.d/supervisord.conf

# # Configure PHP
# RUN mkdir -p /run/php/
# RUN touch /run/php/php8.0-fpm.pid

# COPY config/php-fpm-8.0.conf /etc/php8/php-fpm.conf
# COPY config/php.ini /etc/php8/php.ini

# # Configure nginx
# COPY config/nginx.8.0.conf /etc/nginx/nginx.conf

# RUN mkdir -p /run/nginx/
# RUN touch /run/nginx.pid

# RUN ln -sf /dev/stdout /var/log/nginx/access.log
# RUN ln -sf /dev/stderr /var/log/nginx/error.log

# # Make sure files/folders needed by the processes are accessable when they run under the nobody user
# RUN chown -R nobody.nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# # Switch to use a non-root user from here on
# USER nobody

# # # Building process
# # COPY . .
# # RUN composer install --no-dev

# # RUN chown -R nobody:nobody /var/www/html/storage

# EXPOSE 80
# CMD ["supervisord", "-c", "/etc/supervisor.d/supervisord.ini"]

# # Configure a healthcheck to validate that everything is up&running
# HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:80/fpm-ping
