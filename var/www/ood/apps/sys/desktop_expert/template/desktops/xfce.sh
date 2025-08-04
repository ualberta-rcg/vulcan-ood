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

# Ensure D-Bus is available early
eval "$(dbus-launch --sh-syntax --exit-with-session)"
export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID

# Disable ssh-agent and gpg-agent
xfconf-query -c xfce4-session -p /startup/ssh-agent/enabled -n -t bool -s false
xfconf-query -c xfce4-session -p /startup/gpg-agent/enabled -n -t bool -s false

# Wipe and recreate ~/.config/autostart with suppression for broken apps
AUTOSTART="${HOME}/.config/autostart"
rm -rf "${AUTOSTART}"
mkdir -p "${AUTOSTART}"

for app in \
  polkit-gnome-authentication-agent-1 \
  polkit-mate-authentication-agent-1 \
  nm-applet \
  blueman-applet \
  light-locker \
  xfce4-volumed \
  xscreensaver \
  xiccd \
  system-config-printer-applet \
  gnome-keyring-daemon \
  pulseaudio \
  rhsm-icon \
  spice-vdagent \
  tracker-extract \
  tracker-miner-apps \
  tracker-miner-user-guides \
  xfce4-power-manager \
  blueman \
  xfce-polkit; do
  cat > "${AUTOSTART}/${app}.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=${app}
Exec=${app}
Hidden=true
EOF
done

# Ensure xfce4-terminal launches as login shell
TERM_CONFIG="${HOME}/.config/xfce4/terminal/terminalrc"
mkdir -p "$(dirname "${TERM_CONFIG}")"
if grep -q '^CommandLoginShell=' "${TERM_CONFIG}" 2>/dev/null; then
  sed -i 's/^CommandLoginShell=.*/CommandLoginShell=TRUE/' "${TERM_CONFIG}"
else
  echo "CommandLoginShell=TRUE" >> "${TERM_CONFIG}"
fi

# Final step: Launch XFCE session with or without VirtualGL
echo "[xfce.sh] DISPLAY is: $DISPLAY"
exec xfce4-session

echo "[xfce.sh] XFCE session ended with exit code $?"

