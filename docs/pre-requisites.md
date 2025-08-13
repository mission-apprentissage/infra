# Prérequis

## Environnement local

Contient l'ensemble des données sensibles nécessaires à la mise en place de
l'application.

## Ansible

Installez [Ansible 2.07+](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

> Sur **macOS** vous pouvez utiliser `brew install ansible`

---

> Sur Ubuntu / WSL vous pouvez l'installer en 2 temps via :

> 1. L'ajout du dépôt Ansible officiel

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
```

> 2. L'installer avec la commande

```bash
sudo apt install -y ansible
```

## 1Password CLI

[Suivre la documentation dédié](./1password.md)

## Yq

[Installez yq](https://github.com/mikefarah/yq)

> Sur **macOS** vous pouvez utiliser `brew install yq`

> Sur Ubuntu / WSL vous pouvez utiliser `sudo snap install yq`

## sshpass

[Installez sshpass](https://www.linuxtricks.fr/wiki/ssh-sshpass-la-connexion-ssh-par-mot-de-passe-non-interactive)

> Sur **macOS** vous pouvez utiliser

```bash
brew tap esolitos/ipa
brew install esolitos/ipa/sshpass
```

> Sur Ubuntu / WSL vous pouvez utiliser :

```bash
sudo apt install -y sshpass
```

## pwgen

> Sur **macOS** vous pouvez utiliser `brew install pwgen`

> Sur Ubuntu / WSL vous pouvez utiliser `sudo apt install -y pwgen`

## Bash 5+

> Sur **macOS** vous pouvez utiliser `brew install bash`

> Sur Ubuntu / WSL vous pouvez utiliser `sudo apt install -y bash`

## shred

> Sur **macOS** vous pouvez utiliser `brew install coreutils`

### GPG

Veuillez suivre les instructions [Clé GPG](./gpg.md)

### Yubikey

- [Yubikey](./docs/yubikey.md)

### Vault Diff (optionnel)

Pour résoudre les conflits git sur le vault, il est possible de configurer git avec un mergetool custom. L'idée du custom merge tool est de décrypter le fichier pour appliquer le merge automatique de fichier.

Pour l'installer il faut exécuter les commandes suivantes

```bash
git config --local merge.merge-vault.driver ".bin/scripts/merge-vault.sh %O %A %B"
git config --local merge.merge-vault.name "ansible-vault merge driver"
git config --local diff.diff-vault.textconv "ansible-vault decrypt --vault-password-file='.bin/vault-password-file.sh' --output -"
git config --local diff.diff-vault.cachetextconv "false"
```

Ensuite lors du merge, vous serez invité à entrer votre passphrase (3 fois) pour décrypter les fichiers (distant, local et resultat). Il sera également affiché un le `git diff` dans le stdout.

```bash
git merge main
```
