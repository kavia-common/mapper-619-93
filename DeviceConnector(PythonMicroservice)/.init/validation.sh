#!/usr/bin/env bash
set -euo pipefail
# Validation step: start Flask via venv in new session, poll /health, then stop cleanly
WORKSPACE="/home/kavia/workspace/code-generation/mapper-619-93/DeviceConnector(PythonMicroservice)"
LOGDIR="$WORKSPACE/.logs"
mkdir -p "$LOGDIR"
EVIDENCE="$LOGDIR/validation_evidence_$(date +%s).txt"
SERVER_LOG="$LOGDIR/server_$(date +%s).log"
# Prefer runtime envs; do not source profile to avoid side effects
API_BIND_HOST="${API_BIND_HOST:-127.0.0.1}"
API_BIND_PORT="${API_BIND_PORT:-5000}"
cd "$WORKSPACE"
export FLASK_APP=deviceconnector
# Ensure venv python exists
if [ ! -x "$WORKSPACE/.venv/bin/python" ]; then
  echo "ERROR: venv python not found at $WORKSPACE/.venv/bin/python" | tee "$EVIDENCE" >&2
  exit 2
fi
# Start server in a new session to decouple from this shell
setsid "$WORKSPACE/.venv/bin/python" -m flask run --host="$API_BIND_HOST" --port="$API_BIND_PORT" >"$SERVER_LOG" 2>&1 &
SERVER_PID=$!
# Wait for readiness (timeout 30s)
READY=0
for i in {1..15}; do
  sleep 2
  if curl -s -f "http://$API_BIND_HOST:$API_BIND_PORT/health" >/dev/null 2>&1; then
    READY=1; break
  fi
  # if server process died early, break
  if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    break
  fi
done
if [ "$READY" -ne 1 ]; then
  echo "Validation failed: /health not responding on $API_BIND_HOST:$API_BIND_PORT" | tee "$EVIDENCE" >&2
  echo "Server log:" >>"$EVIDENCE"; tail -n 200 "$SERVER_LOG" >>"$EVIDENCE" || true
  # Attempt staged shutdown
  kill -TERM "$SERVER_PID" >/dev/null 2>&1 || true
  sleep 2
  kill -KILL "$SERVER_PID" >/dev/null 2>&1 || true
  echo "validation evidence: $EVIDENCE"
  exit 6
fi
# Successful: record evidence
echo "Validation succeeded: /health returned ok on $API_BIND_HOST:$API_BIND_PORT" | tee "$EVIDENCE"
# Shutdown: TERM, wait up to 10s, then KILL
kill -TERM "$SERVER_PID" >/dev/null 2>&1 || true
for i in {1..10}; do
  if ! kill -0 "$SERVER_PID" >/dev/null 2>&1; then break; fi
  sleep 1
done
kill -KILL "$SERVER_PID" >/dev/null 2>&1 || true
# Append server log tail to evidence
echo "--- server log ---" >>"$EVIDENCE"
tail -n 200 "$SERVER_LOG" >>"$EVIDENCE" || true
echo "validation evidence: $EVIDENCE"
