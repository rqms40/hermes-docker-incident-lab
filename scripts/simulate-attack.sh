#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lab-common.sh"
resolve_lab_network
DOCKER_BIN="${DOCKER_BIN:-docker}"

printf 'Safe attack simulation: abruptly terminating only demo-web with SIGKILL.\n'
"$DOCKER_BIN" compose -f "$LAB_ROOT/compose.yaml" kill -s SIGKILL demo-web
printf 'SIMULATED_ATTACK: demo-web was force-terminated. No external host or network was targeted.\n'
