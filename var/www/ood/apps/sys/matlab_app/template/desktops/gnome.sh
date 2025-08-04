#!/bin/bash

echo "[gnome.sh] Starting improved GNOME session for $USER at $(date)"

# Clean up old monitor config to avoid popups
[[ -f "${HOME}/.config/monitors.xml" ]] && mv "${HOME}/.config/monitors.xml" "${HOME}/.config/monitors.xml.bak"

# Disable disk utility popup
mkdir -p "${HOME}/.config/autostart"
if [[ -f /etc/xdg/autostart/gdu-notification-daemon.desktop ]]; then
  cat /etc/xdg/autostart/gdu-notification-daemon.desktop <(echo "X-GNOME-Autostart-enabled=false") \
    > "${HOME}/.config/autostart/gdu-notification-daemon.desktop"
fi

unset DBUS_SESSION_BUS_ADDRESS 
unset DBUS_SESSION_BUS_PID 
unset XDG_SESSION_TYPE 
unset WAYLAND_DISPLAY

# Set GNOME settings - disable screensaver and session idle
gsettings set org.gnome.nautilus.preferences always-use-browser true
gsettings set org.gnome.system.proxy mode 'manual'
gsettings set org.gnome.system.proxy.http host 'squid'
gsettings set org.gnome.system.proxy.http port 3128
gsettings set org.gnome.system.proxy.https host 'squid'
gsettings set org.gnome.system.proxy.https port 3128

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

echo "[gnome.sh] Launching minimal GNOME-lite session..."

# Start window manager
if command -v metacity &>/dev/null; then
  echo "[gnome.sh] Starting metacity..."
  metacity --replace &
elif command -v mutter &>/dev/null; then
  echo "[gnome.sh] Starting mutter..."
  mutter --replace &
else
  echo "[gnome.sh] No supported window manager found."
  exit 1
fi

# Start GNOME panel only
echo "[gnome.sh] Starting gnome-panel..."
gnome-panel &
GNOME_PID=$!
sleep 2  # allow Gnome to initialize

if ! ps -p $GNOME_PID > /dev/null; then
  echo "[gnome.sh] ERROR: Gnome session failed to start."
  exit 1
fi

# Load module for OOD_APP_LAUNCH if set
if [[ -n "$OOD_APP_LAUNCH" ]]; then
  TARGET_MODULE=$(echo "$OOD_APP_LAUNCH")
  echo "[gnome.sh] Attempting to load module for: $TARGET_MODULE"

  if module load "$TARGET_MODULE"; then
    echo "[gnome.sh] Successfully loaded $TARGET_MODULE"
  else
    echo "[gnome.sh] Initial load failed, checking prerequisites..."

    # Extract all possible prerequisites from spider
    ALL_MODULES=$(module spider "$TARGET_MODULE" 2>&1 | \
                  awk '/You will need to load all module\(s\)/, /This module provides/' | \
                  grep -Eo '[A-Za-z0-9_/-]+/[0-9.]+' | sort -u)

    # Filter out the target module from the list
    PREREQS=""
    for mod in $ALL_MODULES; do
      if [[ "$mod" != "$TARGET_MODULE" ]]; then
        PREREQS="$PREREQS $mod"
      fi
    done

    if [[ -n "$PREREQS" ]]; then
      echo "[gnome.sh] Detected prerequisites: $PREREQS"
      module load $PREREQS
      echo "[gnome.sh] Retrying load of $TARGET_MODULE..."
      if module load "$TARGET_MODULE"; then
        echo "[gnome.sh] Successfully loaded $TARGET_MODULE after loading prerequisites."
      else
        echo "[gnome.sh] Failed to load $TARGET_MODULE even after loading prerequisites."
        # Do not exit — just skip launch
        unset OOD_APP_LAUNCH
      fi
    else
      echo "[gnome.sh] No prerequisites found. Giving up."
      unset OOD_APP_LAUNCH
    fi
  fi
fi

# Run app and keep session alive only while app runs
if [[ -n "$OOD_APP_LAUNCH" ]]; then
  APP_CMD=$(echo "$OOD_APP_LAUNCH" | awk -F/ '{print $1}')
  echo "[gnome.sh] Launching app: $APP_CMD"
  sleep 5  # give XFCE components time to initialize
  if [[ "$OOD_GPU_AVAILABLE" == "true" ]]; then
    echo "[gnome.sh] Using EGL for GPU acceleration"
    "$APP_CMD" &
  else
    echo "[gnome.sh] Using software rendering"
    LIBGL_ALWAYS_SOFTWARE=1 "$APP_CMD" &
  fi
  APP_PID=$!
  wait $APP_PID
else
  echo "[gnome.sh] No app to launch. Waiting for Gnome session to end."
  wait $GNOME_PID
fi

echo "[gnome.sh] Gnome session ended with code $?"

