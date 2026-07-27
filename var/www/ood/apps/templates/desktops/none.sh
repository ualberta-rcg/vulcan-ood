#!/bin/bash
# none.sh — self-contained app-only launcher (no desktop environment) for OOD VNC apps.
# ERB-inlined by each app's script.sh.erb. Used when a form offers desktop=none and the
# user wants just the application window (no GNOME/MATE/XFCE chrome). Still sets Chrome as
# the default browser in case the app opens links. before.sh.erb supplies: OOD_GPU_AVAILABLE,
# OOD_APP_LAUNCH, XDG_RUNTIME_DIR.

log(){ echo "[desktop:none] $*"; }
log "starting app-only session for $USER at $(date)"

# --- env cleanup ---
unset DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID XDG_SESSION_TYPE WAYLAND_DISPLAY
unset $(env | grep -o '^BASH_FUNC_.*%%' | cut -d= -f1) 2>/dev/null || true

# --- D-Bus (some apps still want it) ---
eval "$(dbus-launch --sh-syntax --exit-with-session)"
export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID
log "D-Bus session up"

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
  log "Chrome not present on this image; skipping .desktop patch"
fi

# --- default browser = Chrome (covers any link the app opens) ---
command -v xdg-mime >/dev/null 2>&1 && xdg-mime default google-chrome.desktop \
  text/html x-scheme-handler/http x-scheme-handler/https x-scheme-handler/about \
  x-scheme-handler/unknown application/xhtml+xml application/pdf 2>/dev/null || true
mkdir -p "${HOME}/.config/xfce4"
printf 'WebBrowser=google-chrome\nMailReader=thunderbird\nTerminalEmulator=xfce4-terminal\n' > "${HOME}/.config/xfce4/helpers.rc"
rm -f ~/.config/google-chrome/Singleton*
log "default browser set to Chrome"

# --- app launch ---
if [[ -z "$OOD_APP_LAUNCH" ]]; then
  log "WARN: no app requested (OOD_APP_LAUNCH empty); nothing to display. Exiting."
  exit 0
fi

log "loading app module: $OOD_APP_LAUNCH"
if ! module load "$OOD_APP_LAUNCH" 2>/dev/null; then
  PREREQS=$(module spider "$OOD_APP_LAUNCH" 2>&1 | awk '/You will need to load all module\(s\)/, /This module provides/' | grep -Eo '[A-Za-z0-9_/-]+/[0-9.]+' | sort -u | grep -vxF "$OOD_APP_LAUNCH" | tr '\n' ' ')
  if [[ -n "${PREREQS// }" ]]; then
    log "loading spider prereqs:${PREREQS}"; module --force purge 2>/dev/null; module load $PREREQS
    module load "$OOD_APP_LAUNCH" 2>/dev/null || { log "ERROR: load failed after prereqs; aborting"; exit 1; }
  else
    log "no spider prereqs; trying StdEnv"; module load StdEnv/2020 gcc/9.3.0 2>/dev/null || module load StdEnv/2023 2>/dev/null
    module load "$OOD_APP_LAUNCH" 2>/dev/null || { log "ERROR: load failed with StdEnv; aborting"; exit 1; }
  fi
fi

APP_CMD=$(echo "$OOD_APP_LAUNCH" | awk -F/ '{print $1}')
log "launching app: $APP_CMD (GPU=${OOD_GPU_AVAILABLE:-false})"
sleep 2
if [[ "${OOD_GPU_AVAILABLE}" == "true" ]]; then "$APP_CMD" ${OOD_APP_ARGS:-} & else LIBGL_ALWAYS_SOFTWARE=1 "$APP_CMD" ${OOD_APP_ARGS:-} & fi
APP_PID=$!; wait "$APP_PID"
log "session ended"
