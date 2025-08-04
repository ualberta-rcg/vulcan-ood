#!/bin/bash

echo "[gnome-session.sh] Starting improved GNOME session for $USER at $(date)"

#Update Path to use Local files first
export PATH=/snap/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/bin:$PATH

# Clean up old monitor config to avoid popups
[[ -f "${HOME}/.config/monitors.xml" ]] && mv "${HOME}/.config/monitors.xml" "${HOME}/.config/monitors.xml.bak"

# Disable disk utility popup
mkdir -p "${HOME}/.config/autostart"
if [[ -f /etc/xdg/autostart/gdu-notification-daemon.desktop ]]; then
  cat /etc/xdg/autostart/gdu-notification-daemon.desktop <(echo "X-GNOME-Autostart-enabled=false") \
    > "${HOME}/.config/autostart/gdu-notification-daemon.desktop"
fi

# Set GNOME settings - disable screensaver and session idle
gsettings set org.gnome.nautilus.preferences always-use-browser true

# Environment variables
export XDG_CURRENT_DESKTOP=GNOME
export GNOME_SHELL_SESSION_MODE=classic
export GNOME_SESSION_MODE=classic
export XDG_SESSION_TYPE=x11
export GIO_USE_VFS=local
export GTK_MODULES=""
export PIPEWIRE_DISABLE=1
export DISABLE_SYSTEMD=1

# Start D-Bus cleanly
eval "$(dbus-launch --sh-syntax --exit-with-session)"
export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID

echo "[gnome-session.sh] Launching minimal GNOME-lite session..."

# Clean up old Google Chrome locks
rm -f ~/.config/google-chrome/Singleton*

# Define Chrome as Default Browswer
xdg-settings set default-web-browser google-chrome.desktop

# Start window manager
if command -v metacity &>/dev/null; then
  echo "[gnome-session.sh] Starting metacity..."
  metacity --replace &
elif command -v mutter &>/dev/null; then
  echo "[gnome-session.sh] Starting mutter..."
  mutter --replace &
else
  echo "[gnome-session.sh] No supported window manager found."
  exit 1
fi

# Start GNOME panel only
echo "[gnome-session.sh] Starting gnome-panel..."
gnome-panel &

# Keep session alive
wait

