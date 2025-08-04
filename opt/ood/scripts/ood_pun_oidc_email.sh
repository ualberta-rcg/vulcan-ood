#!/bin/bash
# Save the user's OIDC email claim to ~/ondemand/oidc_email.txt
# Called as root; --user username is the first argument

# Parse --user argument
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --user) OOD_USER="$2"; shift ;;
  esac
  shift
done

# This is the var passed by Apache
OIDC_EMAIL="${OOD_OIDC_CLAIM_email}"

if [[ -n "$OOD_USER" && -n "$OIDC_EMAIL" ]]; then
  USER_ONDEMAND_HOME="/home/${OOD_USER}/ondemand"
  EMAIL_FILE="${USER_ONDEMAND_HOME}/oidc_email.txt"
  mkdir -p "${USER_ONDEMAND_HOME}"
  echo "${OIDC_EMAIL}" > "${EMAIL_FILE}"
  chown "${OOD_USER}:${OOD_USER}" "${EMAIL_FILE}"
  chmod 0600 "${EMAIL_FILE}"
fi

exit 0

