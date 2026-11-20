FROM ubuntu:24.04

ARG TARGETARCH

ARG RUNNER_VERSION=2.338.0
ARG RUNNER_SHA256_AMD64=af4b794c1bc41d73d40535e3fe092a39f9679cd8d965954c2aca25a05ca41d32
ARG RUNNER_SHA256_ARM64=628b4a7258487b80c1d3c221095a7ded349f5ae0175fd3dfab708d07428f041b

ARG SOPS_VERSION=3.13.3
ARG SOPS_SHA256_AMD64=e5bec3346a873ae91d871550f3e698c1aad962aff462a080e40f25fde17fef6b
ARG SOPS_SHA256_ARM64=53b0abacd38ef1b12a66d6c100956691b9cefce018d91f81e73ddf7438b94d77

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates tar gnupg \
    openssh-client python3 python3-pip \
    git git-lfs jq libicu74 \
  && pip3 install --break-system-packages ansible-core jmespath \
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
