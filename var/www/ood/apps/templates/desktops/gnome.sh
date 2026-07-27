#!/bin/bash
# gnome.sh — self-contained GNOME-lite desktop launcher for OOD VNC apps.
# ERB-inlined by each app's script.sh.erb (one file per DE; no sibling sourcing).
# ALL desktop logic lives here: browser default, chrome patch, autostart, proxy,
# session start, and app launch. before.sh.erb supplies: OOD_GPU_AVAILABLE,
# OOD_APP_LAUNCH, OOD_NUM_CORES, XDG_RUNTIME_DIR.

log(){ echo "[desktop:gnome] $*"; }
log "starting GNOME-lite session for $USER at $(date)"

# --- env cleanup ---
unset DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID XDG_SESSION_TYPE WAYLAND_DISPLAY
unset $(env | grep -o '^BASH_FUNC_.*%%' | cut -d= -f1) 2>/dev/null || true
export XDG_CURRENT_DESKTOP=GNOME GNOME_SHELL_SESSION_MODE=classic GNOME_SESSION_MODE=classic
export XDG_SESSION_TYPE=x11 GIO_USE_VFS=local GTK_MODULES="" PIPEWIRE_DISABLE=1 DISABLE_SYSTEMD=1

# --- suppress monitor-layout popup ---
[[ -f "${HOME}/.config/monitors.xml" ]] && mv "${HOME}/.config/monitors.xml" "${HOME}/.config/monitors.xml.bak"

# --- D-Bus session first, so gsettings works ---
eval "$(dbus-launch --sh-syntax --exit-with-session)"
export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
log "D-Bus session up"

# --- disable noisy / unavailable autostart apps ---
AUTOSTART="${HOME}/.config/autostart"; mkdir -p "$AUTOSTART"
for app in polkit-gnome-authentication-agent-1 polkit-mate-authentication-agent-1 \
  polkit-gnome-authentication-agent polkit-mate-authentication-agent nm-applet blueman-applet \
  blueman light-locker xfce4-volumed xscreensaver xiccd system-config-printer-applet \
  gnome-keyring-daemon pulseaudio rhsm-icon spice-vdagent tracker-extract tracker-miner-apps \
  tracker-miner-user-guides tracker-miner-fs-3 tracker-extract-3 tracker-miner-rss-3 \
  xfce4-power-manager xfce-polkit mate-power-manager gnome-screensaver mate-screensaver \
  xscreensaver-properties gdu-notification-daemon; do
  df="${AUTOSTART}/${app}.desktop"
  if [[ ! -f "$df" ]] || ! grep -q '^Hidden=true$' "$df" || ! grep -q '^Name=' "$df"; then
    printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s\nHidden=true\n' "$app" "$app" > "$df"
  fi
done
log "autostart noise disabled"

# --- GNOME settings: browser-mode file manager + squid proxy ---
gsettings set org.gnome.nautilus.preferences always-use-browser true 2>/dev/null || true
gsettings set org.gnome.system.proxy mode 'manual'            2>/dev/null || true
gsettings set org.gnome.system.proxy.http  host 'squid' port 3128 2>/dev/null || true
gsettings set org.gnome.system.proxy.https host 'squid' port 3128 2>/dev/null || true

# --- Chrome: per-user .desktop override (strip VGL faker, disable sandbox/GPU) ---
CHROME_BIN="/usr/bin/google-chrome-stable"
CHROME_SRC="/usr/share/applications/google-chrome.desktop"
CHROME_DST="${HOME}/.local/share/applications/google-chrome.desktop"
if [[ -x "$CHROME_BIN" && -f "$CHROME_SRC" ]]; then
  mkdir -p "$(dirname "$CHROME_DST")"
  CHROME_PROXY="${https_proxy:-${http_proxy:-}}"
  CHROME_EXEC="env -u LD_PRELOAD /usr/bin/google-chrome-stable --no-sandbox --disable-gpu-sandbox --disable-gpu"
  [[ -n "$CHROME_PROXY" ]] && CHROME_EXEC="$CHROME_EXEC --proxy-server=$CHROME_PROXY"
  sed -e "s#^Exec=/usr/bin/google-chrome-stable#Exec=$CHROME_EXEC#" "$CHROME_SRC" > "$CHROME_DST"
  chmod 644 "$CHROME_DST"
  log "Chrome launcher patched (--no-sandbox, --disable-gpu, no VGL faker)"
else
  log "WARN: Chrome not present on this image; skipping .desktop patch"
fi

# --- default browser = Chrome (mimeapps.list for GNOME + legacy gsettings) ---
command -v xdg-mime >/dev/null 2>&1 && xdg-mime default google-chrome.desktop \
  text/html x-scheme-handler/http x-scheme-handler/https x-scheme-handler/about \
  x-scheme-handler/unknown application/xhtml+xml application/pdf 2>/dev/null || true
gsettings set org.gnome.desktop.default-applications.browser exec 'google-chrome' 2>/dev/null || true
rm -f ~/.config/google-chrome/Singleton*
log "default browser set to Chrome"

# --- window manager ---
if   command -v metacity >/dev/null 2>&1; then log "starting metacity"; metacity --replace &
elif command -v mutter  >/dev/null 2>&1; then log "starting mutter";  mutter --replace &
else log "ERROR: no supported window manager (metacity/mutter)"; exit 1; fi

# --- GNOME panel (the desktop) ---
log "starting gnome-panel"
gnome-panel &
SESSION_PID=$!
sleep 2
ps -p "$SESSION_PID" >/dev/null || { log "ERROR: gnome-panel failed to start"; exit 1; }
log "session up (pid $SESSION_PID)"

# --- app launch (if requested), else keep the desktop alive ---
if [[ -n "$OOD_APP_LAUNCH" ]]; then
  log "loading app module: $OOD_APP_LAUNCH"
  if ! module load "$OOD_APP_LAUNCH" 2>/dev/null; then
    PREREQS=$(module spider "$OOD_APP_LAUNCH" 2>&1 | awk '/You will need to load all module\(s\)/, /This module provides/' | grep -Eo '[A-Za-z0-9_/-]+/[0-9.]+' | sort -u | grep -vxF "$OOD_APP_LAUNCH" | tr '\n' ' ')
    if [[ -n "${PREREQS// }" ]]; then
      log "loading spider prereqs:${PREREQS}"; module --force purge 2>/dev/null; module load $PREREQS
      module load "$OOD_APP_LAUNCH" 2>/dev/null || { log "WARN: load failed after prereqs"; unset OOD_APP_LAUNCH; }
    else
      log "no spider prereqs; trying StdEnv"; module load StdEnv/2020 gcc/9.3.0 2>/dev/null || module load StdEnv/2023 2>/dev/null
      module load "$OOD_APP_LAUNCH" 2>/dev/null || { log "WARN: load failed with StdEnv"; unset OOD_APP_LAUNCH; }
    fi
  fi
fi

if [[ -n "$OOD_APP_LAUNCH" ]]; then
  APP_CMD=$(echo "$OOD_APP_LAUNCH" | awk -F/ '{print $1}')
  log "launching app: $APP_CMD (GPU=${OOD_GPU_AVAILABLE:-false})"
  sleep 5
  if [[ "${OOD_GPU_AVAILABLE}" == "true" ]]; then "$APP_CMD" ${OOD_APP_ARGS:-} & else LIBGL_ALWAYS_SOFTWARE=1 "$APP_CMD" ${OOD_APP_ARGS:-} & fi
  APP_PID=$!; wait "$APP_PID"
else
  log "no app requested; waiting for desktop session"
  wait "$SESSION_PID"
fi
log "session ended"
