#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${CI:-}" ]]; then

  # Ensure gh is authenticated
  if ! gh auth status &> /dev/null; then
    echo -e "\033[33m===============================\033[0m"
    echo -e "\033[33m   GitHub CLI Authentication   \033[0m"
    echo -e "\033[33m===============================\033[0m"
    echo "Authenticating with GitHub CLI..."
    
    BROWSER=false gh auth login

    echo -e "\033[32m==================================\033[0m"
    echo -e "\033[32m   Authentication Successful!    \033[0m"
    echo -e "\033[32m==================================\033[0m"
  fi

  # Ensure op is authenticated

  if ! op whoami --account "${OP_ACCOUNT}" &> /dev/null; then
    echo -e "\033[33m==================================\033[0m"
    echo -e "\033[33m   1Password CLI Authentication   \033[0m"
    echo -e "\033[33m==================================\033[0m"

    op signin --account "${OP_ACCOUNT}"

    echo -e "\033[32m=================================\033[0m"
    echo -e "\033[32m   Authentication Successful!    \033[0m"
    echo -e "\033[32m=================================\033[0m"
  fi

fi
