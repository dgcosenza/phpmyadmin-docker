# syntax=docker/dockerfile:1.7
# Hardened phpMyAdmin on Debian 13 (trixie) with Apache + PHP 8.3
# Upstream: https://www.phpmyadmin.net/ / https://github.com/phpmyadmin/docker
# Maintainer: Daniel G. Cosenza from FNX Labs

ARG PHP_BASE=php:8.3.37-apache-trixie@sha256:fb5e44981a84757b95cd29440f534509f42a9766382c8c83bfd404924a62379b
ARG COMPOSER_BASE=composer:2@sha256:0049ce90b432795bf413a738b073963ada1a689e1a8708104684baafe94586ec
ARG PHP_VERSION=8.3.37
ARG PMA_VERSION=5.2.3
# Official phpMyAdmin release signing key (Isaac Bennetch)
ARG PMA_GPG_FPR=3D06A59ECE730EB71B511C17CE752F178259BD92
ARG UPLOAD_PROGRESS_VERSION=2.0.2
ARG UPLOAD_PROGRESS_SHA256=fe3f6cdfcedad563c970c4fd1cda31e422cfc0df5cc9a217d8c80ed3c8d137f5
ARG IMAGE_CREATED=1970-01-01T00:00:00Z
ARG IMAGE_REVISION=dev
ARG IMAGE_SOURCE=https://github.com/dgcosenza/phpmyadmin-docker

FROM ${COMPOSER_BASE} AS composer-bin

