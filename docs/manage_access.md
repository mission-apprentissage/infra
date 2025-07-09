# Gestion des accès d'un produit

Donner accès à un produit revient à donner l'accès:
- aux **vault** d'un produit, la personne aura alors un accès à tous les secrets
- **root via SSH** aux different serveurs

## Création des habilitations

Chaque produit est régit par un fichier `habilitations.yml` situé dans le dossier `products/<nom_du_produit>`. Ce dernier contient la liste des utilisateurs, leur nom, leur clé GPG et la liste de leurs clés SSH : 
```yml
habilitations:
  - username: "john_doe"
    name: "John Doe"
    gpg_key: XXXXXX
    authorized_keys:
        - "ssh-rsa key1"
        - "ssh-rsa key2"
        - "ssh-ed25519 key3"

  - username: "john_doe_2"
    name: "John Doe 2"
    gpg_key: XXXXXXXX
    authorized_keys:
        - "ssh-rsa key1"
        - "ssh-rsa key2"
        - "ssh-ed25519 key3"

gpg_keys: "{{ habilitations | map(attribute='gpg_key', default='') | select() | join(',')}}"
```

Elles peuvent aussi être hébergées sur github, par exemple : `https://github.com/faxaq.keys`

```yml
habilitations:
  - username: "john_doe"
    name: "John Doe"
    gpg_key: XXXXXX
    authorized_keys:
        - "https://github.com/mission-apprentissage.keys"

gpg_keys: "{{ habilitations | map(attribute='gpg_key', default='') | select() | join(',')}}"
```

## Mise à jour des habilitations

```bash
.bin/infra product:access:update <nom_produit>
```

Un fichier vide s'ouvre dans VsCode, veuillez compléter les habilitations avec le model suivant:

```yaml
habilitations:
  - username: "john_doe"
    name: "John Doe"
    gpg_key: XXXXXX
    authorized_keys:
        - "https://github.com/mission-apprentissage.keys"

gpg_keys: "{{ habilitations | map(attribute='gpg_key', default='') | select() | join(',')}}"
```

Fermez le fichier.

> [!WARNING]
> Les habilitations sont mise à jours, et il faut les stocker dans un répertoire sécurisé. Par contre à ce stade elles ne sont pas appliquées, il faut pour cela:
> - lancer la configuration de l'environnement pour mettre à jour les accès SSH
> - ouvrir le vault du produit via `.bin/infra vault:edit` et commiter le changement du vault.
