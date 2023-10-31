#!/usr/bin/env bash

set -e

role=${CONTAINER_ROLE:-app}
env=${APP_ENV:-production}
dbhost=${DB_HOST:-mysql}
dbport=${DB_PORT:-3306}
automigrate=${AUTOMIGRATE:-false}

if [ "$env" != "local" ] && [ "$env" != "testing" ]; then
    echo "Caching configuration..."
    su -s /bin/bash -c 'cd /var/www/html && php artisan config:cache && (php artisan route:cache || true)' www-data
fi

confd -onetime -backend env

case "$role" in
    "queue")
        cp -ar /etc/services.d/worker /etc/service/worker01
        ;;
    "scheduler")
        cp -ar /etc/services.d/scheduler /etc/service/scheduler
        ;;
    "websockets")
        cp -ar /etc/services.d/websockets /etc/service/websockets
        ;;
    "app")
        cp -ar /etc/services.d/nginx /etc/service/nginx
        cp -ar /etc/services.d/php-fpm /etc/service/php-fpm
        php artisan storage:link
        ;;
esac

if [ "$automigrate" = "true" ] && [ "$role" = "scheduler" ]; then
    echo "Waiting for database connection..."
    until nc -z -v -w30 $dbhost $dbport
    do
        # wait for 2 seconds before check again
        echo "."
        sleep 2
    done

    su -s /bin/bash -c 'php artisan migrate --force' www-data
fi

exec "$@"
