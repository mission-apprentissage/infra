#!/bin/bash

# Display Help
Help() {
    echo
    echo "export-cron-status-prom"
    echo "##########################"
    echo
    echo "Description: Write node-exporter metric."
    echo "Syntax: export-cron-status-prom [-n|-c|-v|help]"
    echo "Example: export-cron-status-prom -c \"Renew certs for proxy01\" -v 0"
    echo "options:"
    echo "  -c    Code for metric value."
    echo "  -v    Value of metric."
    echo "  help  Show export-cron-status-prom help."
    echo
}

# Show help and exit
if [[ $1 == 'help' ]]; then
    Help
    exit
fi

# Process params
while getopts ":n :c: :v:" opt; do
  case $opt in
    n) TYPE="$OPTARG"
    ;;
    c) CODE="$OPTARG"
    ;;
    v) VALUE="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    Help
    exit;;
  esac
done

[[ -z "$CODE" ]] && { echo "Parameter -c|code is empty" ; exit 1; }
[[ -z "$VALUE" ]] && { echo "Parameter -v|value is empty" ; exit 1; }

# echo "Write metric node_cron_job_exit_code for code \"$CODE\" with value $VALUE."
ID=$(echo $CODE | shasum | cut -c1-5)

cat << EOF >> /opt/bal/data/cron/node_cron_job_exit_code.$ID.prom.$$
# HELP node_cron_job_exit_code Last exit code of cron job.
# TYPE node_cron_job_exit_code counter
node_cron_job_exit_code{code="$CODE"} $VALUE
EOF
chmod go+rw /opt/bal/data/cron/node_cron_job_exit_code.$ID.prom.$$
mv /opt/bal/data/cron/node_cron_job_exit_code.$ID.prom.$$ /opt/bal/data/cron/node_cron_job_exit_code.$ID.prom
