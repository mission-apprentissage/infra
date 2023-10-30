ARG NGINX_VERSION="1.22.1"
FROM nginx:${NGINX_VERSION} as nginxModules

ARG HEADERS_MORE_VERSION="v0.34"

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
  automake \
  cmake \
  doxygen \
  g++ \
  git \
  libcurl4-gnutls-dev \
  libgeoip-dev \
  liblua5.3-dev \
  libpcre++-dev \
  libtool \
  libxml2-dev \
  make \
  ruby \
  pkg-config \
  zlib1g-dev; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*

WORKDIR /sources

# We use master
RUN set -eux; \
  git clone -b "${HEADERS_MORE_VERSION}" --depth 1 https://github.com/openresty/headers-more-nginx-module; \
  curl -sSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx-${NGINX_VERSION}.tar.gz; \
  tar -xzf nginx-${NGINX_VERSION}.tar.gz; \
  cd ./nginx-${NGINX_VERSION}; \
  ./configure --with-compat --add-dynamic-module=../headers-more-nginx-module; \
  make modules; \
  strip objs/ngx_http_headers_more_filter_module.so; \
  cp objs/ngx_http_headers_more_filter_module.so /etc/nginx/modules/;

FROM owasp/modsecurity-crs:3.3.4-nginx-202303180303

COPY --from=nginxModules /etc/nginx/modules/ngx_http_headers_more_filter_module.so /etc/nginx/modules/ngx_http_headers_more_filter_module.so

#Nginx
COPY files/templates /etc/nginx/templates
COPY files/reload.sh /reload.sh

ENV NGINX_ALWAYS_TLS_REDIRECT=true
ENV PARANOIA=1
ENV ANOMALY_INBOUND=5
ENV ANOMALY_OUTBOUND=4
ENV REPORTING_LEVEL=4
ENV DNS_SERVER=127.0.0.11
ENV LOGLEVEL=warn
ENV ALLOWED_METHODS="GET HEAD POST OPTIONS PUT PATCH DELETE"
ENV MODSEC_AUDIT_LOG_FORMAT="JSON"
ENV MODSEC_AUDIT_LOG="/var/log/nginx/modsec_audit.log"
ENV ALLOWED_REQUEST_CONTENT_TYPE="|application/x-www-form-urlencoded| |multipart/form-data| |multipart/related| |text/xml| |application/xml| |application/soap+xml| |application/json| |application/cloudevents+json| |application/cloudevents-batch+json| |text/plain|"

HEALTHCHECK CMD curl -sk -A healthcheck "http://localhost/healthz"
VOLUME [ "/var/log/nginx" ]
