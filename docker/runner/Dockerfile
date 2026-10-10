FROM ubuntu:24.04

ARG TARGETARCH

ARG RUNNER_VERSION=2.337.0
ARG RUNNER_SHA256_AMD64=70920811a4f8ad4328818682bca5c6469c1c942fab52448868071d0063816613
ARG RUNNER_SHA256_ARM64=9b1dc70626422526e3c94767cf024896beb15da5342a3f4819bf2feac13e0393

ARG SOPS_VERSION=3.12.2
ARG SOPS_SHA256_AMD64=14e2e1ba3bef31e74b70cf0b674f6443c80f6c5f3df15d05ffc57c34851b4998
ARG SOPS_SHA256_ARM64=f66de6f528dca946e910d74fa36a62a7714c11d0db16bd3c9bd8acf73b66704b

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates tar gnupg \
    openssh-client python3 python3-pip \
    git jq libicu74 \
  && pip3 install --break-system-packages ansible-core \
  && rm -rf /var/lib/apt/lists/*

RUN ansible-galaxy collection install \
    community.general:==12.6.0 \
    community.crypto:==3.1.1 \
    ansible.posix:==2.1.0 \
    community.sops:==2.5.0 \
    -p /usr/share/ansible/collections

RUN set -eu; \
  case "${TARGETARCH}" in \
    amd64) SOPS_SHA256="${SOPS_SHA256_AMD64}" ;; \
    arm64) SOPS_SHA256="${SOPS_SHA256_ARM64}" ;; \
    *) echo "Architecture non geree : ${TARGETARCH}" >&2; exit 1 ;; \
  esac; \
  curl -fsSL -o /usr/local/bin/sops \
    "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${TARGETARCH}"; \
  echo "${SOPS_SHA256}  /usr/local/bin/sops" | sha256sum -c -; \
  chmod 755 /usr/local/bin/sops

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
