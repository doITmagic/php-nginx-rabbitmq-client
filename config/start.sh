#!/bin/bash
set -e

# start php7.1-fpm
service php7.1-fpm start

# start nginx
exec /usr/sbin/nginx 