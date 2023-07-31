FROM fluent/fluentd:v1.16-debian
USER root

RUN fluent-gem install fluent-plugin-grafana-loki
COPY ./fluent.conf /fluentd/etc/fluent.conf
USER fluent
VOLUME [ "/var/log/fluent" ]
