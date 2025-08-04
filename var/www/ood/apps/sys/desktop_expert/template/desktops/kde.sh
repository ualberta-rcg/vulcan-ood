#!/bin/bash

# Set KDE log file inside OOD staging directory
export KDE_LOG="${OOD_DIR}/kde_ood_startup.log"
exec > >(tee -a "$KDE_LOG") 2>&1
exec 2>&1

echo "[kde.sh] ===== KDE STARTUP ====="
echo "[kde.sh] Timestamp: $(date)"
echo "[kde.sh] UID: $(id -u)"
echo "[kde.sh] HOME: $HOME"
echo "[kde.sh] SHELL: $SHELL"
echo "[kde.sh] OOD_DIR: $OOD_DIR"
echo "[kde.sh] GPU_AVAILABLE: $OOD_GPU_AVAILABLE"

# Set minimal required KDE/X11 session variables
export XDG_SESSION_TYPE=x11
export QT_XCB_GL_INTEGRATION=none
export KDE_FULL_SESSION=true
export KDE_SESSION_VERSION=5
export START_KDE_NO_POWERMANAGEMENT=1
export KWIN_COMPOSE=none

# Disable KDE compositor
mkdir -p "${HOME}/.config"
cat > "${HOME}/.config/kwinrc" <<EOF
[Compositing]
Enabled=false
OpenGLIsUnsafe=true
EOF

# Disable Baloo (file indexer)
cat > "${HOME}/.config/baloofilerc" <<EOF
[Basic Settings]
Indexing-Enabled=false
EOF

# If GPU is present and VGL is ready
if [[ "$OOD_GPU_AVAILABLE" == "true" ]]; then
  echo "[kde.sh] GPU detected and VirtualGL available — using vglrun"
  echo "[kde.sh] VGL_DISPLAY: $VGL_DISPLAY"
  echo "[kde.sh] LD_PRELOAD: $LD_PRELOAD"

  for lib in $(echo "$LD_PRELOAD" | tr ':' '\n'); do
    [[ -f "$lib" ]] && echo "[kde.sh] Found: $lib" || echo "[kde.sh] MISSING: $lib"
  done

  echo "[kde.sh] Launching KDE via vglrun..."
  exec env LD_PRELOAD="$LD_PRELOAD" vglrun dbus-launch startplasma-x11 --no-splash

else
  # Software rendering fallback
  echo "[kde.sh] No GPU or missing VirtualGL — falling back to software rendering"
  export LIBGL_ALWAYS_SOFTWARE=1
  export QT_QUICK_BACKEND=software

  echo "[kde.sh] LIBGL_ALWAYS_SOFTWARE=$LIBGL_ALWAYS_SOFTWARE"
  echo "[kde.sh] QT_QUICK_BACKEND=$QT_QUICK_BACKEND"

  echo "[kde.sh] Launching KDE in software mode..."
  exec dbus-launch startplasma-x11 --no-splash
fi

# If exec fails (it shouldn't)
echo "[kde.sh] KDE Plasma failed to start. See log: $KDE_LOG"
exit 1

