set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MODULE_DIR="${SCRIPT_DIR}/ovh-nodejs-client"
readonly INFRA_DIR="${SCRIPT_DIR}/../.."
readonly ENV_NAME=${1:?"Merci de préciser un environnement (ex. recette ou production)"}
readonly APP_KEY=${2:?"Merci de préciser l'application key OVH (ex. recette ou production)"}
readonly APP_SECRET=${3:?"Merci de préciser l'application secret OVH (ex. recette ou production)"}

shift

function main() {
  local env_ip
  env_ip="$(grep "\[${ENV_NAME}\]" -A 1 "${INFRA_DIR}/env.ini" | tail -1)"

  cd "${MODULE_DIR}"
  yarn install
  export APP_KEY
  export APP_SECRET
  yarn cli createFirewall "${env_ip}" "$@"
  cd - >/dev/null
}

main "$@"
