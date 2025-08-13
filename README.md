# Configuration Serveurs - INFRASTRUCTURE

Le dépot contient la configuration de base des serveurs ainsi que les images dockers personnalisées.

## Reverse Proxy

Le reverse proxy est un serveur nginx, le code se trouve dans le dossier `reverse_proxy`.

L'image est basée sur l'image officielle de nginx et ajoute:

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


## TODO

- [ ] Automatiser la vérification des utilisateurs ayant accès au S3 `OVH_S3_BUCKET`
  - Aucun utilisateur n'est censé avoir la permission de supprimer des fichiers dans le bucket
  - Seuls les utilisateurs lié à un membre de l'équipe peuvent avoir accès en lecture (c'est à dire les comptes nominatifs).
  - L'utilisateur identifié par `OVH_S3_API_KEY` doit avoir la polique S3 suivante:
    ```
    {
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:ListBucket"
          ],
          "Resource": "arn:aws:s3:::{{ OVH_S3_BUCKET }}"
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:PutObject",
            "s3:GetObject"
          ],
          "Resource": "arn:aws:s3:::{{ OVH_S3_BUCKET }}/*"
        }
      ]
    }
    ```
- [ ] S'assurer que le bucket `OVH_S3_BUCKET` a bien l'option de chiffrement activée
- [ ] Automatiser la configuration de l'access logging est activé `aws s3api put-bucket-logging --bucket <bucket> --bucket-logging-status file://logging.json`
- [ ] Automatiser la configuration multi-région de OVH S3
- [ ] Automatiser la configuration de la lifecyle policy
