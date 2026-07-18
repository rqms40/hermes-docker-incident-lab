# Hermes Docker Incident-Response Seminar Starter Kit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a portable, copy-pasteable Hermes seminar lab that diagnoses and safely recovers a Docker website force-terminated by a controlled attack simulation through Telegram.

**Architecture:** Docker Compose runs one static `demo-web` container on a specific server IPv4 address. Shell scripts own deterministic lifecycle and evidence collection; Hermes receives narrowly scoped Telegram instructions to inspect those artifacts and runs recovery only after a user approval phrase. The repository has no secrets and binds only to the address selected in `.env`.

**Tech Stack:** Bash, Docker Compose, static HTML served by Nginx, Hermes Agent, OpenRouter, Telegram.

## Global Constraints

- Supported host: Ubuntu/Debian-compatible Linux with Docker Engine and Compose.
- Hermes must be installed with `curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash`.
- Hermes CLI prerequisites: Git, curl, and xz-utils; do not require Hermes Desktop build dependencies.
- Default model: `openai/gpt-oss-20b:free`; document replacing it with another OpenRouter `:free` model.
- The safe attack simulation sends `SIGKILL` only to `demo-web`; it is not a real exploit or network attack.
- No Caddy, dashboard, VM setup, reverse proxy, or unattended repair.

---

### Task 1: Deterministic lab scripts

**Files:**
- Create: `scripts/start-demo.sh`, `scripts/check-demo.sh`, `scripts/simulate-attack.sh`, `scripts/collect-incident.sh`, `scripts/recover-demo.sh`
- Create: `tests/test_scripts.sh`

**Interfaces:**
- Consumes: optional `LAB_ROOT`, `REPORT_DIR`, `DOCKER_BIN`, and `CURL_BIN` environment variables.
- Produces: a local website state and timestamped Markdown/JSON incident artifacts.

- [x] Write failing fake-command tests for safe stop, evidence capture, scoped recovery, and OpenRouter configuration.
- [x] Run the tests and confirm they fail because scripts are absent.
- [x] Implement scripts using `docker compose -f "$LAB_ROOT/compose.yaml"` and the specific server-IP URL resolved from `.env`.
- [x] Run tests and shell syntax checks.

### Task 2: Docker demo and setup assets

**Files:**
- Create: `compose.yaml`, `app/Dockerfile`, `app/index.html`, `.env.example`, `.gitignore`
- Create: `scripts/configure-openrouter.sh`, `templates/SOUL.md`, `templates/USER.md`, `templates/AGENTS.md`, `templates/config.yaml`

- [x] Provide a single Nginx website with a Docker health check.
- [x] Keep all credentials as examples or interactive terminal input; never commit a real key.
- [x] Configure Telegram allowlist, manual approval, and cron deny defaults.
- [x] Validate Compose structure without starting a real service; Docker CLI validation is deferred because Docker is unavailable in this workspace.

### Task 3: Seminar guide and final verification

**Files:**
- Create: `README.md`, `prompts/telegram-incident-response.md`

- [x] Document exact prerequisite verification, Docker setup, official Hermes installation, OpenRouter setup, Telegram setup, lab execution, incident investigation, approval, and recovery.
- [x] Explain the installer-managed dependencies and why Docker is a separate demo requirement.
- [x] Add expected outputs, troubleshooting, and Git secret-safety checks.
- [x] Run the complete automated test harness, Bash syntax checks, Compose-structure validation, secret scan, and repository status review.
