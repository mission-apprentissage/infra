# Gestion des accès d'un produit

Donner accès à un produit revient à donner l'accès :

- Aux secrets gérés par l'**Ansible Vault** du produit. La personne aura alors un accès à tous les secrets de ce produit.
- Un accès nominatif pour se connecter en **SSH** aux different serveurs du produit. La personne aura alors la possibilité d'exécuter des commandes en tant qu'utilisateur `root` sur ces serveurs.

## Mise à jour des habilitations

Dans un premier temps, il faut mettre à jour le fichier d'habilitation du produit souhaité.

```bash
.bin/infra product:access:update <produit>
```

Un fichier s'ouvre dans l'éditeur par défaut. Il faut ensuite compléter les habilitations avec le modèle suivant :

```yaml
habilitations:

  - name: John Doe
    username: john
    email: john.doe@beta.gouv.fr
    gpg_keys:
      - 00000000000000000000000000000000DEADBEEF
    authorized_keys:
      - "https://github.com/XXXX.keys"

team_gpg_keys: "{{ habilitations | map(attribute='gpg_keys', default='') | flatten | join(',') }}"
```

Lorsque le fichier est fermé, si des changements ont été opérés, un nouveau secret principal va être généré pour l'**Ansible Vault**, puis positionné dans les variables `VAULT_PWD` et `mongodb_VAULT_PWD` de **Github**. Ce secret principal est également chiffré avec les clés publiques de chiffrement de l'ensemble des personnes déclarées dans le fichier d'habilitation, avant que le résultat ne soit déposé sur l'entrée **1Password** associée au produit.

> [!WARNING]
> À ce stage, les tâches **Github Actions**, ainsi que les tâches manuelles avec **Ansible** ne sont plus possibles. Il est nécessaire qu'une personne ayant déjà l'habilitation, réalise rapidement la rotation du secret principal **Ansible Vault** du produit, avec l'aide de la commande `.bin/mna vault:edit` depuis le dépôt du produit. Le résultat doit faire l'objet d'une transaction **Git** qui doit être poussée vers la forge **Github**.

> [!WARNING]
> À ce stade, les habilitations ne sont pas complètement appliquées, il faut pour cela, lancer la configuration de l'environnement du produit pour que l'utilisateur nominatif soit créé, et accompagé de la clé **SSH** publique associée, sur l'ensembe des serveurs du produit.
