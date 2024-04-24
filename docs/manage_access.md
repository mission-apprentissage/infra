# Gestion des accès d'un produit

Donner accès à un produit revient à donner l'accès:
- aux **vault** d'un produit, la personne aura alors un accès à tous les secrets
- **root via SSH** aux different serveurs

## Mise à jour des habilitations

```bash
.bin/mna product:access:update <nom_produit>
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
> Les habilitations sont mise à jours, et stockées dans 1password. Par contre à ce stade elles ne sont pas appliquées, il faut pour cela:
> - lancer la configuration de l'environnement pour mettre à jour les accès SSH
> - ouvrir le vault du produit via `.bin/mna vault:edit` et commiter le changement du vault.
