#!/usr/bin/env bash

cd "${0%/*}/../../" || exit;

echo "Push les images docker de BAL sur le registry github (https://ghcr.io/mission-apprentissage/)"

file_path="./.infra/env.ini"

generate_next_patch_version() {
  version="$1"
  IFS='.' read -ra parts <<< "$version"

  major="${parts[0]}"
  minor="${parts[1]}"
  patch="${parts[2]}"

  echo "$major.$minor.$((patch + 1))" # Nouvelle version de correctif
}

select_version() {
  prompt="$1"
  current_version="$2"
  next_patch_version=$(generate_next_patch_version "$current_version")

  read -p "$prompt new version ($next_patch_version) ? [Y/n]: " response
  case $response in
    [nN][oO]|[nN])
      read -p "Custom version : " custom_version
      echo "$custom_version"
      ;;
    *)
      echo "$next_patch_version"
      ;;
  esac
}

build_image() {
  image_name="$1"
  current_version="$2"
  read -p "[Build&Push] $image_name image ? [Y/n]: " response

  case $response in
    [nN][oO]|[nN])
      return
      ;;
  esac

  new_version=$(select_version "$image_name $current_version > " "$current_version")
  echo "$new_version"
}

if [ -f "$file_path" ]; then
  reverse_proxy_version=$(awk -F= '/^reverse_proxy_version=/ {print $2}' "$file_path")
  app_version=$(awk -F= '/^app_version=/ {print $2}' "$file_path")

  new_reverse_proxy_version=$(build_image "Reverse Proxy" "$reverse_proxy_version")
  new_app_version=$(build_image "App" "$app_version")
else
  echo "Le fichier $file_path n'a pas été trouvé. Veuillez vérifier le chemin du fichier."
fi

echo -e '\n'
echo "New Reverse Proxy: $new_reverse_proxy_version"
echo "New App version: $new_app_version"
read -p "Confirm $v ? [Y/n]: " response

case $response in
  [nN][oO]|[nN])
    return
    ;;
esac

read -p "[ghcr.io] user ? : " u
read -p "[ghcr.io] GH personnal token ? : " p

echo "Login sur le registry ..."
echo $p | docker login ghcr.io -u "$u" --password-stdin
echo "Logged!"

echo "Création des images docker locales (docker build)"

if [ ! -z "$new_app_version" ]; then
  echo "Build ui:$new_app_version ..."
  .infra/scripts/release/release-app.sh $new_app_version push
fi

if [ ! -z "$new_reverse_proxy_version" ]; then
  echo "Building reverse_proxy:$new_reverse_proxy_version ..."
  docker build ./reverse_proxy \
        --platform linux/amd64 \
        --tag ghcr.io/mission-apprentissage/mna_bal_reverse_proxy:"$new_reverse_proxy_version" \
        --label "org.opencontainers.image.source=https://github.com/mission-apprentissage/bal" \
        --label "org.opencontainers.image.description=Reverse proxy bal" \
        --label "org.opencontainers.image.licenses=MIT"
  sleep 3
  echo "Pushing reverse_proxy:$new_reverse_proxy_version ..."
  docker push ghcr.io/mission-apprentissage/mna_bal_reverse_proxy:"$new_reverse_proxy_version"

  sed -i '' "s/reverse_proxy_version=.*/reverse_proxy_version=$new_reverse_proxy_version/" ".infra/env.ini"
  echo "Bump reverse_proxy version in .infra/env.ini : $new_reverse_proxy_version"
fi

