#!/bin/bash
# create-ice.sh — prepare /tmp/.ICE-unix and /run/user/$UID for an OOD VNC job.
# Runs as root via sudo (see /etc/sudoers.d/mkice). Called by desktop before.sh.erb.
#
# Security: only operates on the calling user's OWN uid. The uid arg must be a
# positive integer and, when invoked under sudo, must equal SUDO_UID (the uid of
# the user who ran sudo). This prevents a user from clobbering or hijacking
# another user's /run/user dir, and blocks empty/traversal args to rm -rf.

set -euo pipefail

TARGET_UID="${1:-}"

# 1) Must be a positive integer (blocks empty arg -> rm -rf /run/user/ and
#    traversal like ../.. -> /run/user/../.. )
if [[ ! "$TARGET_UID" =~ ^[0-9]+$ ]] || (( TARGET_UID == 0 )); then
  echo "create-ice: invalid uid '$TARGET_UID'" >&2
  exit 1
fi

# 2) Under sudo, only the caller's own uid is permitted.
if [[ -n "${SUDO_UID:-}" && "${SUDO_UID}" != "$TARGET_UID" ]]; then
  echo "create-ice: refusing to operate on uid $TARGET_UID (you are $SUDO_UID)" >&2
  exit 1
fi

# Shared ICEauthority dir (sticky, root-owned — standard X11 convention)
mkdir -p /tmp/.ICE-unix
chown root:root /tmp/.ICE-unix
chmod 1777 /tmp/.ICE-unix

# Per-user XDG runtime dir: symlink /run/user/$UID -> the job's tmp dir.
# rm is best-effort (a stale symlink from a prior session); if the entry is a
# live mount (busy) we leave it — ln -sfn still wins for the symlink case.
rm -rf "/run/user/${TARGET_UID}" 2>/dev/null || true
ln -sfn "/tmp/xdg-runtime-${TARGET_UID}" "/run/user/${TARGET_UID}"
