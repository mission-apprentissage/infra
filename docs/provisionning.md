# Provisionnement d'un VPS

- [Provisionnement d'un VPS](#provisionnement-dun-vps)
  - [Prérequis](#prérequis)
  - [Création d'un produit (optionnel)](#création-dun-produit-optionnel)
    - [Création du env.ini](#création-du-envini)
    - [Création du vault password \& habilitations](#création-du-vault-password--habilitations)
    - [Création du Slack Webhook](#création-du-slack-webhook)
  - [Déclaration de l'environnement](#déclaration-de-lenvironnement)
  - [Création du nom de domaine](#création-du-nom-de-domaine)
  - [Configuration de l'environnement](#configuration-de-lenvironnement)

## Prérequis

Voir [Prérequis](./pre-requisites.md)

**Important:** Cette section décris comment installer l'infrastructure sur un nouvel environnement. Pour la mise à jour de celui-ci, veuillez vous référer à la section [Mise à jour de la configuration](#mise-à-jour-de-la-configuration).

## Création d'un produit (optionnel)

Si vous voulez simplement ajouter un nouvel environnement à un produit existant vous pouvez ignorer cette étape

### Création du env.ini

```bash
.bin/mna product:create <nom_produit>
```

Ouvrir le fichier `/products/<nom_produit>/env.ini` et mettre à jour les variables `product_name` & `repo`

### Création du vault password & habilitations

Création des habilitations initiales
```bash 
.bin/mna product:access:update <nom_produit>
```

Un fichier vide s'ouvre dans VsCode, veuillez compléter les habilitations avec le model suivant:

```yaml
habilitations:
  - username: 
    name: 
    gpg_key: 
    authorized_keys:
      - "https://github.com/mission-apprentissage.keys"

gpg_keys: "{{ habilitations  | map(attribute='gpg_key', default='') | select() | join(',')}}"
```

Fermez le fichier

### Création du Slack Webhook

Créez les variables d'environnement

```bash
.bin/mna vault:edit
```

## Déclaration de l'environnement

Le fichier `/products/<nom_produit>/env.ini` définit les environnements de l'application. Il faut donc ajouter le nouvel environnement
dans ce fichier en renseignant les informations suivantes :

```ini
[<nom_environnement>]
<IP>
[<nom de l'environnement>:vars]
dns_name=<nom_produit>-<nom_environnement>.apprentissage.beta.gouv.fr
host_name=<nom_produit>-<nom_environnement>
env_type=recette
```

Pour information, vous pouvez obtenir l'adresse ip du vps en consultant les emails de
service : https://www.ovh.com/manager/dedicated/#/useraccount/emails

Editer le vault pour créer les env-vars liés à ce nouvel environnement (cf: [Edition du vault](#edition-du-vault))

## Création du nom de domaine

Créer un domain name pour le nouvel environment https://admin.alwaysdata.com/record/?domain=69636 `<nom_produit>-<nom_environnement>.apprentissage.beta.gouv.fr` et pour la prod `<nom_produit>.apprentissage.beta.gouv.fr`

## Configuration de l'environnement

Pour configurer l'environnement, il faut lancer la commande suivante :

```bash
.bin/mna ssh:known_hosts:update <nom_produit>
.bin/mna system:setup:initial <nom_produit> <nom_environnement>
.bin/mna ssh:config <nom_produit>
```

L'utilisateur `ubuntu` est un utilisateur créé par défaut par OVH, le mot de passe de ce compte est envoyé par email à
l'administrateur du compte OVH et est également disponible dans les emails de
service : https://www.ovh.com/manager/dedicated/#/useraccount/emails

Pour finaliser le création de l'environnement, vous devez vous connecter pour initialiser votre utilisateur :

```bash
ssh <nom_produit>-<nom_environnement>
```

Enfin pour des questions de sécurité, vous devez supprimer l'utilisateur `ubuntu` :

```bash
.bin/mna system:user:remove <nom_produit> <nom_environnement> ubuntu --user <votre_nom_utilisateur>
```
