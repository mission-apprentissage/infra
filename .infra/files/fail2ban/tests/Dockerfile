# Même distribution et même paquet fail2ban que les serveurs.
FROM ubuntu:24.04
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends fail2ban python3-systemd \
 && rm -rf /var/lib/apt/lists/*
