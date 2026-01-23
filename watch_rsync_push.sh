#!/usr/bin/env bash
# Watch a local directory and rsync changed files to a remote directory.
# Supports optional SSH jump host (ProxyJump).
#
# Usage:
#   watch_rsync_push [options] <local_dir> <user@host:remote_dir>
#
# Options:
#   -J <jump_host>   SSH jump host (ProxyJump), e.g. user@jump
#   -p <port>        SSH port (default: 22)
#   -e <events>      inotify events (default: close_write)
#   -n, --dry-run    Dry-run (print rsync command, don't execute)
#   -v               Verbose rsync output (adds -v to rsync)
#   -h               Show this help

set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage: watch_rsync_push [options] <local_dir> <user@host:remote_dir>

Options:
  -J <jump_host>   SSH jump host (ProxyJump), e.g. user@jump
  -p <port>        SSH port (default: 22)
  -e <events>      inotify events (default: close_write)
  -n, --dry-run    Dry-run (print rsync command, don't execute)
  -v               Verbose rsync output (adds -v to rsync)
  -h               Show this help

Examples:
  watch_rsync_push -n ./sunbeam-python/sunbeam ubuntu@bastion:/home/ubuntu/squashfs-root/lib/python3.12/site-packages/
  watch_rsync_push -J ubuntu@jumpbox ./src ubuntu@app01:/opt/app/
EOF
}

# Default values
port=22
events="close_write"
dry_run=0
verbose=0
jump_host=""

# Support long option --dry-run by translating it to -n for getopts
ARGS=()
while (($#)); do
  case "$1" in
    --dry-run) ARGS+=("-n"); shift ;;
    --) ARGS+=("--"); shift; ARGS+=("$@"); break ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
set -- "${ARGS[@]}"

while getopts ":J:p:e:nvh" opt; do
  case "$opt" in
    J) jump_host="$OPTARG" ;;
    p) port="$OPTARG" ;;
    e) events="$OPTARG" ;;
    n) dry_run=1 ;;
    v) verbose=1 ;;
    h) usage; exit 0 ;;
    :) echo "Missing argument for -$OPTARG" >&2; exit 2 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

if [[ $# -ne 2 ]]; then
  echo "watch_rsync_push: missing required args." >&2
  echo "Usage: watch_rsync_push [options] <local_dir> <user@host:remote_dir>" >&2
  exit 2
fi

local_dir="$1"
remote_spec="$2"

# Check dependencies
command -v inotifywait >/dev/null 2>&1 || { echo "inotifywait is not found (install inotify-tools)" >&2; exit 2; }
command -v rsync >/dev/null 2>&1 || { echo "rsync is not found" >&2; exit 2; }

if [[ ! -d "$local_dir" ]]; then
  echo "local_dir does not exist or is not a directory: $local_dir" >&2
  exit 1
fi

# Normalize directory paths
local_abs=$(cd "$local_dir" && pwd -P)
local_base=$(basename "$local_abs")

# Build SSH command
ssh_cmd="ssh -p $port"
if [[ -n "$jump_host" ]]; then
  ssh_cmd+=" -J $jump_host"
fi
ssh_cmd+=" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=QUIET"

# Build rsync flags
rsync_flags=(-a -R)
if (( verbose )); then
  rsync_flags+=("-v")
  rsync_flags+=("--progress")
fi

echo "watch_rsync_push: Watching $local_abs -> $remote_spec" >&2
if [[ -n "$jump_host" ]]; then
  echo "watch_rsync_push: Using SSH jump host: $jump_host" >&2
fi

# cleanup on exit
cleanup() {
  echo "watch_rsync_push: Exiting..." >&2
  exit 0
}
trap cleanup INT TERM

# Run inotifywait and process events
inotifywait -mr --timefmt '%Y-%m-%dT%H:%M:%S' --format '%T %w %f' -e "$events" "$local_abs" |
while read -r timestamp dir file; do
  # Strip the watched absolute prefix + trailing slash
  changed_abs="${dir}${file}"
  changed_rel="${changed_abs#$local_abs/}"

  # Run from the local base directory so --relative (-R) option for rsync works
  pushd "$local_abs" >/dev/null || exit 1

  if (( dry_run )); then
    echo "DRY-RUN: rsync ${rsync_flags[*]} -e \"$ssh_cmd\" \"$changed_rel\" \"$remote_spec\"" >&2
    popd >/dev/null || exit 1
    continue
  fi

  rsync "${rsync_flags[@]}" -e "$ssh_cmd" "$changed_rel" "$remote_spec" && \
    echo "${timestamp} | ${changed_rel}" >&2

  popd >/dev/null || exit 1
done
