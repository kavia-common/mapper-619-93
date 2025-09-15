#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mapper-619-93/DeviceConnector(PythonMicroservice)"
mkdir -p "$WORKSPACE" "$WORKSPACE/deviceconnector"
cat > "$WORKSPACE/requirements.txt" <<'REQ'
Flask>=2.2,<3
requests>=2.28,<3
pytest>=7,<8
# device lib (netmiko OR ncclient) will be appended during build step based on DEVICE_LIB
REQ

cat > "$WORKSPACE/deviceconnector/__init__.py" <<'PY'
from flask import Flask
app = Flask(__name__)
from . import views
PY

cat > "$WORKSPACE/deviceconnector/views.py" <<'PY'
import os
from . import app
from flask import jsonify

@app.route('/health')
def health():
    return jsonify(status='ok')

# device connector stub that respects DEVICE_LIB at runtime
def connect_stub():
    lib = os.environ.get('DEVICE_LIB','').lower()
    try:
        if lib == 'ncclient':
            import ncclient
            return True
        elif lib == 'netmiko':
            import netmiko
            return True
        else:
            return False
    except Exception:
        return False
PY

cat > "$WORKSPACE/run.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mapper-619-93/DeviceConnector(PythonMicroservice)"
API_BIND_HOST="${API_BIND_HOST:-127.0.0.1}"
API_BIND_PORT="${API_BIND_PORT:-5000}"
export FLASK_APP=deviceconnector
"$WORKSPACE/.venv/bin/python" -m flask run --host="$API_BIND_HOST" --port="$API_BIND_PORT"
SH
chmod +x "$WORKSPACE/run.sh"
