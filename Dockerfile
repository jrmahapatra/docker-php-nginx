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
    php8-dev \
    php8-pear \
    php8-exif \
    php8-ctype \
    php8-xmlreader \
    php8-dev \
    autoconf \
    supervisor \
    nodejs \
    npm

# Create symlink so programs depending on `php` still function
# RUN ln -s /usr/bin/php8 /usr/bin/php



## Intel x86
# SQL SERVER DRIVER
# RUN apk --no-cache add g++ gcc unixodbc-dev gnupg
# RUN apk add --no-cache make
# RUN apk add libbaz

# #Download the desired package(s)
# RUN curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.10.2.1-1_amd64.apk
# RUN curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.10.1.1-1_amd64.apk

# #(Optional) Verify signature, if 'gpg' is missing install it using 'apk add gnupg':
# RUN curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.10.2.1-1_amd64.sig
# RUN curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.10.1.1-1_amd64.sig

# RUN curl https://packages.microsoft.com/keys/microsoft.asc  | gpg --import -

# #Install the package(s)
# RUN apk add --allow-untrusted msodbcsql17_17.10.2.1-1_amd64.apk
# RUN apk add --allow-untrusted mssql-tools_17.10.1.1-1_amd64.apk

# RUN set -xe \    
#     && pecl install sqlsrv pdo_sqlsrv



# RUN echo extension=sqlsrv.so >> /etc/php8/php.ini
# RUN echo extension=pdo_sqlsrv.so >> /etc/php8/php.ini



# ## Apple Silicon
# RUN apk --no-cache add g++ gcc unixodbc-dev gnupg gpg
# RUN apk add --no-cache make
# ARG architecture=arm64
# #Download the desired package(s)
# RUN curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/msodbcsql18_18.3.2.1-1_$architecture.apk
# RUN curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/mssql-tools18_18.3.1.1-1_$architecture.apk


# #(Optional) Verify signature, if 'gpg' is missing install it using 'apk add gnupg':
# RUN curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/msodbcsql18_18.3.2.1-1_$architecture.sig
# RUN curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/mssql-tools18_18.3.1.1-1_$architecture.sig

# RUN curl https://packages.microsoft.com/keys/microsoft.asc   | gpg --import -
# # RUN gpg --verify msodbcsql18_18.3.2.1-1_$architecture.sig msodbcsql18_18.3.2.1-1_$architecture.apk 
# # RUN gpg --verify mssql-tools18_18.3.1.1-1_$architecture.sig mssql-tools18_18.3.1.1-1_$architecture.apk


# #Install the package(s)
# RUN  apk add --allow-untrusted msodbcsql18_18.3.2.1-1_$architecture.apk
# RUN  apk add --allow-untrusted mssql-tools18_18.3.1.1-1_$architecture.apk
# RUN pecl install sqlsrv pdo_sqlsrv



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
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

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
