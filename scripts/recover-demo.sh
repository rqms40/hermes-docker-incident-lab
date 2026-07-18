#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lab-common.sh"
resolve_lab_network
DOCKER_BIN="${DOCKER_BIN:-docker}"
CURL_BIN="${CURL_BIN:-curl}"

"$DOCKER_BIN" compose -f "$LAB_ROOT/compose.yaml" up -d demo-web
printf 'Recovery command started only demo-web. Waiting briefly for the HTTP check.\n'
for _ in 1 2 3 4 5; do
  if "$CURL_BIN" --fail --silent --show-error --max-time 5 "$DEMO_URL" >/dev/null 2>&1; then
    printf 'RECOVERED: %s is healthy\n' "$DEMO_URL"
    exit 0
  fi
  sleep 2
done

printf 'RECOVERY_FAILED: demo-web was started but %s is still unavailable\n' "$DEMO_URL" >&2
exit 1
