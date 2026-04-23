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

fi
