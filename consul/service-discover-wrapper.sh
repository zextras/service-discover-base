#!/bin/bash
# service-discover-wrapper.sh — sd_notify wrapper for consul connect envoy sidecars
#
# Starts consul connect envoy, captures stderr to detect the admin address,
# polls /ready, then sends READY=1 via systemd-notify.
#
# Usage: service-discover-wrapper.sh [consul connect envoy args...]
# Example: service-discover-wrapper.sh -token-file /etc/carbonio/.../token -admin-bind localhost:0 -sidecar-for carbonio-mta

set -euo pipefail

READY_TIMEOUT="${ENVOY_READY_TIMEOUT:-30}"

# Create a pipe to capture envoy's stderr while still forwarding it to journald
ADMIN_FILE=$(mktemp)
trap 'rm -f "$ADMIN_FILE"' EXIT

# Start consul connect envoy in background.
# Tee stderr so we can scan for the admin address line.
/usr/bin/consul connect envoy "$@" 2> >(tee >(
  # Scan stderr for the admin address line and write the port
  while IFS= read -r line; do
    echo "$line" >&2
    if [[ "$line" == *"admin address:"* ]]; then
      # Extract port from "admin address: 127.0.0.1:PORT"
      port="${line##*:}"
      echo "$port" >"$ADMIN_FILE"
    fi
  done
) >/dev/null) &
ENVOY_PID=$!

# Wait for the admin address to appear in envoy's output
admin_port=""
elapsed=0
while [ -z "$admin_port" ] && [ "$elapsed" -lt "$READY_TIMEOUT" ]; do
  sleep 1
  elapsed=$((elapsed + 1))
  if [ -s "$ADMIN_FILE" ]; then
    admin_port=$(cat "$ADMIN_FILE")
  fi
done

if ! kill -0 "$ENVOY_PID" 2>/dev/null; then
  echo "consul-envoy-wrapper: envoy exited prematurely" >&2
  wait "$ENVOY_PID"
  exit $?
fi

if [ -z "$admin_port" ]; then
  echo "consul-envoy-wrapper: could not detect admin port after ${READY_TIMEOUT}s" >&2
  systemd-notify --ready --status="envoy started (admin port unknown)" || true
else
  # Poll /ready endpoint until envoy reports LIVE
  ready=false
  while [ "$elapsed" -lt "$READY_TIMEOUT" ]; do
    if ! kill -0 "$ENVOY_PID" 2>/dev/null; then
      echo "consul-envoy-wrapper: envoy exited during readiness check" >&2
      wait "$ENVOY_PID"
      exit $?
    fi
    if curl -sf "http://127.0.0.1:${admin_port}/ready" >/dev/null 2>&1; then
      systemd-notify --ready --status="envoy sidecar ready (admin :${admin_port})" || true
      ready=true
      break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done

  if [ "$ready" = false ]; then
    echo "consul-envoy-wrapper: /ready timeout after ${READY_TIMEOUT}s" >&2
    systemd-notify --ready --status="envoy started (ready timeout)" || true
  fi
fi

# Wait for envoy to exit
wait $ENVOY_PID
