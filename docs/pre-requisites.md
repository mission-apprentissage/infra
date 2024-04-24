# Prérequis

## Environnement local

Contient l'ensemble des données sensibles nécessaires à la mise en place de
l'application.

- Ansible 2.7+: `brew install ansible`
- sshpass
  ```bash
  brew tap esolitos/ipa
  brew install esolitos/ipa/sshpass
  ```
- pwgen: `brew install pwgen`
- bash 5+: `brew install bash`
- 1Password CLI
- Brew (jq)

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
git config --local diff.diff-vault.textconv "ansible-vault decrypt --vault-password-file='./setup/vault/get-vault-password-client.sh' --output -"
git config --local diff.diff-vault.cachetextconv "false"
```

Ensuite lors du merge, vous serez invité à entrer votre passphrase (3 fois) pour décrypter les fichiers (distant, local et resultat). Il sera également affiché un le `git diff` dans le stdout.

```bash
git merge master
```
