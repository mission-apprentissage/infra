#!/usr/bin/env bash

set -euo pipefail

export BIN_DIR="$(dirname -- "$( readlink -f -- "$0"; )")"
export ROOT_DIR="$(dirname "${BIN_DIR}")"
export SCRIPT_DIR="$BIN_DIR/scripts"

source "${BIN_DIR}/commands.sh"

################################################################################
# Help                                                                         #
################################################################################
function Help()
{
   # Display Help
   echo "Execute commands to manage Infra"
   echo
   echo "Usage: .bin/mna-infra [command]"
   echo 

   exit 1
}

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################

readonly command=${1:-}
if [ -z "$command" ]; then
  Help
fi;
shift

if [[ `command -v $command` != $command ]]; then
  echo "Err: Command '$command' not found"
  echo
  Help
fi;

$command "$@"
