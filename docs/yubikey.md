# Yubikey

> [!IMPORTANT]
> Tutoriel source de https://github.com/drduh/YubiKey-Guide
> Pour tout compléments d'informations, veullez vous référer au guider original
> La documentation qui suit est un résumé dans notre cas d'utilisation

- [Yubikey](#yubikey)
  - [Pré-requis](#pré-requis)
  - [Clef GPG](#clef-gpg)
    - [Création de la clef maitre](#création-de-la-clef-maitre)
    - [Création des sous-clefs](#création-des-sous-clefs)
    - [Backup des clefs](#backup-des-clefs)
    - [Conservation des Backups](#conservation-des-backups)
      - [Sur papier](#sur-papier)
      - [Chiffré via GPG](#chiffré-via-gpg)
    - [Configuration de la Yubikey](#configuration-de-la-yubikey)
    - [Transfer de la clef](#transfer-de-la-clef)
    - [Vérification](#vérification)
    - [Configuration de la clef additionnel](#configuration-de-la-clef-additionnel)
    - [Nettoyage](#nettoyage)
    - [Utilisation des clefs](#utilisation-des-clefs)
    - [Réinitialisation des clefs](#réinitialisation-des-clefs)
    - [Git Commits](#git-commits)
    - [Ajout dans Github](#ajout-dans-github)
  - [VPN](#vpn)
    - [Pré-requis](#pré-requis-1)
    - [Extraction des certficats](#extraction-des-certficats)
    - [Importation des certificats dans Yubikey](#importation-des-certificats-dans-yubikey)
    - [Configuration du profil OpenVPN](#configuration-du-profil-openvpn)
    - [Clef addtionnel](#clef-addtionnel)
    - [Cleanup](#cleanup)

## Pré-requis

- [GnuPG](https://www.gnupg.org/) version 2.0.2 or later.
  - Sur OSX `brew install gnupg`
  - Sur Ubuntu `sudo apt install gnupg`
- [Yubikey Manager CLI](https://developers.yubico.com/yubikey-manager/)
  - Sur OSX `brew install ykman`
  - Sur Ubuntu `snap install ykman`

## Clef GPG

Dans cette partie nous verrons comment configurer Yubikey pour stocker vos clefs GPG.

### Création de la clef maitre

La première clef a etre généré sera la clef maitre, qui sera utilisé pour certifier uniquement.

**Important:** la clef maitre doit etre conservé hors-ligne et utilisé uniquement pour générer ou révoquer les sous-clefs. 

**Important:** Veuillez utiliser une phrase-secrete robuste.

Généré une nouvelle clef GPG, en séléctionnant `(11) ECC (set your own capabilities)`, la capacité de `Certifier`  only and `4096` bit key size.


```console
$ gpg --expert --full-generate-key
gpg (GnuPG) 2.4.3; Copyright (C) 2023 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Sélectionnez le type de clef désiré :
   (1) RSA and RSA
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
   (7) DSA (set your own capabilities)
   (8) RSA (set your own capabilities)
   (9) ECC (sign and encrypt) *default*
  (10) ECC (signature seule)
  (11) ECC (set your own capabilities)
  (13) Existing key
  (14) Existing key from card
Quel est votre choix ? 11

Possible actions for this ECC key: Signer Certifier Authentifier 
Actions actuellement permises : Signer Certifier 

   (S) Inverser la capacité de signature
   (A) Inverser la capacité d'authentification
   (Q) Terminé

Quel est votre choix ? S

Possible actions for this ECC key: Signer Certifier Authentifier 
Actions actuellement permises : Certifier 

   (S) Inverser la capacité de signature
   (A) Inverser la capacité d'authentification
   (Q) Terminé

Quel est votre choix ? A

Possible actions for this ECC key: Signer Certifier Authentifier 
Actions actuellement permises : Certifier Authentifier 

   (S) Inverser la capacité de signature
   (A) Inverser la capacité d'authentification
   (Q) Terminé

Quel est votre choix ? A

Possible actions for this ECC key: Signer Certifier Authentifier 
Actions actuellement permises : Certifier 

   (S) Inverser la capacité de signature
   (A) Inverser la capacité d'authentification
   (Q) Terminé

Quel est votre choix ? Q
Sélectionnez le type de courbe elliptique désiré :
   (1) Curve 25519 *default*
   (2) Curve 448
   (3) NIST P-256
   (4) NIST P-384
   (5) NIST P-521
   (6) Brainpool P-256
   (7) Brainpool P-384
   (8) Brainpool P-512
   (9) secp256k1
Quel est votre choix ? 1
Veuillez indiquer le temps pendant lequel cette clef devrait être valable.
         0 = la clef n'expire pas
      <n>  = la clef expire dans n jours
      <n>w = la clef expire dans n semaines
      <n>m = la clef expire dans n mois
      <n>y = la clef expire dans n ans
Pendant combien de temps la clef est-elle valable ? (0) 0
La clef n'expire pas du tout
Est-ce correct ? (o/N) o

GnuPG doit construire une identité pour identifier la clef.

Nom réel : Moroine Bentefrit
Adresse électronique : moroine.bentefrit@beta.gouv.fr
Commentaire : 
Vous avez sélectionné cette identité :
    « Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr> »

Changer le (N)om, le (C)ommentaire, l'(A)dresse électronique
ou (O)ui/(Q)uitter ? O
De nombreux octets aléatoires doivent être générés. Vous devriez faire
autre chose (taper au clavier, déplacer la souris, utiliser les disques)
pendant la génération de nombres premiers ; cela donne au générateur de
nombres aléatoires une meilleure chance d'obtenir suffisamment d'entropie.
gpg: revocation certificate stored as '/Users/moroine/.gnupg/openpgp-revocs.d/9430B570051988403A178AB850F902F567461135.rev'
les clefs publique et secrète ont été créées et signées.

pub   ed25519 2024-01-30 [C]
      9430B570051988403A178AB850F902F567461135
uid                      Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>
```

Exportez l'identifiant de la clef dans une variable pour une utilisation ultérieure

```console
$ export KEYID=9430B570051988403A178AB850F902F567461135
```

### Création des sous-clefs

Éditez la clef maitre pour ajouter les sous-clefs:
    - signature
    - encryption
    - authentification

```console
$ gpg --expert --edit-key $KEYID                       
gpg (GnuPG) 2.4.3; Copyright (C) 2023 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

La clef secrète est disponible.

gpg: vérification de la base de confiance
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: profondeur : 0  valables :   1  signées :   0
     confiance : 0 i., 0 n.d., 0 j., 0 m., 0 t., 1 u.
sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

gpg> addkey
Sélectionnez le type de clef désiré :
   (3) DSA (sign only)
   (4) RSA (sign only)
   (5) Elgamal (encrypt only)
   (6) RSA (encrypt only)
   (7) DSA (set your own capabilities)
   (8) RSA (set your own capabilities)
  (10) ECC (signature seule)
  (11) ECC (set your own capabilities)
  (12) ECC (encrypt only)
  (13) Existing key
  (14) Existing key from card
Quel est votre choix ? 10
Sélectionnez le type de courbe elliptique désiré :
   (1) Curve 25519 *default*
   (2) Curve 448
   (3) NIST P-256
   (4) NIST P-384
   (5) NIST P-521
   (6) Brainpool P-256
   (7) Brainpool P-384
   (8) Brainpool P-512
   (9) secp256k1
Quel est votre choix ? 1
Veuillez indiquer le temps pendant lequel cette clef devrait être valable.
         0 = la clef n'expire pas
      <n>  = la clef expire dans n jours
      <n>w = la clef expire dans n semaines
      <n>m = la clef expire dans n mois
      <n>y = la clef expire dans n ans
Pendant combien de temps la clef est-elle valable ? (0) 0
La clef n'expire pas du tout
Est-ce correct ? (o/N) o
Faut-il vraiment la créer ? (o/N) o
De nombreux octets aléatoires doivent être générés. Vous devriez faire
autre chose (taper au clavier, déplacer la souris, utiliser les disques)
pendant la génération de nombres premiers ; cela donne au générateur de
nombres aléatoires une meilleure chance d'obtenir suffisamment d'entropie.

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

gpg> addkey
Sélectionnez le type de clef désiré :
   (3) DSA (sign only)
   (4) RSA (sign only)
   (5) Elgamal (encrypt only)
   (6) RSA (encrypt only)
   (7) DSA (set your own capabilities)
   (8) RSA (set your own capabilities)
  (10) ECC (signature seule)
  (11) ECC (set your own capabilities)
  (12) ECC (encrypt only)
  (13) Existing key
  (14) Existing key from card
Quel est votre choix ? 12
Sélectionnez le type de courbe elliptique désiré :
   (1) Curve 25519 *default*
   (2) Curve 448
   (3) NIST P-256
   (4) NIST P-384
   (5) NIST P-521
   (6) Brainpool P-256
   (7) Brainpool P-384
   (8) Brainpool P-512
   (9) secp256k1
Quel est votre choix ? 1
Veuillez indiquer le temps pendant lequel cette clef devrait être valable.
         0 = la clef n'expire pas
      <n>  = la clef expire dans n jours
      <n>w = la clef expire dans n semaines
      <n>m = la clef expire dans n mois
      <n>y = la clef expire dans n ans
Pendant combien de temps la clef est-elle valable ? (0) 0
La clef n'expire pas du tout
Est-ce correct ? (o/N) o
Faut-il vraiment la créer ? (o/N) o
De nombreux octets aléatoires doivent être générés. Vous devriez faire
autre chose (taper au clavier, déplacer la souris, utiliser les disques)
pendant la génération de nombres premiers ; cela donne au générateur de
nombres aléatoires une meilleure chance d'obtenir suffisamment d'entropie.

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

gpg> addkey
Sélectionnez le type de clef désiré :
   (3) DSA (sign only)
   (4) RSA (sign only)
   (5) Elgamal (encrypt only)
   (6) RSA (encrypt only)
   (7) DSA (set your own capabilities)
   (8) RSA (set your own capabilities)
  (10) ECC (signature seule)
  (11) ECC (set your own capabilities)
  (12) ECC (encrypt only)
  (13) Existing key
  (14) Existing key from card
Quel est votre choix ? 11

Possible actions for this ECC key: Signer Authentifier 
Actions actuellement permises : Signer 

   (S) Inverser la capacité de signature
   (A) Inverser la capacité d'authentification
   (Q) Terminé

Quel est votre choix ? s

Alan ? certaines de ces opérations semblent faire puis défaire puis refaire la même conf.

Possible actions for this ECC key: Signer Authentifier 
Actions actuellement permises : 

   (S) Inverser la capacité de signature
   (A) Inverser la capacité d'authentification
   (Q) Terminé

Quel est votre choix ? S

Possible actions for this ECC key: Signer Authentifier 
Actions actuellement permises : Signer 

   (S) Inverser la capacité de signature
   (A) Inverser la capacité d'authentification
   (Q) Terminé

Quel est votre choix ? S

Possible actions for this ECC key: Signer Authentifier 
Actions actuellement permises : 

   (S) Inverser la capacité de signature
   (A) Inverser la capacité d'authentification
   (Q) Terminé

Quel est votre choix ? A

Possible actions for this ECC key: Signer Authentifier 
Actions actuellement permises : Authentifier 

   (S) Inverser la capacité de signature
   (A) Inverser la capacité d'authentification
   (Q) Terminé

Quel est votre choix ? Q
Sélectionnez le type de courbe elliptique désiré :
   (1) Curve 25519 *default*
   (2) Curve 448
   (3) NIST P-256
   (4) NIST P-384
   (5) NIST P-521
   (6) Brainpool P-256
   (7) Brainpool P-384
   (8) Brainpool P-512
   (9) secp256k1
Quel est votre choix ? 1
Veuillez indiquer le temps pendant lequel cette clef devrait être valable.
         0 = la clef n'expire pas
      <n>  = la clef expire dans n jours
      <n>w = la clef expire dans n semaines
      <n>m = la clef expire dans n mois
      <n>y = la clef expire dans n ans
Pendant combien de temps la clef est-elle valable ? (0) 0
La clef n'expire pas du tout
Est-ce correct ? (o/N) o
Faut-il vraiment la créer ? (o/N) o
De nombreux octets aléatoires doivent être générés. Vous devriez faire
autre chose (taper au clavier, déplacer la souris, utiliser les disques)
pendant la génération de nombres premiers ; cela donne au générateur de
nombres aléatoires une meilleure chance d'obtenir suffisamment d'entropie.

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

gpg> save
```

Vous pouvez vérifier que les sous-clefs sont bien créés avec les bonnes capacités:

```console
$ gpg --list-keys
[keyboxd]
---------
pub   ed25519 2024-01-30 [C]
      9430B570051988403A178AB850F902F567461135
uid          [  ultime ] Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>
sub   ed25519 2024-01-30 [S]
sub   cv25519 2024-01-30 [E]
sub   ed25519 2024-01-30 [A]
```

### Backup des clefs

```console
$ gpg --armor --export-secret-keys $KEYID > secret-key.asc
$ gpg --armor --export $KEYID > public.crt
$ gpg --keyserver hkps://keyserver.ubuntu.com:443 --send-key $KEYID
```

Meme si nous allons exporter et stoquer la clef maitre en lieu sure, c'est une bonne pratique de toujours envisager la possibilité de la perdre ou d'avoir un problème de backup. Nous allons donc généré un certificat de révocation, pour etre capable de révoquer nos certificats le cas échéant.

```console
$ gpg --output revoke.asc --gen-revoke $KEYID
```

> [!CAUTION]
> Une fois que les clés sont déplacés sur la Yubikey, elles ne peuvent plus etre récupérées.

> [!CAUTION]
> Conservez ces exports dans un endroit sécurisé.

### Conservation des Backups

Le fichier `secret-key.asc` est sensible, car ils représentent une copie sécurisée uniquement par votre phrase secrete. Pour archiver ces fichiers vous avez plusieurs possibilitées:
- Sur une clef USB chiffrée: https://github.com/drduh/YubiKey-Guide?tab=readme-ov-file#backup
- Sur papier: https://wiki.archlinux.org/title/Paperkey
- Chiffré via votre clef GPG et stocké dans 1password (n'oubliez pas d'activer le 2FA sur votre compte 1password).

#### Sur papier

Pré-requis:
- [Paperkey](https://wiki.archlinux.org/title/Paperkey)
  - OSX: `brew install paperkey`
- [QrEncode](https://fukuchi.org/works/qrencode/index.html.en)
  - OSX: `brew install qrencode`
- [Zbar](https://zbar.sourceforge.net/)
  - OSX: `brew install zbar`

```console
$ gpg --export-secret-key $KEYID | paperkey --output-type raw | qrencode --8bit --output secret-key.qr.png
```

Supprimer votre clef et tentez de la ré-importer:

```console
$  gpg --delete-secret-keys $KEYID
gpg (GnuPG) 2.4.3; Copyright (C) 2023 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.


sec  ed25519/50F902F567461135 2024-01-30 Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

Faut-il supprimer cette clef du porte-clefs ? (o/N) o
C'est une clef secrète — faut-il vraiment la supprimer ? (o/N) o
$ gpg -K
$ zbarimg -1 --raw -q -Sbinary secret-key.qr.png | paperkey --pubring public.crt.gpg | gpg --import
gpg: clef 50F902F567461135 : « Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr> » n'est pas modifiée
gpg: To migrate 'secring.gpg', with each smartcard, run: gpg --card-status
gpg: clef 50F902F567461135 : clef secrète importée
gpg:       Quantité totale traitée : 1
gpg:                 non modifiées : 1
gpg:           clefs secrètes lues : 1
gpg:      clefs secrètes importées : 1
$ gpg -K
[keyboxd]
---------
sec   ed25519 2024-01-30 [C]
      9430B570051988403A178AB850F902F567461135
uid          [  ultime ] Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>
ssb#  ed25519 2024-01-30 [A]
ssb#  cv25519 2024-01-30 [E]
ssb#  ed25519 2024-01-30 [S]
```

> [!IMPORTANT]
> - Imprimez votre QR Code
> - Conservez votre phrase secrete sur 1password
> - Conservez le fichier `public.crt` sur 1password
> - Conservez le fichier `revoke.asc` sur 1password

#### Chiffré via GPG

```console
$ gpg --encrypt --armor --recipient $KEYID -o secret-key.asc.encrypted secret-key.asc
```

> [!IMPORTANT]
> - Conservez le fichier `secret-key.asc.encrypted` 
> - Conservez votre phrase secrete sur 1password
> - Conservez le fichier `public.crt` sur 1password
> - Conservez le fichier `revoke.asc` sur 1password

> [!WARNING]
> Cette méthode nécéssitera d'avoir accès à une de vos Yubikey.

### Configuration de la Yubikey

Connecter votre Yubikey à l'ordinateur et commencer la configuration

```console
$ gpg --card-edit

Reader ...........: Yubico YubiKey OTP FIDO CCID
Application ID ...: D2760001240100000006254870570000
Application type .: OpenPGP
Version ..........: 3.4
Manufacturer .....: Yubico
Serial number ....: 25487057
Name of cardholder: [non positionné]
Language prefs ...: [non positionné]
Salutation .......: 
URL of public key : [non positionné]
Login data .......: [non positionné]
Signature PIN ....: non forcé
Key attributes ...: rsa2048 rsa2048 rsa2048
Max. PIN lengths .: 127 127 127
PIN retry counter : 3 0 3
Signature counter : 0
KDF setting ......: off
UIF setting ......: Sign=off Decrypt=off Auth=off
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]
General key info..: [none]
```

Activer le mode administrateur:

```console
gpg/carte> admin
Les commandes d'administration sont permises
```

**IMPORTANT:** Changement des PINS

> 3 mauvais PIN successifs, bloquent la clef qui peut etre débloquée via le PIN Admin
> 3 mauvais PIN Admin ou Reset successifs détruisent toutes les données GPG sur la clef

Name       | Default Value | Use
-----------|---------------|-------------------------------------------------------------
PIN        | `123456`      | decrypt and authenticate (SSH)
Admin PIN  | `12345678`    | reset *PIN*, change *Reset Code*, add keys and owner information
Reset code | _**None**_    | reset *PIN* ([more information](https://forum.yubico.com/viewtopicd01c.html?p=9055#p9055))

> [!TIP]
> Pour les PINS vous pouvez utiliser n'importe quel charactere.

```console
gpg/carte> passwd
gpg: carte OpenPGP nº D2760001240100000006254870570000 détectée

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Quel est votre choix ? 3
PIN changed.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Quel est votre choix ? 1
PIN changed.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Quel est votre choix ? q

gpg/carte> quit
```

Activer KDF:

Alan ? l'activation de cette commande après le changement de PIN semble avoir invalidé lesdits changements.

```console
$ gpg --card-edit

gpg/carte> kdf-setup

gpg/carte> quit
```

Mise à jour des informations:

```console
$ gpg --card-edit

gpg/carte> name
Nom du détenteur de la carte : Bentefrit
Prénom du détenteur de la carte : Moroine

gpg/carte> lang
Préférences de langue : fr

gpg/carte> login
Données d'identification (nom du compte) : moroine

gpg/carte> sex
Salutation (M = Mr., F = Ms., or space): M

gpg/carte> url
URL pour récupérer la clef publique : https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xVOTRE_$_KEYID
gpg/carte> quit
```

> [!NOTE]
> L'url dépend de votre id de clef publique

Mettez à jour la configuration du touch:

> [!IMPORTANT]
> Ubuntu : La connection ykman à la yubikey peut nécessiter de jouer les deux instructions suivantes :
> sudo wget -O /etc/udev/rules.d/70-yubikey.rules https://raw.githubusercontent.com/Yubico/libu2f-host/master/70-u2f.rules
> sudo udevadm control --reload-rules
> débrancher rebrancher la yubikey

```console
$ ykman openpgp keys set-touch aut cached
Enter Admin PIN: 
Set touch policy of AUT key to cached? [y/N]: y
$ ykman openpgp keys set-touch sig cached
Enter Admin PIN: 
Set touch policy of SIG key to cached? [y/N]: y
$ ykman openpgp keys set-touch dec cached
Enter Admin PIN: 
Set touch policy of DEC key to cached? [y/N]: y
```

### Transfer de la clef

> [!CAUTION]
> L'utilisation de `keytocard` est destructive, impossible de récuépérer les clefs ensuite. Assurez-vous dávoir le backup qui sera utile pour configurer les clefs additionnels.

```console
gpg --edit-key $KEYID
gpg (GnuPG) 2.4.3; Copyright (C) 2023 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

La clef secrète est disponible.

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>
```

> La clef selectionnée est identifiée par le charactere `*` (par exemple `ssb*` dans le code suivant).

Clef de signature: 

```console
gpg> key 1

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb* ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

gpg> keytocard
Veuillez sélectionner l'endroit où stocker la clef :
   (1) Clef de signature
   (3) Clef d'authentification
Quel est votre choix ? 1

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb* ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

Note: the local copy of the secret key will only be deleted with "save".
```

Clef d'enryption (taper `key 1` pour déséléctionner et `key 2` pour séléctionner la clef suivante).

```console
gpg> key 1

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

gpg> key 2

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
ssb* cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

gpg> keytocard
Veuillez sélectionner l'endroit où stocker la clef :
   (2) Clef de chiffrement
Quel est votre choix ? 2

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
ssb* cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

Note: the local copy of the secret key will only be deleted with "save".
```

Clef d'authentification (taper `key 2` pour déséléctionner et `key 3` pour séléctionner la clef suivante).

```console
gpg> key 2

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

gpg> key 3

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
ssb* ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

gpg> keytocard
Veuillez sélectionner l'endroit où stocker la clef :
   (3) Clef d'authentification
Quel est votre choix ? 3

sec  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
ssb* ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

Note: the local copy of the secret key will only be deleted with "save".
```

Sauvegarder et quitter:

```console
gpg> save
```

### Vérification

Vérifier que les sub-keys ont étés déplacés sur la Yubikey, indiqué par `ssb>`

```console
$ gpg -K
[keyboxd]
---------
sec   ed25519 2024-01-30 [C]
      9430B570051988403A178AB850F902F567461135
uid          [  ultime ] Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>
ssb>  ed25519 2024-01-30 [S]
ssb>  cv25519 2024-01-30 [E]
ssb>  ed25519 2024-01-30 [A]
```

Chiffrer un message via:

```console
$ echo "test message string" | gpg --encrypt --armor --recipient $KEYID -o encrypted.txt
```

Dechiffrer le:

```console
$ gpg --decrypt --armor encrypted.txt
gpg: anonymous recipient; trying secret key 0x0000000000000000 ...
gpg: okay, we are the anonymous recipient.
gpg: encrypted with RSA key, ID 0x0000000000000000
test message string
```

### Configuration de la clef additionnel

> [!CAUTION]
> Assurez-vous d'avoir bien les fichiers `secret-key.asc` & `private_subkeys.key`

Supprimer les clef secrets enregistrés dans votre agent GPG

```console
$ gpg --delete-secret-keys $KEYID
```

> [!IMPORTANT]
> Vous ne supprimez pas les clefs sur votre Yubikey, mais simplement la reference dans votre agent.

Ré-importez votre certificat master

```console
$ gpg --import secret-key.asc
$ gpg --edit-key $KEYID
gpg> trust
pub  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : inconnu       validité : inconnu
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
     nº de carte : 0006 25487150
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
     nº de carte : 0006 25487150
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
     nº de carte : 0006 25487150
[ inconnue] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

Décidez maintenant de la confiance que vous portez en cet utilisateur pour
vérifier les clefs des autres utilisateurs (en regardant les passeports, en
vérifiant les empreintes depuis diverses sources, etc.)

  1 = je ne sais pas ou n'ai pas d'avis
  2 = je ne fais PAS confiance
  3 = je fais très légèrement confiance
  4 = je fais entièrement confiance
  5 = j'attribue une confiance ultime
  m = retour au menu principal

Quelle est votre décision ? 5
Voulez-vous vraiment attribuer une confiance ultime à cette clef ? (o/N) o

pub  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : inconnu
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
     nº de carte : 0006 25487150
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
     nº de carte : 0006 25487150
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
     nº de carte : 0006 25487150
[ inconnue] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>
Veuillez remarquer que la validité affichée pour la clef n'est pas
forcément correcte avant d'avoir relancé le programme.

gpg> quit
```

Répéter les étapes:
- [Configuration de la Yubikey](#configuration-de-la-yubikey)
- [Transfer de la clef](#transfer-de-la-clef)
- [Vérification](#vérification)

Une fois configuré, re-connecter la clef précédente

```console
$  gpg-connect-agent "scd serialno" "learn --force" /bye
```

### Nettoyage

> [!CAUTION]
> Veuillez vous assurer que:
>   - Les sous-clef de signature, de chiffrement et d'authentification sont sur la Yubikey (`gpg -K` doit afficher `ssb>`)
>   - Le PIN et Admin PIN des Yubikey ont été changé
>   - La phrase secrete de la clef maitre est conservée sur 1password
>   - Le certificat publique est conservé sur 1password (et keyserver.ubuntu.com)
>   - La clef secrete est conservée dans un endroit sécurisé

```console
$ gpg --delete-secret-key $KEYID
$ sudo rm secret-key.* revoke.asc
```

### Utilisation des clefs

1. Connectez votre Yubikey
2. Utilisez la commande `fetch` pour récupérer la clef public de la carte
```console
$ gpg --edit-card

gpg/card> fetch
gReader ...........: Yubico YubiKey OTP FIDO CCID
Application ID ...: D2760001240100000006254870570000
Application type .: OpenPGP
Version ..........: 3.4
Manufacturer .....: Yubico
Serial number ....: 25487057
Name of cardholder: Moroine Bentefrit
Language prefs ...: fr
Salutation .......: Mr.
URL of public key : https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x9430b570051988403a178ab850f902f567461135
Login data .......: moroine
Signature PIN ....: non forcé
Key attributes ...: ed25519 cv25519 ed25519
Max. PIN lengths .: 127 127 127
PIN retry counter : 3 0 3
Signature counter : 0
KDF setting ......: on
UIF setting ......: Sign=off Decrypt=off Auth=off
Signature key ....: 2A49 81D6 FB88 7198 05B7  64DE B309 9E19 8CD0 932A
      created ....: 2024-01-30 20:32:16
Encryption key....: 8FE4 08C8 085D 4E8E A2AC  8B8A A35C AEB0 8D47 5485
      created ....: 2024-01-30 20:32:52
Authentication key: AF35 C111 C16A EE8F 7BBF  3CB9 852D F0FB 24EE FDE0
      created ....: 2024-01-30 20:34:55
General key info..: 
sub  ed25519/B3099E198CD0932A 2024-01-30 Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>
sec#  ed25519/50F902F567461135  créé : 2024-01-30  expire : jamais    
ssb>  ed25519/852DF0FB24EEFDE0  créé : 2024-01-30  expire : jamais    
                                nº de carte : 0006 25487057
ssb>  cv25519/A35CAEB08D475485  créé : 2024-01-30  expire : jamais    
                                nº de carte : 0006 25487057
ssb>  ed25519/B3099E198CD0932A  créé : 2024-01-30  expire : jamais    
                                nº de carte : 0006 25487057

gpg/carte> fetch
gpg: requête de la clef sur « https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x9430b570051988403a178ab850f902f567461135 »
gpg: clef 50F902F567461135 : « Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr> » n'est pas modifiée
gpg:       Quantité totale traitée : 1
gpg:                 non modifiées : 1

gpg/carte> quit
```

3. Définissez la variable KEYID (présente dans le resultat de la commande précédente)
```console
$ export KEYID=0xFF3E7D88647EBCDB
```

4. Attribuez une valeur de confiance à la clef
```console
 gpg --edit-key $KEYID
gpg (GnuPG) 2.4.3; Copyright (C) 2023 g10 Code GmbH
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Secret subkeys are available.

pub  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
     nº de carte : 0006 25487057
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
     nº de carte : 0006 25487057
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
     nº de carte : 0006 25487057
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

gpg> trust
pub  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
     nº de carte : 0006 25487057
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
     nº de carte : 0006 25487057
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
     nº de carte : 0006 25487057
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

Décidez maintenant de la confiance que vous portez en cet utilisateur pour
vérifier les clefs des autres utilisateurs (en regardant les passeports, en
vérifiant les empreintes depuis diverses sources, etc.)

  1 = je ne sais pas ou n'ai pas d'avis
  2 = je ne fais PAS confiance
  3 = je fais très légèrement confiance
  4 = je fais entièrement confiance
  5 = j'attribue une confiance ultime
  m = retour au menu principal

Quelle est votre décision ? 5
Voulez-vous vraiment attribuer une confiance ultime à cette clef ? (o/N) o

pub  ed25519/50F902F567461135
     créé : 2024-01-30  expire : jamais      utilisation : C   
     confiance : ultime        validité : ultime
ssb  ed25519/852DF0FB24EEFDE0
     créé : 2024-01-30  expire : jamais      utilisation : A   
     nº de carte : 0006 25487057
ssb  cv25519/A35CAEB08D475485
     créé : 2024-01-30  expire : jamais      utilisation : E   
     nº de carte : 0006 25487057
ssb  ed25519/B3099E198CD0932A
     créé : 2024-01-30  expire : jamais      utilisation : S   
     nº de carte : 0006 25487057
[  ultime ] (1). Moroine Bentefrit <moroine.bentefrit@beta.gouv.fr>

gpg> quit
```

### Réinitialisation des clefs

> [!WARNING]
> En cas de soucis, vous pouvez toujours réinitialiser les clefs

```console
$ ykman openpgp reset
```

### Git Commits

Activer la signature de tous vos commits

```console
$ git config --global user.signingkey $KEYID
$ git config --global commit.gpgsign true
```

### Ajout dans Github

Récupérer votre certificat publique `gpg --armor --export 9430B570051988403A178AB850F902F567461135`

Ajouter votre certificat publique sur [Github](https://github.com/settings/keys),=

## VPN

### Pré-requis

- Disposer du fichier de configuration VPN https://github.com/mission-apprentissage/vpn
- Avoir déchiffré le fichier de configuration
- [Yubikey Manager](https://www.yubico.com/support/download/yubikey-manager/)

### Extraction des certficats

Ouvrer le fichier de configuration, et créer deux fichiers:
- `openvpn-key.crt`: issue du contenu de la baslise `<key>` du fichier de configuration.
- `openvpn-cert.crt`: issue du contenu de la balise `<cert>`, uniquement le entre les balises `-----BEGIN CERTIFICATE-----` & `-----END CERTIFICATE-----` (copier les balises également).

Supprimer le contenu des balises `<key>` et `<cert>`

> [!CAUTION]
> Bien que la key ne soit plus dans le fichier de profil, celui-ci reste sensible étant donné qu'il reste la balise `tls-crypt-v2` qui pourrait etre utilisé pour DDOS le VPN.

### Importation des certificats dans Yubikey

- Modifier les codes PIN, PUK et Management key par défaut (Yubikey Manager > Applications > PIV > Configure Certificates > PIN Management)
- Ouvrer Yubikey Manager > Applications > PIV > Configure Certificates > Authentification
- Importer d'abord le certificat `openvpn-cert.crt` puis la clef `openvpn-key.crt`

### Configuration du profil OpenVPN

Effectuer l'étape [Locate and copy vendor module](https://openvpn.net/vpn-server-resources/support-of-pkcs11-physical-tokens-for-openvpn-connect/) pour permettre à OpenVPN Connect de détecter la Yubikey.

> [!WARNING]
> Si OpenVPN Connect est ouvert, il sera nécessaire de le redemarrer pour détecter la Yubikey.

Importer le fichier de configuration du VPN (sans les balises `<key>` et `<cert>`).

Dans le formulaire de création de profile, OpenVPN Connect va vous proposer d'assigner le certificat et la clef du profile.

- Choisir Assigner > Hardware Tokens > Authorize
- Selectionner le certificat (votre nom d'utilisateur VPN) et la clef "Private key for PIV Authentication"
- Confirmer

### Clef addtionnel

Réperter les memes opérations avec un nouveau profil OpenVPN.

### Cleanup

Supprimer les fichiers de profils, `openvpn-cert.crt` & `openvpn-key.crt`
