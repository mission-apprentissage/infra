FROM fluent/fluentd:v1.16-debian
USER root

RUN fluent-gem install fluent-plugin-grafana-loki
RUN fluent-gem install fluent-plugin-prometheus --version=0.4.0
COPY ./fluent.conf /fluentd/etc/fluent.conf
VOLUME [ "/var/log/fluent" ]
EXPOSE 24231