# ---- Stage 1: Hardened PHP 8.3 + Apache on Debian 13 (trixie) base ----
FROM ${PHP_BASE} AS base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG UPLOAD_PROGRESS_VERSION
ARG UPLOAD_PROGRESS_SHA256
ARG DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get -y upgrade; \
    apt-get install -y --no-install-recommends curl ca-certificates; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get install -y --no-install-recommends \
        libbz2-dev \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libwebp-dev \
        libxpm-dev \
        libzip-dev; \
    \
    mkdir -p /tmp/uploadprogress; \
    curl -fsSL -o /tmp/uploadprogress/uploadprogress.tar.gz \
        "https://github.com/php/pecl-php-uploadprogress/archive/refs/tags/uploadprogress-${UPLOAD_PROGRESS_VERSION}.tar.gz"; \
    echo "${UPLOAD_PROGRESS_SHA256}  /tmp/uploadprogress/uploadprogress.tar.gz" | sha256sum -c -; \
    tar -xf /tmp/uploadprogress/uploadprogress.tar.gz -C /tmp/uploadprogress --strip-components=1; \
    \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-xpm; \
    docker-php-ext-install -j "$(nproc)" \
        bz2 \
        gd \
        mysqli \
        opcache \
        zip \
        bcmath \
        /tmp/uploadprogress; \
    rm -rf /tmp/uploadprogress; \
    \
    apt-mark auto '.*' > /dev/null; \
    printf '%s\n' "${savedAptMark}" | xargs -r apt-mark manual > /dev/null; \
    extdir="$(php -r 'echo ini_get("extension_dir");')"; \
    ldd "${extdir}"/*.so \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
        | sort -u \
        | xargs -r dpkg-query -S \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    a2enmod remoteip; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; \
    ldd "${extdir}"/*.so | grep -qzv "=> not found"; \
    php --version

# ---- Stage 2: Verify phpMyAdmin tarball (SHA256 + GPG) and patch PHP vendor deps ----
FROM base AS pma-builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG PMA_VERSION
ARG PMA_GPG_FPR
ARG DEBIAN_FRONTEND=noninteractive

COPY --from=composer-bin /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends git gnupg xz-utils unzip; \
    rm -rf /var/lib/apt/lists/*; \
    \
    URL="https://files.phpmyadmin.net/phpMyAdmin/${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.tar.xz"; \
    curl -fsSL -o /tmp/phpMyAdmin.tar.xz "${URL}"; \
    curl -fsSL -o /tmp/phpMyAdmin.tar.xz.asc "${URL}.asc"; \
    curl -fsSL -o /tmp/phpMyAdmin.tar.xz.sha256 "${URL}.sha256"; \
    EXPECTED_SHA="$(awk '{print $1}' /tmp/phpMyAdmin.tar.xz.sha256)"; \
    echo "${EXPECTED_SHA}  /tmp/phpMyAdmin.tar.xz" | sha256sum -c -; \
    \
    GNUPGHOME="$(mktemp -d)"; \
    export GNUPGHOME; \
    curl -fsSL -o /tmp/phpmyadmin.keyring "https://files.phpmyadmin.net/phpmyadmin.keyring"; \
    gpg --batch --import /tmp/phpmyadmin.keyring; \
    gpg --batch --fingerprint "${PMA_GPG_FPR}" >/dev/null; \
    VERIFY_OUT="$(gpg --batch --status-fd 1 --verify /tmp/phpMyAdmin.tar.xz.asc /tmp/phpMyAdmin.tar.xz)"; \
    echo "${VERIFY_OUT}" | grep -q "VALIDSIG ${PMA_GPG_FPR}"; \
    gpgconf --kill all || true; \
    rm -rf "${GNUPGHOME}" /tmp/phpmyadmin.keyring /tmp/phpMyAdmin.tar.xz.asc /tmp/phpMyAdmin.tar.xz.sha256; \
    \
    rm -rf /var/www/html/*; \
    tar -xf /tmp/phpMyAdmin.tar.xz -C /var/www/html --strip-components=1; \
    rm -f /tmp/phpMyAdmin.tar.xz; \
    \
    # Strip require-dev and dev-only VCS repositories, then refresh production \
    # Composer dependencies to patch known vendor CVEs (Twig, Symfony). \
    php -r '$j = json_decode(file_get_contents("composer.json"), true); unset($j["require-dev"]); $j["repositories"] = array_values(array_filter($j["repositories"] ?? [], fn($r) => ($r["type"] ?? "") !== "github")); file_put_contents("composer.json", json_encode($j, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");'; \
    COMPOSER_ALLOW_SUPERUSER=1 COMPOSER_NO_INTERACTION=1 \
        composer update --no-dev --no-progress --prefer-dist --optimize-autoloader --with-all-dependencies; \
    rm -rf /root/.composer /tmp/*; \
    \
    rm -rf /var/www/html/setup/ /var/www/html/examples/ /var/www/html/js/src/ \
        /var/www/html/babel.config.json /var/www/html/doc/html/_sources/ \
        /var/www/html/RELEASE-DATE-* /var/www/html/CONTRIBUTING.md; \
    mkdir -p /var/www/html/tmp; \
    grep -q -F "'configFile' => ROOT_PATH . 'config.inc.php'," /var/www/html/libraries/vendor_config.php; \
    sed -i "s@'configFile' => .*@'configFile' => '/etc/phpmyadmin/config.inc.php',@" /var/www/html/libraries/vendor_config.php; \
    php -l /var/www/html/libraries/vendor_config.php; \
    php -l /var/www/html/index.php; \
    find /var/www/html -type d -exec chmod 555 {} \;; \
    find /var/www/html -type f -exec chmod 444 {} \;; \
    chmod 1777 /var/www/html/tmp

# ---- Stage 3: Minimal runtime image ----
FROM base AS runtime

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG PHP_VERSION
ARG PMA_VERSION
ARG IMAGE_CREATED
ARG IMAGE_REVISION
ARG IMAGE_SOURCE

LABEL org.opencontainers.image.title="phpMyAdmin on Debian 13 (trixie)" \
      org.opencontainers.image.description="Hardened phpMyAdmin container image on Debian 13 (trixie) with PHP 8.3, Apache, GPG-verified upstream release, and patched Composer dependencies, maintained by Daniel G. Cosenza from FNX Labs." \
      org.opencontainers.image.version="${PMA_VERSION}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.url="https://hub.docker.com/r/dgcosenza/phpmyadmin" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="${IMAGE_SOURCE}#readme" \
      org.opencontainers.image.vendor="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.authors="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.licenses="GPL-2.0-only AND MIT" \
      org.opencontainers.image.base.name="php:${PHP_VERSION}-apache-trixie" \
      io.github.dgcosenza.phpmyadmin.version="${PMA_VERSION}" \
      io.github.dgcosenza.phpmyadmin.php="${PHP_VERSION}"

ENV PMA_SSL_DIR=/etc/phpmyadmin/ssl \
    MAX_EXECUTION_TIME=600 \
    MEMORY_LIMIT=512M \
    UPLOAD_LIMIT=2048K \
    TZ=UTC \
    SESSION_SAVE_PATH=/sessions \
    VERSION="${PMA_VERSION}"

RUN set -eux; \
    mkdir -p "${SESSION_SAVE_PATH}" "${PMA_SSL_DIR}" /etc/phpmyadmin; \
    chmod 1777 "${SESSION_SAVE_PATH}"; \
    chmod 755 "${PMA_SSL_DIR}" /etc/phpmyadmin; \
    chown -R www-data:www-data /etc/phpmyadmin "${SESSION_SAVE_PATH}"; \
    \
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
    } > "${PHP_INI_DIR}/conf.d/opcache-recommended.ini"; \
    \
    { \
        echo 'session.cookie_httponly=1'; \
        echo 'session.use_strict_mode=1'; \
    } > "${PHP_INI_DIR}/conf.d/session-strict.ini"; \
    \
    { \
        echo 'allow_url_fopen=Off'; \
        echo 'expose_php=Off'; \
        echo 'max_execution_time=${MAX_EXECUTION_TIME}'; \
        echo 'max_input_vars=10000'; \
        echo 'memory_limit=${MEMORY_LIMIT}'; \
        echo 'post_max_size=${UPLOAD_LIMIT}'; \
        echo 'upload_max_filesize=${UPLOAD_LIMIT}'; \
        echo 'date.timezone=${TZ}'; \
        echo 'session.save_path=${SESSION_SAVE_PATH}'; \
    } > "${PHP_INI_DIR}/conf.d/phpmyadmin-misc.ini"

COPY --from=pma-builder --chown=www-data:www-data /var/www/html /var/www/html
COPY --chown=www-data:www-data config.inc.php /etc/phpmyadmin/config.inc.php
COPY --chown=www-data:www-data helpers.php /etc/phpmyadmin/helpers.php
COPY --chmod=0755 docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2-foreground"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD ["curl", "-fsS", "http://127.0.0.1:80/"]
