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
    php84 \
    php84-common \
    php84-fpm \
    php84-intl \
    php84-gd \
    php84-mysqli \
    php84-pdo \
    php84-opcache \
    php84-zip \
    php84-phar \
    php84-iconv \
    php84-cli \
    php84-curl \
    php84-openssl \
    php84-mbstring \
    php84-tokenizer \
    php84-fileinfo \
    php84-json \
    php84-xml \
    php84-xmlwriter \
    php84-simplexml \
    php84-dom \
    php84-pdo_mysql \
    php84-pdo_sqlite \
    php84-tokenizer \
    php84-pecl-redis \
    php84-dev \
    php84-pear \
    php84-exif \
    php84-ctype \
    php84-xmlreader \
    php84-dev \
    autoconf \
    supervisor

# Create symlink so programs depending on `php` still function
RUN ln -s /usr/bin/php84 /usr/bin/php
RUN ln -s /usr/bin/pecl84 /usr/bin/pecl


# Apple Silicon
RUN apk --no-cache add g++ gcc unixodbc-dev gnupg gpg
RUN apk add --no-cache make

ARG architecture=arm64
#Download the desired package(s)
RUN curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/msodbcsql18_18.3.2.1-1_$architecture.apk
RUN curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/mssql-tools18_18.3.1.1-1_$architecture.apk


#(Optional) Verify signature, if 'gpg' is missing install it using 'apk add gnupg':
RUN curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/msodbcsql18_18.3.2.1-1_$architecture.sig
RUN curl -O https://download.microsoft.com/download/3/5/5/355d7943-a338-41a7-858d-53b259ea33f5/mssql-tools18_18.3.1.1-1_$architecture.sig

RUN curl https://packages.microsoft.com/keys/microsoft.asc   | gpg --import -
# RUN gpg --verify msodbcsql18_18.3.2.1-1_$architecture.sig msodbcsql18_18.3.2.1-1_$architecture.apk 
# RUN gpg --verify mssql-tools18_18.3.1.1-1_$architecture.sig mssql-tools18_18.3.1.1-1_$architecture.apk


#Install the package(s)
RUN  apk add --allow-untrusted msodbcsql18_18.3.2.1-1_$architecture.apk
RUN  apk add --allow-untrusted mssql-tools18_18.3.1.1-1_$architecture.apk
RUN pecl install sqlsrv pdo_sqlsrv

RUN echo "extension=sqlsrv.so" > /etc/php84/conf.d/20_sqlsrv.ini && \
    echo "extension=pdo_sqlsrv.so" > /etc/php84/conf.d/30_pdo_sqlsrv.ini && \
    chmod 644 /usr/lib/php84/modules/sqlsrv.so && \
    chmod 644 /usr/lib/php84/modules/pdo_sqlsrv.so && \
    echo "PHP Modules:" && \
    php -m && \
    echo "Extension directory:" && \
    php -i | grep "extension_dir"

# Install composer from the official image
COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN mkdir -p /.composer && chown -R nobody:nobody /.composer

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php84/php-fpm.d/www.conf
COPY config/php.ini /etc/php84/conf.d/custom.ini

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