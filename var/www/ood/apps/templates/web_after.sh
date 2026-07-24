#!/bin/bash
# web_after.sh — shared "after"-hook for web-app OOD apps. ERB-included by each app's
# after.sh.erb (pure bash). Waits for the server to open its port, then hands the
# connection back to OOD. The app wrapper sets OOD_APP_NAME (and optionally WAIT_TIMEOUT)
# before including this.
#
# Replaces the per-app wait_until_port_used blocks (and the over-engineered fallbacks)
# with one consistent, simple wait.

APP="${OOD_APP_NAME:-web}"
TO="${WAIT_TIMEOUT:-300}"
echo "[after:${APP}] waiting for server on ${host}:${port} (timeout ${TO}s)..."

if wait_until_port_used "${host}:${port}" "${TO}"; then
  echo "[after:${APP}] server is up on port ${port}"
else
  echo "[after:${APP}] ERROR: timed out waiting for port ${port} — check output.log"
  clean_up 1
fi

sleep 2
echo "[after:${APP}] ready"
