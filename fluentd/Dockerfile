FROM fluent/fluentd:v1.16-debian
USER root

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends build-essential; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*;
RUN fluent-gem install fluent-plugin-grafana-loki
RUN fluent-gem install fluent-plugin-prometheus
RUN fluent-gem install fluent-plugin-s3
COPY ./fluent.conf /fluentd/etc/fluent.conf
COPY ./conf.d /fluentd/etc/conf.d
VOLUME [ "/var/log/fluent" ]
EXPOSE 24231
