#!/bin/bash

php_fpm_CONF=/xcdata/server/php/etc/php-fpm.conf
php_fpm_PID=/xcdata/server/php/var/run/php-fpm.pid
nginx_CONF=/etc/nginx/nginx.conf

/xcdata/server/php/sbin/php-fpm --fpm-config $php_fpm_CONF --pid $php_fpm_PID
/usr/sbin/nginx -g "daemon off;" -c $nginx_CONF
