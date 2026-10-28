FROM php:8.3-fpm-alpine

ARG MATOMO_VERSION=5.13.0
ARG MATOMO_SHA256=2877f8ce4da93eb8d202f10df5fd26de39a57a481cf0a9d91af5d8e3dbf388fb
ARG MCP_VERSION=5.1.0
ARG MCP_SHA256=9f428b404bc885080299a8a3f2ae4d580390285ea435ca7d1d1e052133e8b208

# Extensions PHP requises par Matomo, absentes de l'image de base
RUN set -eux; \
  apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    freetype-dev \
    icu-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev; \
  docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
  docker-php-ext-install -j"$(nproc)" \
    bcmath \
    gd \
    intl \
    mysqli \
    opcache \
    pdo_mysql \
    zip; \
  runDeps="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
      | tr ',' '\n' \
      | sort -u \
      | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  )"; \
  apk add --no-cache --virtual .matomo-rundeps $runDeps; \
  apk del --no-network .build-deps; \
  cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Code Matomo et plugin McpServer, empreintes verifiees
RUN set -eux; \
  cd /tmp; \
  curl -fsSL -o matomo.tar.gz "https://builds.matomo.org/matomo-${MATOMO_VERSION}.tar.gz"; \
  echo "${MATOMO_SHA256}  matomo.tar.gz" | sha256sum -c -; \
  tar -xzf matomo.tar.gz; \
  mv /tmp/matomo /var/www/matomo; \
  curl -fsSL -o mcp.zip "https://plugins.matomo.org/api/2.0/plugins/McpServer/download/${MCP_VERSION}"; \
  echo "${MCP_SHA256}  mcp.zip" | sha256sum -c -; \
  unzip -q mcp.zip -d /var/www/matomo/plugins; \
  rm -rf /tmp/*; \
  chown -R root:root /var/www/matomo; \
  find /var/www/matomo -type d -exec chmod 0755 {} +; \
  find /var/www/matomo -type f -exec chmod 0644 {} +

COPY --chown=root:root --chmod=0644 bootstrap.php /var/www/matomo/bootstrap.php
COPY --chown=root:root --chmod=0644 php/90-matomo.ini "$PHP_INI_DIR/conf.d/90-matomo.ini"
COPY --chown=root:root --chmod=0644 php/zz-matomo.conf /usr/local/etc/php-fpm.d/zz-matomo.conf

# Arborescence de PIWIK_USER_PATH : un volume nomme monte ici herite de ces
# droits a sa creation
RUN set -eux; \
  mkdir -p /var/lib/matomo/config /var/lib/matomo/tmp /var/lib/matomo/misc/user; \
  chown -R www-data:www-data /var/lib/matomo; \
  chmod -R 0750 /var/lib/matomo

WORKDIR /var/www/matomo

USER www-data

EXPOSE 9000
