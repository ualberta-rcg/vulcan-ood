#!/bin/bash
# xfce.sh — self-contained XFCE desktop launcher for OOD VNC apps.
# ERB-inlined by each app's script.sh.erb. All desktop logic lives here.
# before.sh.erb supplies: OOD_GPU_AVAILABLE, OOD_APP_LAUNCH, XDG_RUNTIME_DIR.
#
# The XFCE "Web Browser" panel button runs exo-open, which reads ONLY
# ~/.config/xfce4/helpers.rc (it ignores mimeapps.list). The CVMFS default there
# is WebBrowser=firefox (not installed on compute images -> opens nothing), so we
# write helpers.rc = google-chrome here. That is the actual fix for the button.

log(){ echo "[desktop:xfce] $*"; }
log "starting XFCE session for $USER at $(date)"

# --- env cleanup + PATH (local bins first) ---
unset DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID XDG_SESSION_TYPE WAYLAND_DISPLAY
unset $(env | grep -o '^BASH_FUNC_.*%%' | cut -d= -f1) 2>/dev/null || true
export XDG_CURRENT_DESKTOP=XFCE
export PATH=/snap/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin:/bin:$PATH

# --- suppress monitor-layout popup ---
[[ -f "${HOME}/.config/monitors.xml" ]] && mv "${HOME}/.config/monitors.xml" "${HOME}/.config/monitors.xml.bak"

# --- copy default panel config if missing (avoids a GUI prompt) ---
PANEL_CONFIG="${HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
if [[ ! -f "$PANEL_CONFIG" ]]; then
  mkdir -p "$(dirname "$PANEL_CONFIG")"
  cp "/etc/xdg/xfce4/panel/default.xml" "$PANEL_CONFIG" 2>/dev/null && log "default panel installed"
fi

# --- D-Bus session ---
eval "$(dbus-launch --sh-syntax --exit-with-session)"
export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
log "D-Bus session up"

# --- disable XFCE's own ssh/gpg agents (use the job's) ---
xfconf-query -c xfce4-session -p /startup/ssh-agent/enabled -n -t bool -s false 2>/dev/null || true
xfconf-query -c xfce4-session -p /startup/gpg-agent/enabled -n -t bool -s false 2>/dev/null || true

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

# --- default browser = Chrome ---
# mimeapps.list (general) + helpers.rc (XFCE exo-open panel button — the actual fix)
command -v xdg-mime >/dev/null 2>&1 && xdg-mime default google-chrome.desktop \
  text/html x-scheme-handler/http x-scheme-handler/https x-scheme-handler/about \
  x-scheme-handler/unknown application/xhtml+xml application/pdf 2>/dev/null || true
mkdir -p "${HOME}/.config/xfce4"
cat > "${HOME}/.config/xfce4/helpers.rc" <<'RCEOF'
WebBrowser=google-chrome
MailReader=thunderbird
TerminalEmulator=xfce4-terminal
RCEOF

# exo-open (the panel "Web Browser" button) resolves WebBrowser= to a helper .desktop
# in $XDG_DATA_DIRS/xfce4/helpers/. The CVMFS helpers dir isn't always on that search
# path inside an OOD job, so exo-open reports "default browser not found". Install a
# USER helper (~/.local/share/xfce4/helpers = XDG_DATA_HOME, always searched) that
# launches Chrome with the OOD-safe flags: strip the VGL faker, disable sandbox/GPU.
mkdir -p "${HOME}/.local/share/xfce4/helpers"
HCMD="env -u LD_PRELOAD %B --no-sandbox --disable-gpu-sandbox --disable-gpu"
[[ -n "$CHROME_PROXY" ]] && HCMD="$HCMD --proxy-server=$CHROME_PROXY"
cat > "${HOME}/.local/share/xfce4/helpers/google-chrome.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=X-XFCE-Helper
Name=Google Chrome
Icon=google-chrome
StartupNotify=true
X-XFCE-Binaries=google-chrome-stable;google-chrome;
X-XFCE-Category=WebBrowser
X-XFCE-Commands=$HCMD;
X-XFCE-CommandsWithParameter=$HCMD "%s";
EOF
rm -f ~/.config/google-chrome/Singleton*
log "default browser set to Chrome (mimeapps.list + XFCE helpers.rc)"

# --- xfce4-terminal opens as a login shell ---
TERM_CONFIG="${HOME}/.config/xfce4/terminal/terminalrc"
mkdir -p "$(dirname "$TERM_CONFIG")"
if grep -q '^CommandLoginShell=' "$TERM_CONFIG" 2>/dev/null; then
  sed -i 's/^CommandLoginShell=.*/CommandLoginShell=TRUE/' "$TERM_CONFIG"
else
  echo "CommandLoginShell=TRUE" >> "$TERM_CONFIG"
fi

# --- XFCE session ---
log "launching xfce4-session (DISPLAY=$DISPLAY)"
xfce4-session &
SESSION_PID=$!
sleep 2
ps -p "$SESSION_PID" >/dev/null || { log "ERROR: xfce4-session failed to start"; exit 1; }
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
  if [[ "${OOD_GPU_AVAILABLE}" == "true" ]]; then "$APP_CMD" & else LIBGL_ALWAYS_SOFTWARE=1 "$APP_CMD" & fi
  APP_PID=$!; wait "$APP_PID"
else
  log "no app requested; waiting for desktop session"
  wait "$SESSION_PID"
fi
log "session ended"
