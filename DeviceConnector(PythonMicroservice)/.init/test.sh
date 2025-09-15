#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/mapper-619-93/DeviceConnector(PythonMicroservice)"
PYTEST_BIN="$WORKSPACE/.venv/bin/pytest"
PYTHON_BIN="$WORKSPACE/.venv/bin/python"
LOGFILE="$WORKSPACE/.logs/pytest_$(date +%s).log"
mkdir -p "$WORKSPACE/tests" "$WORKSPACE/.logs"

cat > "$WORKSPACE/tests/test_health.py" <<'PY'
from deviceconnector import app

def test_health():
    client = app.test_client()
    r = client.get('/health')
    assert r.status_code == 200
    assert r.get_json().get('status') == 'ok'
PY

# Fast import sanity check using venv python
if [ ! -x "$PYTHON_BIN" ]; then echo "venv python not found at $PYTHON_BIN" >&2; exit 4; fi
# run check, preserve errors
"$PYTHON_BIN" - <<PY >/dev/null 2>&1 || { echo "fast import check failed: deviceconnector not importable" >&2; exit 5; }
import sys
sys.path.insert(0, "${WORKSPACE}")
import deviceconnector
print('import_ok')
PY

# Run pytest with PYTHONPATH set to workspace so 'from deviceconnector import app' works
if [ ! -x "$PYTEST_BIN" ]; then echo "pytest binary not found at $PYTEST_BIN" >&2; exit 6; fi
PYTHONPATH="$WORKSPACE" "$PYTEST_BIN" -q "$WORKSPACE/tests" 2>&1 | tee "$LOGFILE"
EXIT_CODE=${PIPESTATUS[0]:-1}
if [ "$EXIT_CODE" -ne 0 ]; then echo "pytest failed, see $LOGFILE" >&2; exit "$EXIT_CODE"; fi
