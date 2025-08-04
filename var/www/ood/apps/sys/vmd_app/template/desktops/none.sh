#!/bin/bash
echo "[none.sh] Starting app-only session for $USER at $(date)"

unset DBUS_SESSION_BUS_ADDRESS 
unset DBUS_SESSION_BUS_PID 
unset XDG_SESSION_TYPE 
unset WAYLAND_DISPLAY

# Start D-Bus cleanly (some apps still want this)
eval "$(dbus-launch --sh-syntax --exit-with-session)"
export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID

# Load module for OOD_APP_LAUNCH if set
if [[ -n "$OOD_APP_LAUNCH" ]]; then
  TARGET_MODULE=$(echo "$OOD_APP_LAUNCH")
  echo "[none.sh] Attempting to load module for: $TARGET_MODULE"

  if module load "$TARGET_MODULE"; then
    echo "[none.sh] Successfully loaded $TARGET_MODULE"
  else
    echo "[none.sh] Initial load failed, checking prerequisites..."

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
      echo "[none.sh] Detected prerequisites: $PREREQS"
      module load $PREREQS
      echo "[none.sh] Retrying load of $TARGET_MODULE..."
      if module load "$TARGET_MODULE"; then
        echo "[none.sh] Successfully loaded $TARGET_MODULE after loading prerequisites."
      else
        echo "[none.sh] Failed to load $TARGET_MODULE even after loading prerequisites."
        unset OOD_APP_LAUNCH
      fi
    else
      echo "[none.sh] No prerequisites found. Giving up."
      unset OOD_APP_LAUNCH
    fi
  fi
fi

# Run app and keep session alive only while app runs
if [[ -n "$OOD_APP_LAUNCH" ]]; then
  APP_CMD=$(echo "$OOD_APP_LAUNCH" | awk -F/ '{print $1}')
  echo "[none.sh] Launching app: $APP_CMD"
  sleep 5  # give components time to initialize
  if [[ "$OOD_GPU_AVAILABLE" == "true" ]]; then
    echo "[none.sh] Using EGL for GPU acceleration"
    "$APP_CMD" &
  else
    echo "[none.sh] Using software rendering"
    LIBGL_ALWAYS_SOFTWARE=1 "$APP_CMD" &
  fi
  APP_PID=$!
  wait $APP_PID
else
  echo "[none.sh] No app to launch. Waiting for session to end."
fi

echo "[none.sh] session ended with code $?"
