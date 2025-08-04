#!/bin/bash

# === CONFIGURATION ===
API_HOST="http://172.26.92.21"    # Can be changed via env or hardcoded
BEARER_TOKEN="utZg4h4FvJzkWg4Em7SzUuRCzYBko4I3UjfbTuH4GVY"               # Replace with a secure loader later (e.g., ansible-vault)
LOG_FILE="/var/log/email_lookup/${USERNAME}.log"
USERNAME="${1:-$USER}"

# === CURL ===
RESPONSE=$(curl -s --max-time 30 \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  "$API_HOST/email?user=$USERNAME")

# === LOGGING ===
#echo "$(date '+%F %T') USER=$USERNAME RESPONSE=$RESPONSE" >> "$LOG_FILE"

# === PARSE RESPONSE ===
if [[ $? -ne 0 ]]; then
  #echo "$(date '+%F %T') ERROR: Timeout or connection failure." >> "$LOG_FILE"
  exit 1
fi

EMAIL=$(echo "$RESPONSE" | jq -r .email 2>/dev/null)

if [[ "$EMAIL" == "null" || -z "$EMAIL" ]]; then
  #echo "$(date '+%F %T') ERROR: Email not found for user '$USERNAME'" >> "$LOG_FILE"
  exit 2
fi

# === OUTPUT FOR OOD ERB ===
echo "$EMAIL"


