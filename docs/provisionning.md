# Provisionnement d'un VPS

- [Provisionnement d'un VPS](#provisionnement-dun-vps)
  - [Prérequis](#prérequis)
  - [Création d'une app OVH](#création-dune-app-ovh)
  - [Déclaration de l'environnement](#déclaration-de-lenvironnement)
  - [Création du VPS OVH](#création-du-vps-ovh)
  - [Création du nom de domaine](#création-du-nom-de-domaine)
  - [Configuration de l'environnement](#configuration-de-lenvironnement)

## Prérequis

Voir [Prérequis](./pre-requisites.md)

**Important:** Cette section décris comment installer l'infrastructure sur un nouvel environnement. Pour la mise à jour de celui-ci, veuillez vous référer à la section [Mise à jour de la configuration](#mise-à-jour-de-la-configuration).

## Création d'une app OVH

OVH Europe https://eu.api.ovh.com/createApp/

Conserver les informmations suivantes :

- Application Key
- Application Secret

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

## Création du VPS OVH

La première étape est de créer un VPS via l'interface d'OVH : https://www.ovhcloud.com/fr/vps/

Une fois le VPS créé, il est nécessaire de configurer le firewall en lançant la commande :

```bash
mna-infra firewall:setup <nom_produit> <nom_environnement> <app_key> <app_secret>
```

Lors de l'exécution de ce script, vous serez redirigé vers une page web vous demandant de vous authentifier afin de
générer un jeton d'api. Vous devez donc avoir un compte OVH ayant le droit de gérer les instances de la Mission
Apprentissage. Une fois authentifié, le script utilisera automatiquement ce jeton.

Quand le script est terminé, vous pouvez aller sur l'interface
OVH [https://www.ovh.com/manager/#/dedicated/ip](https://www.ovh.com/manager/#/dedicated/ip)
afin de vérifier que le firewall a été activé pour l'ip du VPS.

## Création du nom de domaine

Créer un domain name pour le nouvel environment https://admin.alwaysdata.com/record/?domain=69636 `<nom_produit>-<nom_environnement>.apprentissage.beta.gouv.fr` et pour la prod `<nom_produit>.apprentissage.beta.gouv.fr`

## Configuration de l'environnement

Pour configurer l'environnement, il faut lancer la commande suivante :

```bash
ssh-keygen -R <ip>
ssh-keyscan <ip> >> ~/.ssh/known_hosts
mna-infra system:setup:initial <nom_produit> <nom_environnement>
```

L'utilisateur `ubuntu` est un utilisateur créé par défaut par OVH, le mot de passe de ce compte est envoyé par email à
l'administrateur du compte OVH et est également disponible dans les emails de
service : https://www.ovh.com/manager/dedicated/#/useraccount/emails

Une fois le script terminé, l'application est disponible à l'url qui correspond au `dns_name` dans le fichier `env.ini`

Pour finaliser le création de l'environnement, vous devez vous connecter pour initialiser votre utilisateur :

```bash
ssh <nom_utilisateur>@<ip>
```

Enfin pour des questions de sécurité, vous devez supprimer l'utilisateur `ubuntu` :

```bash
mna-bal system:user:remove --user <votre_nom_utilisateur> --extra-vars "username=ubuntu"
```

Vous pouvez maintenant poursuivre avec le [Deploiement de l'application](#deploiement-de-lapplication).
