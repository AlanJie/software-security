#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

ISO="${BADSTORE_ISO:-BadStore_212.iso}"
HTTP_PORT="${BADSTORE_HTTP_PORT:-80}"
HTTPS_PORT="${BADSTORE_HTTPS_PORT:-443}"
PIDFILE="${BADSTORE_PIDFILE:-/tmp/badstore-qemu.pid}"
SERIAL_LOG="${BADSTORE_SERIAL_LOG:-/tmp/badstore-qemu.serial.log}"
MONITOR="${BADSTORE_MONITOR:-/tmp/badstore-qemu.monitor}"

if [[ ! -f "$ISO" ]]; then
  echo "Missing ISO: $ISO" >&2
  exit 1
fi

if sudo test -f "$PIDFILE"; then
  pid="$(sudo cat "$PIDFILE" 2>/dev/null || true)"
  if [[ -n "${pid:-}" ]] && sudo kill -0 "$pid" 2>/dev/null; then
    echo "BadStore QEMU is already running, pid=$pid"
    exit 0
  fi
fi

if ! grep -qE '(^|[[:space:]])www\.badstore\.net([[:space:]]|$)' /etc/hosts; then
  sudo cp /etc/hosts /etc/hosts.codex-badstore-backup
  printf '\n127.0.0.1 www.badstore.net\n' | sudo tee -a /etc/hosts >/dev/null
fi

accel_args=()
if [[ -e /dev/kvm ]]; then
  accel_args=(-enable-kvm)
fi

sudo rm -f "$PIDFILE" "$SERIAL_LOG" "$MONITOR"

sudo qemu-system-i386 \
  -name badstore-project2 \
  -m 512 \
  "${accel_args[@]}" \
  -cdrom "$ISO" \
  -boot d \
  -netdev "user,id=net0,hostfwd=tcp:127.0.0.1:${HTTP_PORT}-:80,hostfwd=tcp:127.0.0.1:${HTTPS_PORT}-:443" \
  -device rtl8139,netdev=net0 \
  -display none \
  -serial "file:${SERIAL_LOG}" \
  -monitor "unix:${MONITOR},server,nowait" \
  -pidfile "$PIDFILE" \
  -daemonize

echo "Started BadStore QEMU, pid=$(sudo cat "$PIDFILE")"
echo "URL: http://www.badstore.net/"
echo "Verify: curl --noproxy '*' http://www.badstore.net/"
