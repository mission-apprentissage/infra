FROM fluent/fluentd:v1.19-debian-1
USER root

ARG AWS_PARTITIONS_VERSION=1.1180.0
ARG AWS_SIGV4_VERSION=1.12.1
ARG AWS_SDK_CORE_VERSION=3.236.0
ARG AWS_SDK_KMS_VERSION=1.116.0
ARG AWS_SDK_S3_VERSION=1.202.0
ARG FLUENT_PLUGIN_S3_VERSION=1.8.3
ARG FLUENT_PLUGIN_GRAFANA_LOKI_VERSION=1.2.20
ARG FLUENT_PLUGIN_PROMETHEUS_VERSION=2.2.1
ARG FLUENT_PLUGIN_RECORD_MODIFIER_VERSION=2.2.1
ARG JSON_VERSION=2.15.2

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends build-essential; \
  apt-get clean; \
  rm -rf /var/lib/apt/lists/*;

# Dépendances AWS installées en premier, puis plugins avec --conservative :
# une dependance déjà satisfaite n'est pas remontée à sa dernière version

RUN set -eux; \
  fluent-gem install --no-document json -v "${JSON_VERSION}"; \
  fluent-gem install --no-document aws-partitions -v "${AWS_PARTITIONS_VERSION}"; \
  fluent-gem install --no-document --conservative aws-sigv4 -v "${AWS_SIGV4_VERSION}"; \
  fluent-gem install --no-document --conservative aws-sdk-core -v "${AWS_SDK_CORE_VERSION}"; \
  fluent-gem install --no-document --conservative aws-sdk-kms -v "${AWS_SDK_KMS_VERSION}"; \
  fluent-gem install --no-document --conservative aws-sdk-s3 -v "${AWS_SDK_S3_VERSION}"; \
  fluent-gem install --no-document --conservative fluent-plugin-s3 -v "${FLUENT_PLUGIN_S3_VERSION}"; \
  fluent-gem install --no-document --conservative fluent-plugin-grafana-loki -v "${FLUENT_PLUGIN_GRAFANA_LOKI_VERSION}"; \
  fluent-gem install --no-document --conservative fluent-plugin-prometheus -v "${FLUENT_PLUGIN_PROMETHEUS_VERSION}"; \
  fluent-gem install --no-document --conservative fluent-plugin-record-modifier -v "${FLUENT_PLUGIN_RECORD_MODIFIER_VERSION}"; \
  fluent-gem cleanup json

# Garde-fou : la construction de l'image échoue si une seule dépendance n'est
# pas à la version attendue (ou si plusieurs versions cohabitent, hors
# dépendant "default" de Ruby)

RUN set -eu; \
  check() { \
    found=$(fluent-gem list --exact "$1" | sed -n "s/^$1 (\(.*\))$/\1/p" | sed 's/, default: [^,)]*//'); \
    if [ "$found" != "$2" ]; then echo "ERREUR : $1 attendu $2, trouve '$found'" >&2; exit 1; fi; \
  }; \
  check aws-partitions "${AWS_PARTITIONS_VERSION}"; \
  check aws-sigv4 "${AWS_SIGV4_VERSION}"; \
  check aws-sdk-core "${AWS_SDK_CORE_VERSION}"; \
  check aws-sdk-kms "${AWS_SDK_KMS_VERSION}"; \
  check aws-sdk-s3 "${AWS_SDK_S3_VERSION}"; \
  check fluent-plugin-s3 "${FLUENT_PLUGIN_S3_VERSION}"; \
  check fluent-plugin-grafana-loki "${FLUENT_PLUGIN_GRAFANA_LOKI_VERSION}"; \
  check fluent-plugin-prometheus "${FLUENT_PLUGIN_PROMETHEUS_VERSION}"; \
  check fluent-plugin-record-modifier "${FLUENT_PLUGIN_RECORD_MODIFIER_VERSION}"; \
  check json "${JSON_VERSION}"

COPY ./fluent.conf /fluentd/etc/fluent.conf
COPY ./conf.d /fluentd/etc/conf.d
RUN usermod -a -G adm fluent

USER fluent
VOLUME [ "/var/log/fluent" ]
EXPOSE 24231
