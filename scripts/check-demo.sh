#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lab-common.sh"
resolve_lab_network
CURL_BIN="${CURL_BIN:-curl}"

"$CURL_BIN" --fail --silent --show-error --max-time 5 "$DEMO_URL" >/dev/null
printf 'HEALTHY: %s responded successfully\n' "$DEMO_URL"
