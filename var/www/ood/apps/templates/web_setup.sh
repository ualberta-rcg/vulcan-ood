#!/bin/bash
# web_setup.sh — shared "before"-hook preamble for web-app OOD apps (jupyter, rstudio,
# vs_code, chainforge, voyant, openrefine, tensorboard). ERB-included by each app's
# before.sh.erb (pure bash — no ERB here). The app's wrapper sets OOD_APP_NAME first,
# includes this, then adds its app-specific setup AFTER.
#
# Provides the common bits every web app needs: module fn, $port, $JOB_DIR, $CC_CLUSTER,
# and consistent [before:<app>] logging. Sections stay in the correct files:
# before=setup, script=launch, after=wait.

APP="${OOD_APP_NAME:-web}"
wlog(){ echo "[before:${APP}] $*"; }
wlog "starting setup for $USER (uid $(id -u))"

# Export the module function into non-login shells (script.sh.erb loads modules)
if [[ $(type -t module) == "function" ]]; then
  export -f module
else
  wlog "WARN: 'module' function unavailable"
fi

# Job context + Alliance cluster id (so CVMFS modules resolve the right builds)
export JOB_DIR="${PWD}"
export CC_CLUSTER=vulcan

# Free port for the server: script.sh.erb binds to it, after.sh.erb waits on it
export port="$(find_port ${host})"
if [[ -z "$port" ]]; then
  wlog "ERROR: failed to allocate a free port"
  exit 1
fi
wlog "port=${port} job_dir=${JOB_DIR}"
