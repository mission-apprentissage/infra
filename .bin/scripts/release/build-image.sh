#!/usr/bin/env bash

set -euo pipefail

readonly TAG_PREFIX=${1:?"Merci de préciser le directory (ex. reverse_proxy, fluentd)"}
shift
readonly VERSION=$(${SCRIPT_DIR}/release/get-version.sh $TAG_PREFIX)

echo "Build & Push docker de $TAG_PREFIX sur le registry github (https://ghcr.io/mission-apprentissage/)"

get_channel() {
  local version="$1"
  channel=$(echo "$version" | cut -d '-' -f 2)

  if [ "$channel" == "$version" ]; then
    channel="latest"
  else
    channel=$(echo $channel | cut -d '.' -f 1 )
  fi

  echo $channel
}

generate_next_patch_version() {
  local current_commit_id=$(git --git-dir="$ROOT_DIR/.git" rev-parse HEAD)
  local current_version_commit_id=$(git --git-dir="$ROOT_DIR/.git" rev-list -n 1 $TAG_PREFIX@$VERSION 2> /dev/null)

  if [ "$current_commit_id" == "$current_version_commit_id" ]; then
    echo $VERSION;
    return
  fi;

  local version="$VERSION"
  
  # Extract major version
  local major="${version%%.*}"
  version="${version#*.}"

  # Extract minor version
  local minor="${version%%.*}"
  version="${version#*.}"

  # Extract patch version
  local patch="${version%%-*}"

  # Check for pre-release and build metadata
  if [[ "$version" =~ "-" ]]; then
    version="${version#*-}"
    local pre_release_channel="${version%%.*}"
    local pre_release_number="${version#*.}"

    # echo "$major.$minor.$patch$((patch + 1))"
    echo "$major.$minor.$patch-$pre_release_channel.$((pre_release_number + 1))"
  else
    echo "$major.$minor.$((patch + 1))" # Nouvelle version de correctif
  fi
}

select_version() {
  local NEXT_PATCH_VERSION=$(generate_next_patch_version)

  if [ $NEXT_PATCH_VERSION == $VERSION ]; then
    read -p "Current commit is already deployed as $VERSION. Do you want to overwrite ? [Y/n]: " overwrite
    case $overwrite in
      [yY][eE][sS]|[yY]|"")
        echo "$VERSION"
        return;
        ;;
      *)
        ;;
    esac
  fi;

  read -p "Current version $VERSION > New version ($NEXT_PATCH_VERSION) ? [Y/n]: " response
  case $response in
    [nN][oO]|[nN])
      read -p "Custom version : " CUSTOM_VERSION
      echo "$CUSTOM_VERSION"
      ;;
    [yY][eE][sS]|[yY]|"")
      echo "$NEXT_PATCH_VERSION"
      ;;
    *)
      echo "$response"
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
docker buildx create --name infra --driver docker-container --bootstrap --use 2> /dev/null
set -e

echo "Building $TAG_PREFIX:$NEXT_VERSION ..."
docker buildx build "$ROOT_DIR/$TAG_PREFIX" \
      --platform linux/amd64,linux/arm64 \
      --tag ghcr.io/mission-apprentissage/infra_$TAG_PREFIX:"$NEXT_VERSION" \
      --tag ghcr.io/mission-apprentissage/infra_$TAG_PREFIX:$(get_channel $NEXT_VERSION) \
      --label "org.opencontainers.image.source=https://github.com/mission-apprentissage/infra" \
      --label "org.opencontainers.image.description=$TAG_PREFIX Mission Apprentissage" \
      --label "org.opencontainers.image.version=$NEXT_VERSION" \
      --label "org.opencontainers.image.licenses=MIT" \
      --builder infra \
      --push

TAG="$TAG_PREFIX@$NEXT_VERSION"
echo "Creating tag $TAG"
git --git-dir="$ROOT_DIR/.git" tag -f $TAG
git --git-dir="$ROOT_DIR/.git" push -f origin $TAG
