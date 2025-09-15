#!/usr/bin/env bash
set -euo pipefail
# Idempotent install of Python dependencies into workspace venv with conditional device lib
WORKSPACE="/home/kavia/workspace/code-generation/mapper-619-93/DeviceConnector(PythonMicroservice)"
VENV_PY="$WORKSPACE/.venv/bin/python"
VENV_PIP="$WORKSPACE/.venv/bin/pip"
REQ_BASE="$WORKSPACE/requirements.txt"
TMP_REQ=$(mktemp /tmp/deviceconnector_requirements.XXXX)
LOG_DIR="$WORKSPACE/.logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/pip_install_$(date +%s).log"
# ensure venv python exists
if [ ! -x "$VENV_PY" ]; then echo "venv missing at $WORKSPACE/.venv" >&2; exit 2; fi
# Determine device lib (prefer runtime env); document default if used
DEVICE_LIB="${DEVICE_LIB:-}"
if [ -z "$DEVICE_LIB" ]; then
  DEVICE_LIB=netmiko
  echo "DEVICE_LIB not set; defaulting to 'netmiko'" >>"$LOG"
fi
# prepare temp requirements
cp "$REQ_BASE" "$TMP_REQ"
if [ "${DEVICE_LIB,,}" = "ncclient" ]; then
  echo "ncclient>=0.6,<1" >> "$TMP_REQ"
else
  echo "netmiko>=4.0,<5" >> "$TMP_REQ"
fi
# Idempotent: pre-check imports using venv python; skip install if all imports present
SKIP_INSTALL=0
if "$VENV_PY" - <<'PY' 2>/dev/null
import sys
try:
    import flask, requests, pytest
    lib = sys.argv[1]
    if lib == 'ncclient':
        import ncclient
    else:
        import netmiko
    print('imports_ok')
except Exception:
    sys.exit(1)
PY "${DEVICE_LIB,,}"; then
  SKIP_INSTALL=1
  echo "All required packages already importable in venv; skipping pip install" >>"$LOG"
fi
# Install if needed
if [ "$SKIP_INSTALL" -ne 1 ]; then
  "$VENV_PIP" install --upgrade -r "$TMP_REQ" >>"$LOG" 2>&1 || { echo "pip install failed, see $LOG" >&2; rm -f "$TMP_REQ"; exit 11; }
fi
# Final import verification (fail fast if broken)
if ! "$VENV_PY" - <<'PY' 2>&1 | tee -a "$LOG"
import sys
try:
    import flask, requests, pytest
    lib = sys.argv[1]
    if lib == 'ncclient':
        import ncclient
    else:
        import netmiko
except Exception as e:
    print('import_check_failed', e, file=sys.stderr)
    sys.exit(3)
print('imports_ok')
PY "${DEVICE_LIB,,}"; then
  echo "Final import verification failed; check $LOG" >&2
  rm -f "$TMP_REQ"
  exit 3
fi
rm -f "$TMP_REQ"
echo "dependency install log: $LOG"
