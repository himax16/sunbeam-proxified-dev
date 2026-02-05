#!/usr/bin/env bash
set -euo pipefail

# Read input values from stdin
INPUT="$(cat)"
NCORE_MAIN=$(echo "$INPUT" | sed -n 's/.*"ncore_main"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' || true)
NCORE_CHILD=$(echo "$INPUT" | sed -n 's/.*"ncore_child"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' || true)
NB_VM=$(echo "$INPUT" | sed -n 's/.*"nb_vm"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' || true)

# Default values
if [ -z "$NB_VM" ]; then
  NB_VM=1
fi
if [ -z "$NCORE_MAIN" ]; then
  NCORE_MAIN=1
fi
if [ -z "$NCORE_CHILD" ]; then
  NCORE_CHILD=1
fi

# Calculate total requested CPUs
if [ "$NB_VM" -le 1 ]; then
  TOTAL_REQUESTED=$NCORE_MAIN
else
  CHILD_COUNT=$((NB_VM - 1))
  TOTAL_REQUESTED=$((NCORE_MAIN + NCORE_CHILD * CHILD_COUNT))
fi

# Host available CPUs
HOST_CPUS=$(nproc)

if [ "$TOTAL_REQUESTED" -gt "$HOST_CPUS" ]; then
  echo "ERROR: requested ${TOTAL_REQUESTED} CPUs exceed host CPUs (${HOST_CPUS})" >&2
  printf '{"error":"requested %d > host %d", "requested_cpus":%d, "host_cpus":%d}\n' "$TOTAL_REQUESTED" "$HOST_CPUS" "$TOTAL_REQUESTED" "$HOST_CPUS" >&2
  exit 1
fi

printf '{"requested_cpus": %d, "available_cpus": %d}\n' "$TOTAL_REQUESTED" "$HOST_CPUS"
