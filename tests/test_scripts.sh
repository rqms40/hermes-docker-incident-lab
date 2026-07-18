#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$file" || fail "expected '$expected' in $file"
}

fake_bin="$test_root/bin"
mkdir -p "$fake_bin"

cat > "$fake_bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "${FAKE_DOCKER_LOG:?}"
case "$*" in
  *"compose -f $LAB_ROOT/compose.yaml ps"*)
    printf 'NAME                STATUS\ndemo-web            exited (1)\n'
    ;;
  *"compose -f $LAB_ROOT/compose.yaml logs --tail 100 demo-web"*)
    printf 'demo-web  | worker terminated unexpectedly during simulated attack\n'
    ;;
  *"inspect demo-web"*)
    printf '{"Name":"demo-web","State":{"Status":"exited","ExitCode":137,"OOMKilled":false,"Health":{"Status":"unhealthy"}}}\n'
    ;;
esac
EOF
chmod +x "$fake_bin/docker"

cat > "$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${FAKE_CURL_LOG:?}"
if grep -Fq -- "compose -f $LAB_ROOT/compose.yaml up -d demo-web" "${FAKE_DOCKER_LOG:?}"; then
  printf '<html>healthy</html>\n'
  exit 0
fi
exit 22
EOF
chmod +x "$fake_bin/curl"

export LAB_ROOT="$project_root"
export REPORT_DIR="$test_root/reports"
export DOCKER_BIN="$fake_bin/docker"
export CURL_BIN="$fake_bin/curl"
export FAKE_DOCKER_LOG="$test_root/docker.log"
export FAKE_CURL_LOG="$test_root/curl.log"
export DEMO_BIND_IP="192.0.2.10"
export DEMO_URL="http://192.0.2.10:8080"

"$project_root/scripts/simulate-attack.sh"
assert_contains "$FAKE_DOCKER_LOG" "compose -f $LAB_ROOT/compose.yaml kill -s SIGKILL demo-web"

"$project_root/scripts/collect-incident.sh"
json_report="$(find "$REPORT_DIR" -name '*.json' -print -quit)"
markdown_report="$(find "$REPORT_DIR" -name '*.md' -print -quit)"
[[ -n "$json_report" && -n "$markdown_report" ]] || fail "incident reports were not created"
assert_contains "$json_report" '"service":"demo-web"'
assert_contains "$json_report" '"scenario":"simulated-forced-termination"'
assert_contains "$markdown_report" 'worker terminated unexpectedly during simulated attack'
assert_contains "$markdown_report" 'http://192.0.2.10:8080'
assert_contains "$FAKE_CURL_LOG" 'http://192.0.2.10:8080'

"$project_root/scripts/recover-demo.sh"
assert_contains "$FAKE_DOCKER_LOG" "compose -f $LAB_ROOT/compose.yaml up -d demo-web"

fake_hermes_log="$test_root/hermes.log"
cat > "$fake_bin/hermes" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "${FAKE_HERMES_LOG:?}"
EOF
chmod +x "$fake_bin/hermes"
export FAKE_HERMES_LOG="$fake_hermes_log"
printf 'test-openrouter-key\n' | HERMES_BIN="$fake_bin/hermes" "$project_root/scripts/configure-openrouter.sh"
assert_contains "$FAKE_HERMES_LOG" "config set OPENROUTER_API_KEY test-openrouter-key"
assert_contains "$FAKE_HERMES_LOG" "config set model openrouter/openai/gpt-oss-20b:free"

printf 'PASS: deterministic lab scripts\n'
