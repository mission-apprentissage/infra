# Configuration Serveurs - INFRASTRUCTURE

Le dépot contient la configuration de base des serveurs ainsi que les images dockers personnalisées.

## Reverse Proxy

Le reverse proxy est un serveur nginx, le code se trouve dans le dossier `reverse_proxy`.

L'image est basée sur l'image officielle de nginx et ajoute:

- le module `headers-more-nginx-module`
- le waf `modsecurity`
- les fichiers de configuration de base pour:
  - le support ACME (letsencrypt)
  - l'ajout d'un mode de maintenance
  - les routes nécessaire au monitoring (nodeexporter, cadvisor, fluentd)

## Fluendt

Fluentd est un collecteur de logs, le code se trouve dans le dossier `fluentd`.

L'image est basée sur l'image officielle de fluentd et ajoute:

- le plugin `fluent-plugin-grafana-loki` pour l'envoi des logs vers loki
- le plugin `fluent-plugin-prometheus` pour l'exposition des métriques fluentd vers prometheus
- le plugin `fluent-plugin-s3` pour l'archivage des logs vers s3
- une configuration de base pour la collecte des logs:
  - des containers docker
  - du reverse proxy
  - du firewall applicatif (fail2ban)
  - du firewall OVH
  - d'accès ssh (auth.log)
  - système (syslog)

## Configuration des serveurs

La configuration des serveurs est gérée par ansible, le code se trouve dans le dossier `.infra`.

La configuration de base contient la configuration:

- des accès ssh (habilitations, password policy, sudoers)
- du firewall (fail2ban, blacklist IPs)
- du DNS
- de la rotation des logs (logrotate)
- du backup des bases de données
- de Docker (installation, configuration, mise à jour)
- du monitoring (promtail, nodeexporter, cadvisor, fluentd)
- des certificats SSL (letsencrypt)
- des containers de base (reverse proxy, fluentd, nodeexporter, cadvisor)

## Documentation

- [Ajouter un produit/environnement](./docs/provisionning.md)
- [Gestion des accès d'un produit](./docs/manage_access.md)
