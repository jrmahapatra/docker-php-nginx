FROM alpine:latest

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


# Install packages and remove default server definition
RUN apk add --no-cache \
    curl \
    nginx \
    php83 \
    php83-common \
    php83-fpm \
    php83-intl \
    php83-gd \
    php83-mysqli \
    php83-pdo \
    php83-opcache \
    php83-zip \
    php83-phar \
    php83-iconv \
    php83-cli \
    php83-curl \
    php83-openssl \
    php83-mbstring \
    php83-tokenizer \
    php83-fileinfo \
    php83-json \
    php83-xml \
    php83-xmlwriter \
    php83-simplexml \
    php83-dom \
    php83-pdo_mysql \
    php83-pdo_sqlite \
    php83-tokenizer \
    php83-pecl-redis \
    php83-dev \
    php83-pear \
    php83-exif \
    php83-ctype \
    php83-xmlreader \
    php83-dev \
    autoconf \
    supervisor

# Create symlink so programs depending on `php` still function
RUN ln -sf /usr/bin/php83 /usr/bin/php
RUN ln -sf /usr/bin/pecl83 /usr/bin/pecl


## Apple Silicon
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

RUN mkdir -p /.composer && chown -R nobody:nobody /.composer

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php83/php-fpm.d/www.conf
COPY config/php.ini /etc/php83/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody:nobody /var/www/html /run /var/lib/nginx /var/log/nginx

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