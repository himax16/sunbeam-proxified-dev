#!/usr/bin/env bash
set -euo pipefail

# Read input values from stdin
INPUT="$(cat)"
MEMORY_MAIN=$(echo "$INPUT" | sed -n 's/.*"memory_main"[[:space:]]*:[[:space:]]*"\([^\"]*\)".*/\1/p' || true)
MEMORY_CHILD=$(echo "$INPUT" | sed -n 's/.*"memory_child"[[:space:]]*:[[:space:]]*"\([^\"]*\)".*/\1/p' || true)
NB_VM=$(echo "$INPUT" | sed -n 's/.*"nb_vm"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' || true)

# Get host total memory in KiB (from /proc/meminfo)
HOST_KIB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)

# Convert values to KiB
to_kib() {
  s="$1"
  if [ -z "$s" ]; then
    echo 0
    return
  fi
  # Extract numeric part and unit (if any)
  num=$(echo "$s" | sed -n 's/^\([0-9][0-9]*\).*$/\1/p' || true)
  unit=$(echo "$s" | sed -n 's/^[0-9][0-9]*[[:space:]]*\(.*\)$/\1/p' || true)
  unit_lower=$(echo "$unit" | tr '[:upper:]' '[:lower:]')

  case "$unit_lower" in
    *tib|*tb|t)
      kib=$((num * 1024 * 1024 * 1024))
      ;;
    *gib|*gb|g)
      kib=$((num * 1024 * 1024))
      ;;
    *mib|*mb|m)
      kib=$((num * 1024))
      ;;
    *kib|*kb|k)
      kib=$((num))
      ;;
    *)
      # default: assume MiB if unit not provided
      kib=$((num * 1024))
      ;;
  esac
  echo "$kib"
}

MAIN_KIB=$(to_kib "$MEMORY_MAIN")
CHILD_KIB=$(to_kib "$MEMORY_CHILD")

# Default NB_VM to 1 if not provided
if [ -z "$NB_VM" ]; then
  NB_VM=1
fi

# Calculate total requested memory in KiB
if [ "$NB_VM" -le 1 ]; then
  TOTAL_REQUESTED_KIB=$MAIN_KIB
else
  CHILD_COUNT=$((NB_VM - 1))
  TOTAL_REQUESTED_KIB=$((MAIN_KIB + CHILD_KIB * CHILD_COUNT))
fi


if awk -v r="$TOTAL_REQUESTED_KIB" -v h="$HOST_KIB" 'BEGIN{exit !(r>h)}'; then
  # Convert to GiB for human-readable error messages
  TOTAL_REQUESTED_GIB=$(awk -v kib="$TOTAL_REQUESTED_KIB" 'BEGIN{printf("%.2f", kib/1024/1024)}')
  HOST_GIB=$(awk -v kib="$HOST_KIB" 'BEGIN{printf("%.2f", kib/1024/1024)}')

  echo "ERROR: requested ${TOTAL_REQUESTED_GIB} GiB memory exceeds host available ${HOST_GIB} GiB" >&2
  printf '{"error":"requested_memory %dKiB > host %dKiB", "requested_kib":"%d", "available_kib":"%d"}\n' "$TOTAL_REQUESTED_KIB" "$HOST_KIB" "$TOTAL_REQUESTED_KIB" "$HOST_KIB" >&2
  exit 1
fi

printf '{"requested_kib":"%d", "available_kib":"%d"}\n' "$TOTAL_REQUESTED_KIB" "$HOST_KIB"
