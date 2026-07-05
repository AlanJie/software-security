#!/usr/bin/env bash
set -e

export KLEE_CDE="${KLEE_CDE:-/opt/klee-cde-package}"
export KLEE_INCLUDE="${KLEE_INCLUDE:-$KLEE_CDE/cde-root/home/pgbovine/klee/include}"
export PATH="/opt/radamsa-0.3/bin:$KLEE_CDE/bin:$PATH"

cd /work/projects
exec "$@"
