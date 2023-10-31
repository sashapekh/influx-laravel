FROM debian:buster-slim as runtime

SHELL ["/bin/bash", "-c"]

ENV PATH="./vendor/bin:${PATH}" \
    NGINX_SERVER_NAME="_" \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="65536" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="128"

ARG USER_UID=33
ARG USER_GID=33
# this gets auto set to the platform the image will be build for e.g. linux/amd64 or linux/arm64
ARG TARGETPLATFORM

# common packages
RUN apt-get update && apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl gnupg netcat nginx-light runit unzip libgd3 jpegoptim pngquant optipng gifsicle webp \
    && rm -rf /var/lib/apt/lists/*

# php and modules, mariadb-client for backups
RUN curl -s https://packages.sury.org/php/apt.gpg | apt-key add -\
 && echo "deb https://packages.sury.org/php/ buster main" > /etc/apt/sources.list.d/php.list\
 && apt-get update -q && apt-get install -y --no-install-recommends php8.2-{apcu,bcmath,curl,dom,fpm,gd,intl,mbstring,mysql,redis,zip,mongodb}\
 && apt-get install -y mariadb-client \
 && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

# overlay
ADD docker/app/overlay /
RUN cp /confd/$TARGETPLATFORM/confd /usr/local/bin/confd \
    && rm -rf /confd

# working dir and ownership
RUN chown -R www-data:www-data /var/www && /usr/local/bin/changeowner.sh www-data $USER_UID $USER_GID
WORKDIR /var/www/html

# startup
ENTRYPOINT ["/usr/local/bin/run-app.sh"]

CMD ["/usr/bin/runsvdir", "-P", "/etc/service"]

# ---------------------

FROM runtime as develop

# env and args
ARG COMPOSER_AUTH
ENV COMPOSER_AUTH=$COMPOSER_AUTH
#ARG NPM_TOKEN
#ENV NPM_TOKEN=$NPM_TOKEN
ENV QT_QPA_PLATFORM=offscreen

# composer
RUN /usr/local/bin/composer-installer.sh \
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer \
    && composer --version

# xdebug // pcov
RUN apt-get update -q && apt-get install -o Dpkg::Options::="--force-confold" -y php8.2-{xdebug,pcov}\
 && phpenmod -v 8.2 -s cli xdebug\
 && rm -rf /var/lib/apt/lists/*

RUN install -o www-data -g www-data -d /var/www/.cache/ \
    && install -o www-data -g www-data -d /var/www/.composer

# ----------------------------

FROM develop as php-builder
ARG COMPOSER_DEV='--no-dev'
COPY --chown=www-data:www-data . /var/www/html
USER www-data
RUN composer install --prefer-dist --optimize-autoloader $COMPOSER_DEV

FROM runtime as production
COPY --chown=www-data --from=php-builder    /var/www/html        /var/www/html
