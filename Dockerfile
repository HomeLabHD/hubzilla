# Hubzilla is fetched at BUILD time at a pinned ref and baked in. The upstream
# container for this clones from framagit on every container start, which makes the
# running version a function of when the pod happened to restart, puts an outage
# between you and a booting pod, and executes whatever is on master at that moment.
ARG PHP_VERSION=8.3

FROM php:${PHP_VERSION}-cli-bookworm AS source

# Every ref is pinned. A moving ref here would reintroduce exactly the problem this
# image exists to remove.
ARG HUBZILLA_REPO=https://github.com/HomeLabHD/hubzilla-core.git
ARG HUBZILLA_REF
ARG ADDONS_REPO=https://github.com/HomeLabHD/hubzilla-addons.git
ARG ADDONS_REF
ARG THEMES_REPO=""
ARG THEMES_REF=""

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends git ca-certificates; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    test -n "${HUBZILLA_REF}" || { echo "HUBZILLA_REF must be pinned"; exit 1; }; \
    test -n "${ADDONS_REF}"   || { echo "ADDONS_REF must be pinned"; exit 1; }; \
    git clone --depth 1 --branch "${HUBZILLA_REF}" "${HUBZILLA_REPO}" /src; \
    git -C /src rev-parse HEAD > /src/.build-core-sha; \
    git clone --depth 1 --branch "${ADDONS_REF}" "${ADDONS_REPO}" /src/extend/addon/addons-official; \
    git -C /src/extend/addon/addons-official rev-parse HEAD > /src/.build-addons-sha; \
    if [ -n "${THEMES_REPO:-}" ]; then \
      git clone --depth 1 --branch "${THEMES_REF}" "${THEMES_REPO}" /src/extend/theme/extra-themes; \
    fi; \
    find /src -name .git -type d -prune -exec rm -rf {} +

FROM php:${PHP_VERSION}-fpm-bookworm

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libicu-dev libgmp-dev \
      libmagickwand-dev imagemagick; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" gd pdo pdo_mysql zip exif intl bcmath gmp; \
    pecl install imagick; \
    docker-php-ext-enable imagick; \
    apt-get purge -y --auto-remove libmagickwand-dev libpng-dev libjpeg-dev \
      libfreetype6-dev libzip-dev libicu-dev libgmp-dev; \
    rm -rf /var/lib/apt/lists/*

COPY php/hubzilla.ini /usr/local/etc/php/conf.d/hubzilla.ini

# Code is owned by root and never written to at runtime. The three paths Hubzilla
# genuinely writes — uploads, compiled templates, and its config — are mounted in, so
# the image itself can run with a read-only root filesystem.
COPY --from=source --chown=root:root /src /var/www/html

RUN set -eux; \
    rm -rf /var/www/html/store /var/www/html/view/tpl/smarty3; \
    mkdir -p /var/www/html/store /var/www/html/view/tpl/smarty3; \
    chown www-data:www-data /var/www/html/store /var/www/html/view/tpl/smarty3

WORKDIR /var/www/html
USER www-data
EXPOSE 9000
CMD ["php-fpm"]
