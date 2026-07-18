#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lab-common.sh"
resolve_lab_network
DOCKER_BIN="${DOCKER_BIN:-docker}"

"$DOCKER_BIN" compose -f "$LAB_ROOT/compose.yaml" up -d --build demo-web
printf 'Demo started. Open %s\n' "$DEMO_URL"
