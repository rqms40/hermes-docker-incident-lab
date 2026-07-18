#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/lab-common.sh"
resolve_lab_network
REPORT_DIR="${REPORT_DIR:-$LAB_ROOT/reports}"
DOCKER_BIN="${DOCKER_BIN:-docker}"
CURL_BIN="${CURL_BIN:-curl}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$REPORT_DIR"

compose_ps="$("$DOCKER_BIN" compose -f "$LAB_ROOT/compose.yaml" ps 2>&1 || true)"
inspect="$("$DOCKER_BIN" inspect demo-web 2>&1 || true)"
logs="$("$DOCKER_BIN" compose -f "$LAB_ROOT/compose.yaml" logs --tail 100 demo-web 2>&1 || true)"
if "$CURL_BIN" --fail --silent --show-error --max-time 5 "$DEMO_URL" >/dev/null 2>&1; then
  http_healthy=true
  http_result="HTTP check succeeded"
else
  http_healthy=false
  http_result="HTTP check failed"
fi

json_string() {
  python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))'
}

json_report="$REPORT_DIR/incident-$timestamp.json"
markdown_report="$REPORT_DIR/incident-$timestamp.md"
{
  printf '{\n'
  printf '  "service":"demo-web",\n'
  printf '  "scenario":"simulated-forced-termination",\n'
  printf '  "demo_url":%s,\n' "$(printf '%s' "$DEMO_URL" | json_string)"
  printf '  "collected_at_utc":"%s",\n' "$timestamp"
  printf '  "http_healthy":%s,\n' "$http_healthy"
  printf '  "http_result":%s,\n' "$(printf '%s' "$http_result" | json_string)"
  printf '  "compose_ps":%s,\n' "$(printf '%s' "$compose_ps" | json_string)"
  printf '  "inspect":%s,\n' "$(printf '%s' "$inspect" | json_string)"
  printf '  "logs":%s\n' "$(printf '%s' "$logs" | json_string)"
  printf '}\n'
} > "$json_report"

cat > "$markdown_report" <<EOF
# Hermes Docker Lab Incident

- Service: \`demo-web\`
- Scenario: safe simulated forced termination
- URL: \`$DEMO_URL\`
- Collected (UTC): \`$timestamp\`
- HTTP result: **$http_result**

## Docker Compose state

\`\`\`text
$compose_ps
\`\`\`

## Container inspect

\`\`\`text
$inspect
\`\`\`

## Last 100 service log lines

\`\`\`text
$logs
\`\`\`
EOF

printf 'INCIDENT_REPORT_JSON=%s\n' "$json_report"
printf 'INCIDENT_REPORT_MARKDOWN=%s\n' "$markdown_report"
