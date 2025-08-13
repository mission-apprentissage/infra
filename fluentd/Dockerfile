FROM fluent/fluentd:v1.18-debian
USER root

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends build-essential; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*;
RUN fluent-gem install fluent-plugin-grafana-loki
RUN fluent-gem install fluent-plugin-prometheus
RUN fluent-gem install fluent-plugin-s3
# Version 2.7.4 is broken so force update to 2.7.5 (at least)
RUN fluent-gem update json
RUN fluent-gem cleanup json
COPY ./fluent.conf /fluentd/etc/fluent.conf
COPY ./conf.d /fluentd/etc/conf.d
RUN usermod -a -G adm fluent

USER fluent
VOLUME [ "/var/log/fluent" ]
EXPOSE 24231
