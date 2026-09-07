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
    # Hubzilla loads an addon from addon/<name>/<name>.php and nowhere else, so a cloned
    # repo is invisible until each addon inside it is linked into addon/. This is what
    # util/add_addon_repo does after its clone; without it the bundled set — pubcrawl,
    # which is the whole ActivityPub story, included — is present but unusable.
    mkdir -p /src/addon; \
    for dir in /src/extend/addon/addons-official/*/; do \
      [ -d "$dir" ] || continue; \
      name="$(basename "$dir")"; \
      ln -sfn "../extend/addon/addons-official/$name" "/src/addon/$name"; \
    done; \
    find /src -name .git -type d -prune -exec rm -rf {} +

FROM php:${PHP_VERSION}-fpm-bookworm

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      libpng-dev libjpeg-dev libfreetype6-dev libzip-dev libicu-dev libgmp-dev \
      libmagickwand-dev imagemagick msmtp nginx tini; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" gd pdo pdo_mysql zip exif intl bcmath gmp; \
    pecl install imagick; \
    docker-php-ext-enable imagick; \
    apt-get purge -y --auto-remove libmagickwand-dev libpng-dev libjpeg-dev \
      libfreetype6-dev libzip-dev libicu-dev libgmp-dev; \
    # Purging the -dev packages takes libzip's runtime with them, and an extension
    # built against a library that is no longer present fails to load at startup.
    apt-get install -y --no-install-recommends libzip4; \
    rm -rf /var/lib/apt/lists/*

COPY php/hubzilla.ini /usr/local/etc/php/conf.d/hubzilla.ini

# Hubzilla routes on a q= query parameter, answers discovery out of index.php, and needs the
# Authorization header for DAV — rules that belong to the application, not to whoever deploys
# it. They travel with the code so an upgrade cannot leave them behind.
COPY rootfs/nginx.conf            /etc/nginx/nginx.conf
COPY rootfs/php-fpm-hubzilla.conf /usr/local/etc/php-fpm.d/zz-hubzilla.conf
COPY rootfs/web-run.sh            /usr/local/bin/web-run.sh
RUN set -eux; \
    chmod +x /usr/local/bin/web-run.sh; \
    rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf

# Hubzilla sends through PHP's mail(), which needs a sendmail binary the php image
# does not carry: without one, registration, password resets and every notification
# fail. msmtp relays instead, reading credentials from the environment at send time so
# nothing lands in an image layer.
COPY php/msmtp.ini /usr/local/etc/php/conf.d/msmtp.ini
COPY bin/sendmail /usr/local/bin/sendmail

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
EXPOSE 8080
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["web-run.sh"]
