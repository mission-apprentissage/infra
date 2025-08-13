FROM owasp/modsecurity-crs:4.15.0-nginx-202506050606

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


HEALTHCHECK CMD curl -sk -A healthcheck "http://localhost:8080/healthz"
VOLUME [ "/var/log/nginx" ]
