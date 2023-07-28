#!/usr/bin/env bash

set -euo pipefail

################################################################################
# Help                                                                         #
################################################################################
function Help()
{
   # Display Help
   echo "Download logs from server"
   echo
   echo "Usage: ./download_logs.sh [command] [destination] "
   echo 
   echo "  destination     Server address working with 'ssh [destination]'"
   echo 
   echo "Commands"
   echo "  ls [destination] <file>       List directory content, similar to 'ls' command"
   echo "  dl [destination] <file>       Download file locally"
   echo "  rm                            Remove local log files"
   echo 

   exit 1
}

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OPERATION=${1:-}
readonly SERVER=${2:-}
readonly FILE=${3:-}

if [ "$OPERATION" == "rm" ]; then
  rm -rf "$SCRIPT_DIR/logs/"
fi

if [[ -z "${SERVER}" ]]; then
  Help
else
  ssh $SERVER exit > /dev/null
fi;

case $OPERATION in
  'ls')
    ssh -t $SERVER "sudo -S ls /opt/bal/data/fluentd/$FILE"
    ;;
  'dl')
    if [[ "$FILE" != *.log.gz ]]; then
      echo "$FILE: is not a log file";
      exit 1
    fi;
    NAME="${FILE%.log.gz}"
    mkdir -p "$SCRIPT_DIR/logs/"
    DEST="$SCRIPT_DIR/logs/$NAME.json"
    mkdir -p "$(dirname "$DEST")"
    ssh $SERVER "sudo -S cat /opt/bal/data/fluentd/$FILE" | gunzip -c | jq -s > "$DEST"
    echo "Fichier téléchargé dans $DEST";
    ;;
  *)
    Help
    ;;
esac

