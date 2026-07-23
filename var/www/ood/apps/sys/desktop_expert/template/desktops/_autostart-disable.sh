#!/bin/bash
# _autostart-disable.sh — shared by gnome/mate/xfce launchers.
# Disables problematic autostart apps that spam logs or try to reach services
# (system dbus, UPower, udisks, tracker NFS indexing) unavailable in an OOD VNC job.
#
# Rewrite the override .desktop if it's missing Hidden=true OR missing a Name key
# (older versions created files without Name, which strict parsers like MATE reject).

AUTOSTART="${HOME}/.config/autostart"
mkdir -p "$AUTOSTART"

for app in \
  polkit-gnome-authentication-agent-1 \
  polkit-mate-authentication-agent-1 \
  polkit-gnome-authentication-agent \
  polkit-mate-authentication-agent \
  nm-applet \
  blueman-applet \
  blueman \
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
  tracker-miner-fs-3 \
  tracker-extract-3 \
  tracker-miner-rss-3 \
  xfce4-power-manager \
  xfce-polkit \
  mate-power-manager \
  gnome-screensaver \
  mate-screensaver \
  xscreensaver-properties \
  gdu-notification-daemon; do

  df="${AUTOSTART}/${app}.desktop"
  if [[ ! -f "$df" ]] || ! grep -q '^Hidden=true$' "$df" || ! grep -q '^Name=' "$df"; then
    cat > "$df" <<EOF
[Desktop Entry]
Type=Application
Name=${app}
Exec=${app}
Hidden=true
EOF
  fi
done
