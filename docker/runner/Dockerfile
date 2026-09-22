FROM ubuntu:24.04

ARG TARGETARCH
ARG RUNNER_VERSION=2.319.1
ARG RUNNER_SHA256_AMD64=3f6efb7488a183e291fc2c62876e14c9ee732864173734facc85a1bfb1744464
ARG RUNNER_SHA256_ARM64=03d993c65e0c4daa5e3bf5a5a35ba356f363bdb5ceb6b5808fd52fdb813dd8e8

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates tar gnupg \
    openssh-client python3 python3-pip \
    git jq libicu74 \
  && pip3 install --break-system-packages ansible-core \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash runner

WORKDIR /actions-runner

RUN set -eu; \
  case "${TARGETARCH}" in \
    amd64) RUNNER_ARCH="x64"; RUNNER_SHA256="${RUNNER_SHA256_AMD64}" ;; \
    arm64) RUNNER_ARCH="arm64"; RUNNER_SHA256="${RUNNER_SHA256_ARM64}" ;; \
    *) echo "Architecture non geree : ${TARGETARCH}" >&2; exit 1 ;; \
  esac; \
  curl -fsSL -o runner.tar.gz \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"; \
  echo "${RUNNER_SHA256}  runner.tar.gz" | sha256sum -c -; \
  tar xzf runner.tar.gz; \
  rm runner.tar.gz; \
  ./bin/installdependencies.sh

RUN chown -R runner:runner /actions-runner

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER runner

ENTRYPOINT ["/entrypoint.sh"]
