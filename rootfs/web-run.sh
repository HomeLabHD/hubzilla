#!/bin/sh
# php-fpm and nginx are one unit: if either exits the container must exit too, so the
# orchestrator restarts a whole pod rather than serving 502s from a half-dead one.
set -eu

mkdir -p /tmp/nginx-client-body /tmp/nginx-proxy /tmp/nginx-fastcgi /tmp/nginx-uwsgi /tmp/nginx-scgi

php-fpm --nodaemonize &
fpm=$!

nginx -g 'daemon off;' &
web=$!

trap 'kill -TERM "$fpm" "$web" 2>/dev/null' TERM INT

while kill -0 "$fpm" 2>/dev/null && kill -0 "$web" 2>/dev/null; do
    sleep 1
done

kill -TERM "$fpm" "$web" 2>/dev/null || true
wait "$fpm" "$web" 2>/dev/null || true
exit 1
