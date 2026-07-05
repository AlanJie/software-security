#!/usr/bin/env bash
set -euo pipefail

PIDFILE="${BADSTORE_PIDFILE:-/tmp/badstore-qemu.pid}"

if ! sudo test -f "$PIDFILE"; then
  echo "No pidfile found: $PIDFILE"
  exit 0
fi

pid="$(sudo cat "$PIDFILE" 2>/dev/null || true)"
if [[ -z "${pid:-}" ]]; then
  echo "Empty pidfile: $PIDFILE"
  sudo rm -f "$PIDFILE"
  exit 0
fi

if sudo kill -0 "$pid" 2>/dev/null; then
  sudo kill "$pid"
  echo "Stopped BadStore QEMU, pid=$pid"
else
  echo "Process is not running, pid=$pid"
fi

sudo rm -f "$PIDFILE"
