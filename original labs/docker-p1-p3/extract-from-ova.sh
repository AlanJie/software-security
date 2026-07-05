#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
original_labs_dir="$(cd "$script_dir/.." && pwd)"
ova_path="${1:-$original_labs_dir/mooc-vm3.ova}"
out_dir="${2:-$script_dir/.extracted}"

if [[ ! -f "$ova_path" ]]; then
  echo "OVA not found: $ova_path" >&2
  exit 1
fi

if [[ -e "$out_dir" ]]; then
  echo "Output already exists: $out_dir" >&2
  echo "Move it away or pass a different output directory." >&2
  exit 1
fi

for cmd in tar virt-copy-out virt-filesystems; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing command: $cmd" >&2
    echo "Install libguestfs-tools first, then rerun this script." >&2
    exit 1
  fi
done

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "[1/4] Extracting VMDK from OVA..."
tar -C "$tmp_dir" -xf "$ova_path"
vmdk_path="$(find "$tmp_dir" -maxdepth 1 -type f -name '*.vmdk' -print -quit)"

if [[ -z "$vmdk_path" ]]; then
  echo "No VMDK found inside OVA: $ova_path" >&2
  exit 1
fi

echo "[2/4] Detecting Linux root filesystem..."
root_dev="$(virt-filesystems -a "$vmdk_path" --filesystems --long | awk '$3 ~ /^ext[234]$/ { print $1; exit }')"

if [[ -z "$root_dev" ]]; then
  echo "Could not find an ext root filesystem in $vmdk_path" >&2
  exit 1
fi

mkdir -p "$out_dir"

echo "[3/4] Copying Project 1/3 and tools from $root_dev..."
virt-copy-out -a "$vmdk_path" -m "$root_dev" /home/seed/projects "$out_dir"
virt-copy-out -a "$vmdk_path" -m "$root_dev" /home/seed/klee-cde-package "$out_dir"
virt-copy-out -a "$vmdk_path" -m "$root_dev" /home/seed/radamsa-0.3 "$out_dir"

echo "[4/4] Done."
echo "Extracted assets:"
du -sh "$out_dir"/*
