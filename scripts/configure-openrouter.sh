#!/usr/bin/env bash
set -euo pipefail

HERMES_BIN="${HERMES_BIN:-hermes}"
default_model="${HERMES_FREE_MODEL:-openai/gpt-oss-20b:free}"

command -v "$HERMES_BIN" >/dev/null 2>&1 || {
  printf 'Hermes is not available. First run: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash\n' >&2
  exit 1
}

printf 'Paste your OpenRouter API key (input is hidden): '
read -r -s openrouter_key
printf '\n'
[[ -n "$openrouter_key" ]] || { printf 'No API key supplied.\n' >&2; exit 1; }

"$HERMES_BIN" config set OPENROUTER_API_KEY "$openrouter_key"
"$HERMES_BIN" config set model "openrouter/$default_model"
printf 'Configured Hermes model: openrouter/%s\n' "$default_model"
printf 'To change models later, run: hermes model\n'
