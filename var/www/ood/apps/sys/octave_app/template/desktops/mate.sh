#!/bin/bash

echo "[mate.sh] Starting Mate session for $USER at $(date)"

unset DBUS_SESSION_BUS_ADDRESS 
unset DBUS_SESSION_BUS_PID 
unset XDG_SESSION_TYPE 
unset WAYLAND_DISPLAY

export XDG_CURRENT_DESKTOP=MATE

echo "[mate.sh] Launching mate-session under dbus-run-session..."
eval "$(dbus-launch --sh-syntax)"
mate-session &
MATE_PID=$!
sleep 2  # allow Mate to initialize

if ! ps -p $MATE_PID > /dev/null; then
  echo "[mate.sh] ERROR: Mate session failed to start."
  exit 1
fi

export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID

echo "[mate.sh] DISPLAY is: $DISPLAY"

# Load module if requested
if [[ -n "$OOD_APP_LAUNCH" ]]; then
  TARGET_MODULE=$(echo "$OOD_APP_LAUNCH")
  echo "[mate.sh] Attempting to load module for: $TARGET_MODULE"

  if module load "$TARGET_MODULE"; then
    echo "[mate.sh] Successfully loaded $TARGET_MODULE"
  else
    echo "[mate.sh] Initial load failed, checking prerequisites..."

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
      echo "[mate.sh] Detected prerequisites: $PREREQS"
      module load $PREREQS
      echo "[mate.sh] Retrying load of $TARGET_MODULE..."
      if module load "$TARGET_MODULE"; then
        echo "[mate.sh] Successfully loaded $TARGET_MODULE after prerequisites."
      else
        echo "[mate.sh] Failed again. Skipping app launch."
        unset OOD_APP_LAUNCH
      fi
    else
      echo "[mate.sh] No prerequisites found. Giving up."
      unset OOD_APP_LAUNCH
    fi
  fi
fi

# Run app and keep session alive only while app runs
if [[ -n "$OOD_APP_LAUNCH" ]]; then
  APP_CMD=$(echo "$OOD_APP_LAUNCH" | awk -F/ '{print $1}')
  echo "[mate.sh] Launching app: $APP_CMD"
  sleep 5  # give XFCE components time to initialize
  if [[ "$OOD_GPU_AVAILABLE" == "true" ]]; then
    echo "[mate.sh] Using EGL for GPU acceleration"
    "$APP_CMD" --gui &
  else
    echo "[mate.sh] Using software rendering"
    LIBGL_ALWAYS_SOFTWARE=1 "$APP_CMD" --gui &
  fi
  APP_PID=$!
  wait $APP_PID
else
  echo "[mate.sh] No app to launch. Waiting for Mate session to end."
  wait $MATE_PID
fi

echo "[mate.sh] Mate session ended with code $?"
