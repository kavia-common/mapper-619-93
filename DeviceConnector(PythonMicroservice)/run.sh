#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mapper-619-93/DeviceConnector(PythonMicroservice)"
API_BIND_HOST="${API_BIND_HOST:-127.0.0.1}"
API_BIND_PORT="${API_BIND_PORT:-5000}"
export FLASK_APP=deviceconnector
"$WORKSPACE/.venv/bin/python" -m flask run --host="$API_BIND_HOST" --port="$API_BIND_PORT"
