#!/bin/bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="${SCRIPT_DIR}/../../.."

cd ${ROOT_DIR}

next_version="${1:?"Veuillez préciser la version"}"
mode=${2:?"Veuillez préciser le mode <push|load>"}
shift 2

if [[ $# == "0" ]]; then
  echo "Veuillez spécifier les environnements à build (production, recette, preview, local)"
  exit 1;
fi;

SHARED_OPS="\
        --build-arg YARN_FLAGS="--immutable" \
        --platform linux/amd64 \
        --label "org.opencontainers.image.source=https://github.com/mission-apprentissage/bal" \
        --label "org.opencontainers.image.licenses=MIT"
"

CACHE_OPTS=""
if [[ ! -z "${CI:-}" ]]; then
    DEPS_ID=($(md5sum ./yarn.lock))
    SHARED_OPS="${SHARED_OPS} --cache-from type=gha,scope=$DEPS_ID"
    CACHE_OPTS="\
        --cache-to type=gha,mode=min,scope=$DEPS_ID \
    "
fi

echo "Build all stages in parallel and cache yarn installs"
docker build . \
        --target root \
        $SHARED_OPS \
        $CACHE_OPTS

# Declare an associative array to store the names and PIDs of the background processes
names=()
pids=()

for env in "$@"
do
  echo "Start building ui:$next_version with mode=$mode; env=$env"
  docker build . \
    --build-arg PUBLIC_ENV="$env" \
    --build-arg PUBLIC_VERSION="$next_version" \
    --tag ghcr.io/mission-apprentissage/mna_bal_ui:"$next_version-$env" \
    --label "org.opencontainers.image.description=Ui bal" \
    --target ui \
    --${mode} \
    --quiet \
    $SHARED_OPS &

  pids+=($!)
  names+=("ui-$env")
done

echo "Start building server:$next_version with mode=$mode"
docker build . \
        --build-arg PUBLIC_VERSION="$next_version" \
        --tag ghcr.io/mission-apprentissage/mna_bal_server:"$next_version" \
        --label "org.opencontainers.image.description=Server bal" \
        --target server \
        --${mode} \
        --quiet \
        $SHARED_OPS &

pids+=($!)
names+=("server")

final_code=0
for ((i = 0; i < ${#pids[@]}; i++)); do
  pid=${pids[i]}
  name=${names[i]}
  wait "$pid"
  status_code=$?
  final_code=$((final_code + status_code))
  echo "Process '$name' with PID $pid finished with status code: $status_code"
done

if [ "$final_code" -gt 0 ]; then
  echo "One or more background processes failed."
  exit 1
fi

if [[ $(uname) = "Darwin" ]]; then
  sed -i '' "s/app_version=.*/app_version=$next_version/" ".infra/env.ini"
else
  sed -i'' "s/app_version=.*/app_version=$next_version/" ".infra/env.ini"
fi
echo "Bump app version in .infra/env.ini : $next_version"

if [[ $(uname) = "Darwin" ]]; then
  sed -i '' "s/default:.*/default: $next_version/" ".github/workflows/_deploy.yml"
else
  sed -i'' "s/default:.*/default: $next_version/" ".github/workflows/_deploy.yml"
fi
echo "Bump app version in _deploy.yml : $next_version"
