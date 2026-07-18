#!/usr/bin/env bash

resolve_lab_network() {
  local env_file ip_candidate octet
  script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[1]}")" && pwd)"
  LAB_ROOT="${LAB_ROOT:-$(cd "$script_dir/.." && pwd)}"
  env_file="$LAB_ROOT/.env"

  if [[ -z "${DEMO_BIND_IP:-}" && -f "$env_file" ]]; then
    ip_candidate="$(sed -n 's/^[[:space:]]*DEMO_BIND_IP[[:space:]]*=[[:space:]]*//p' "$env_file" | tail -n 1)"
    ip_candidate="${ip_candidate%\"}"
    ip_candidate="${ip_candidate#\"}"
    DEMO_BIND_IP="$ip_candidate"
  fi

  if [[ ! "${DEMO_BIND_IP:-}" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    printf 'Set DEMO_BIND_IP to this server\047s reachable IPv4 address in %s/.env.\n' "$LAB_ROOT" >&2
    return 1
  fi

  IFS='.' read -r -a ip_octets <<< "$DEMO_BIND_IP"
  for octet in "${ip_octets[@]}"; do
    if ((10#$octet > 255)); then
      printf 'Invalid DEMO_BIND_IP: %s\n' "$DEMO_BIND_IP" >&2
      return 1
    fi
  done

  DEMO_URL="${DEMO_URL:-http://$DEMO_BIND_IP:8080}"
  export LAB_ROOT DEMO_BIND_IP DEMO_URL
}
