#!/bin/bash

echo "[xfce.sh] Starting XFCE session for $USER at $(date)"

# Remove any preconfigured monitor layouts (prevents display popup)
if [[ -f "${HOME}/.config/monitors.xml" ]]; then
  mv "${HOME}/.config/monitors.xml" "${HOME}/.config/monitors.xml.bak"
fi

# Copy default panel if user's panel config is missing (avoid GUI prompt)
PANEL_CONFIG="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
if [[ ! -f "${PANEL_CONFIG}" ]]; then
  mkdir -p "$(dirname "${PANEL_CONFIG}")"
  cp "/etc/xdg/xfce4/panel/default.xml" "${PANEL_CONFIG}"
fi

unset DBUS_SESSION_BUS_ADDRESS 
unset DBUS_SESSION_BUS_PID 
unset XDG_SESSION_TYPE 
unset WAYLAND_DISPLAY

# Ensure D-Bus is available early
eval "$(dbus-launch --sh-syntax --exit-with-session)"
export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID

# Disable ssh-agent and gpg-agent
xfconf-query -c xfce4-session -p /startup/ssh-agent/enabled -n -t bool -s false
xfconf-query -c xfce4-session -p /startup/gpg-agent/enabled -n -t bool -s false

AUTOSTART="${HOME}/.config/autostart"
rm -rf "${AUTOSTART}"
mkdir -p "${AUTOSTART}"

for app in \
  polkit-gnome-authentication-agent-1 \
  polkit-mate-authentication-agent-1 \
  nm-applet \
  blueman-applet \
  light-locker \
  xiccd \
  system-config-printer-applet \
  gnome-keyring-daemon \
  rhsm-icon \
  spice-vdagent \
  tracker-extract \
  tracker-miner-apps \
  tracker-miner-user-guides \
  xfce4-power-manager \
  blueman \
  xfce-polkit; do
  echo -e "[Desktop Entry]\nHidden=true" > "${AUTOSTART}/${app}.desktop"
done

# Ensure xfce4-terminal launches as login shell
TERM_CONFIG="${HOME}/.config/xfce4/terminal/terminalrc"
mkdir -p "$(dirname "${TERM_CONFIG}")"
if grep -q '^CommandLoginShell=' "${TERM_CONFIG}" 2>/dev/null; then
  sed -i 's/^CommandLoginShell=.*/CommandLoginShell=TRUE/' "${TERM_CONFIG}"
else
  echo "CommandLoginShell=TRUE" >> "${TERM_CONFIG}"
fi

# Final step: Launch XFCE session
echo "[xfce.sh] DISPLAY is: $DISPLAY"
xfce4-session &
XFCE_PID=$!
sleep 2  # allow XFCE to initialize
if ! ps -p $XFCE_PID > /dev/null; then
  echo "[xfce.sh] ERROR: XFCE session failed to start."
  exit 1
fi

# Load module if requested
if [[ -n "$OOD_APP_LAUNCH" ]]; then
  TARGET_MODULE=$(echo "$OOD_APP_LAUNCH")
  echo "[xfce.sh] Attempting to load module for: $TARGET_MODULE"

  if module load "$TARGET_MODULE"; then
    echo "[xfce.sh] Successfully loaded $TARGET_MODULE"
  else
    echo "[xfce.sh] Initial load failed, checking prerequisites..."

    ALL_MODULES=$(module spider "$TARGET_MODULE" 2>&1 | \
                  awk '/You will need to load all module\(s\)/, /This module provides/' | \
                  grep -Eo '[A-Za-z0-9_/-]+/[0-9.]+' | sort -u)

    PREREQS=""
    for mod in $ALL_MODULES; do
      if [[ "$mod" != "$TARGET_MODULE" ]]; then
        PREREQS="$PREREQS $mod"
      fi
    done

    if [[ -n "$PREREQS" ]]; then
      echo "[xfce.sh] Detected prerequisites: $PREREQS"
      module load $PREREQS
      echo "[xfce.sh] Retrying load of $TARGET_MODULE..."
      if module load "$TARGET_MODULE"; then
        echo "[xfce.sh] Successfully loaded $TARGET_MODULE after prerequisites."
      else
        echo "[xfce.sh] Failed again. Skipping app launch."
        unset OOD_APP_LAUNCH
      fi
    else
      echo "[xfce.sh] No prerequisites found. Giving up."
      unset OOD_APP_LAUNCH
    fi
  fi
fi

# Run app and keep session alive only while app runs
if [[ -n "$OOD_APP_LAUNCH" ]]; then
  APP_CMD=$(echo "$OOD_APP_LAUNCH" | awk -F/ '{print $1}')
  echo "[xfce.sh] Launching app: $APP_CMD"
  sleep 5  # give XFCE components time to initialize
  if [[ "$OOD_GPU_AVAILABLE" == "true" ]]; then
    echo "[xfce.sh] Using EGL for GPU acceleration"
    "$APP_CMD" &
  else
    echo "[xfce.sh] Using software rendering"
    LIBGL_ALWAYS_SOFTWARE=1 "$APP_CMD" &
  fi
  APP_PID=$!
  wait $APP_PID
else
  echo "[xfce.sh] No app to launch. Waiting for XFCE session to end."
  wait $XFCE_PID
fi

echo "[xfce.sh] XFCE session ended with code $?"

