#!/usr/bin/env bash

set -euo pipefail

TAG_PREFIX="reverse_proxy"
readonly VERSION=$(${RELEASE_SCRIPTS_DIR}/get-version.sh)

echo "Get"
echo $VERSION

echo "Build & Push docker du Reverse Proxy sur le registry github (https://ghcr.io/mission-apprentissage/)"

generate_next_patch_version() {
  IFS='.' read -ra parts <<< "$VERSION"

  major="${parts[0]}"
  minor="${parts[1]}"
  patch="${parts[2]}"

  echo "$major.$minor.$((patch + 1))" # Nouvelle version de correctif
}

select_version() {
  local NEXT_PATCH_VERSION=$(generate_next_patch_version)

  read -p "Current version $VERSION > New version ($NEXT_PATCH_VERSION) ? [Y/n]: " response
  case $response in
    [nN][oO]|[nN])
      read -p "Custom version : " CUSTOM_VERSION
      echo "$CUSTOM_VERSION"
      ;;
    *)
      echo "$NEXT_PATCH_VERSION"
      ;;
  esac
}

NEXT_VERSION=$(select_version)

echo -e '\n'
read -p "Do you need to login to ghcr.io registry? [y/N]" RES_LOGIN

case $RES_LOGIN in
  [yY][eE][sS]|[yY])
    read -p "[ghcr.io] user ? : " u
    read -p "[ghcr.io] GH personnal token ? : " p

    echo "Login sur le registry ..."
    echo $p | docker login ghcr.io -u "$u" --password-stdin
    echo "Logged!"
    ;;
esac

set +e
docker buildx create --name mna --driver docker-container --bootstrap --use 2> /dev/null
set -e
docker buildx use --builder mna

echo "Building reverse_proxy:$NEXT_VERSION ..."
docker buildx build "$ROOT_DIR/reverse_proxy" \
      --platform linux/amd64,linux/arm64 \
      --tag ghcr.io/mission-apprentissage/mna_reverse_proxy:"$NEXT_VERSION" \
      --label "org.opencontainers.image.source=https://github.com/mission-apprentissage/infra" \
      --label "org.opencontainers.image.description=Reverse proxy Mission Apprentissage" \
      --label "org.opencontainers.image.version=$NEXT_VERSION" \
      --label "org.opencontainers.image.licenses=MIT" \
      --push

TAG="$TAG_PREFIX@$NEXT_VERSION"
echo "Creating tag $TAG"
git tag -f $TAG
git push origin $TAG
