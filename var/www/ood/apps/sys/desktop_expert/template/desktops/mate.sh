#!/bin/bash
echo "[mate.sh] Starting MATE desktop session for $USER at $(date)"

# Optional: Log file for debugging
export MATE_LOG="${HOME}/.mate_ood_startup.log"
exec > >(tee -a "$MATE_LOG") 2>&1

# Optional: Custom ICEauthority file (can be skipped if no issues)
export ICEAUTHORITY="${HOME}/.ICEauthority-$$"
touch "$ICEAUTHORITY"

# Remove monitor layout popup
if [[ -f "${HOME}/.config/monitors.xml" ]]; then
  mv "${HOME}/.config/monitors.xml" "${HOME}/.config/monitors.xml.bak"
fi

# Set terminal to open as login shell (harmless if dconf isn't installed)
dconf write /org/mate/terminal/profiles/default/login-shell true 2>/dev/null || true

export DISABLE_SYSTEMD=1
export GIO_USE_VFS=local
export GTK_MODULES=""
export PIPEWIRE_DISABLE=1
export XDG_CURRENT_DESKTOP=MATE

# Start MATE desktop inside a dbus-managed session
echo "[mate.sh] Launching mate-session under dbus-run-session..."
exec dbus-run-session -- mate-session

