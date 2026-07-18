# Hermes Docker Incident-Response Lab

A portable Hermes Agent seminar lab. You will run a tiny Docker website on your server IP, trigger a controlled attack simulation that force-terminates it, ask Hermes on Telegram to investigate, and explicitly approve its recovery.

This is a **safe attack simulation**, not a real exploit. It sends `SIGKILL` only to the lab's `demo-web` container so you can investigate an abrupt service failure. It never targets another host, scans a network, or performs unattended repair.

## What you will build

```text
┌────────────────────────────────────────────────────────────────┐
│ You: Telegram owner                                            │
│   │ ask Hermes to investigate                                  │
│   ▼                                                            │
│ Hermes Agent                                                   │
│   │ reads Docker status, inspect data, and the last 100 logs   │
│   │ writes an incident report                                  │
│   ▼                                                            │
│ demo-web at http://SERVER_IP:8080                              │
│   │ requires your explicit approval                            │
│   ▼                                                            │
│ Scoped recovery script verifies the server-IP URL              │
└────────────────────────────────────────────────────────────────┘
```

There is no dashboard, Caddy, reverse proxy, VM provisioning, or automatic repair in this kit. Docker publishes the website only on the specific IPv4 address configured in `.env`.

## Core Hermes concepts: identity, user, project, and memory

Hermes receives different kinds of context for different reasons. Keeping them separate makes an agent easier to understand, safer to operate, and less likely to follow an old project rule in the wrong place.

```text
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│  SOUL.md             │  │  USER.md             │  │  AGENTS.md           │
│  Who Hermes is       │  │  Who Hermes serves   │  │  How this project    │
│  Global identity     │  │  User preferences    │  │  must be operated    │
└──────────────────────┘  └──────────────────────┘  └──────────────────────┘
           │                         │                         │
           └───────────┬─────────────┴─────────────┬───────────┘
                       ▼                           ▼
                  Hermes Agent                This lab only
```

| File or concept | What it means | Correct location in this lab | What belongs there | What does **not** belong there |
| --- | --- | --- | --- | --- |
| `SOUL.md` — **identity** | Hermes' durable identity, tone, and communication defaults. This is the official file behind the “IDENTITY.md / Who it is” idea in the visual. | `~/.hermes/SOUL.md` | “Be concise, report uncertainty, inspect before acting.” | Temporary incident details, repository paths, API keys, or Telegram tokens. |
| `USER.md` — **user profile** | A small, persistent profile of the person Hermes serves: preferences, role, timezone, and reporting style. | `~/.hermes/memories/USER.md` | “The owner prefers concise incident reports with evidence first.” | Authentication decisions, secrets, passwords, or a list of commands Hermes may run. |
| `AGENTS.md` — **project instructions** | The operational manual for one repository: boundaries, architecture, scripts, commands, and safety rules. | `./AGENTS.md` in this repository | “Only inspect `demo-web`; recovery must use `scripts/recover-demo.sh` after approval.” | A global persona or rules that should apply to every unrelated project. |
| `MEMORY.md` — **learned facts** | Bounded agent memory for durable facts about the environment and workflow; Hermes manages it between sessions. | `~/.hermes/memories/MEMORY.md` | “The demo site uses Docker Compose and is checked through the server-IP URL.” | Large logs, one-time errors, secrets, or anything that should expire quickly. |

### The important distinction: identity is not authorization

`SOUL.md` can tell Hermes to be careful, but it does not grant access. Authorization comes from the configuration around the agent: Telegram owner allowlists, the available tools, the terminal working directory, Docker permissions, and manual approval settings. This lab uses all of those controls together.

### Why there is no `IDENTITY.md` template

The visual's **IDENTITY.md** label is a useful way to teach the idea of “who the agent is.” Hermes’ documented auto-loaded identity file is `SOUL.md`, stored in `HERMES_HOME` (normally `~/.hermes/SOUL.md`). Creating a separate `IDENTITY.md` would not make Hermes load it automatically. Put identity and tone in `SOUL.md`; put lab-specific operating rules in `AGENTS.md`.

### A simple rule for deciding where a sentence belongs

- “How should Hermes sound and reason everywhere?” → `SOUL.md`
- “What does this owner prefer?” → `USER.md`
- “What may Hermes do in this repository?” → `AGENTS.md`
- “What durable fact did Hermes learn?” → `MEMORY.md`

## Other practical Hermes applications

This lab demonstrates a useful pattern: **observe first, report evidence, and require human approval before an action changes a system**. The same pattern can support other practical workflows once their tools, files, and credentials are deliberately scoped.

| Application | What Hermes can do | Safe starting point |
| --- | --- | --- |
| Docker and service incident assistant | Check an allowlisted service, collect status and recent logs, then send a concise Telegram incident report. | Read-only diagnostics; use one dedicated recovery script and require an explicit approval phrase. |
| Daily operations briefing | Gather selected system checks, calendar items, project notes, or trusted sources and send a short owner briefing. | Send only useful summaries; use `[SILENT]` when no attention is needed. |
| Repository and CI helper | Inspect an allowlisted Git repository, open issues, and CI results; summarize findings or prepare a proposed change. | Review and draft first; a human reviews diffs and performs merge or push actions. |
| Research and content workflow | Monitor a defined set of sources, organize notes, and prepare a source-linked draft for a post, report, or newsletter. | Keep publication separate from drafting; require approval before anything is sent or published. |
| Personal knowledge capture | Turn Telegram text or voice notes into organized local Markdown notes and retrieve relevant prior context. | Keep notes in a private, access-controlled workspace; avoid placing credentials or sensitive personal data in prompts. |
| Home or office automation | Read state from specifically connected devices and prepare a requested action, such as an alert or a scheduled routine. | Use an allowlist of devices and commands; require confirmation for actions with physical or financial impact. |

Do not give an agent blanket shell, network, repository, or messaging access merely for convenience. Start with one narrow workflow, grant only the tools it needs, keep an owner allowlist for Telegram, and add approval gates for every external or destructive action.

## 0. Host requirements

Use a Linux shell on Ubuntu 22.04/24.04, Debian, a VirtualBox Linux VM, a local Linux machine, or a Linux VPS. Select an IPv4 address you can reach from your browser. Prefer a private LAN, VPN, host-only, or internal VPS address. If you intentionally use a public VPS address, restrict TCP port `8080` to your allowed source IPs with the provider firewall.

### Hermes CLI prerequisites

The official Hermes installer needs:

- Git;
- on Linux, `curl` and `xz-utils`.

Verify or install them:

```bash
sudo apt update
sudo apt install -y git curl xz-utils ca-certificates
git --version
curl --version
xz --version
```

The Hermes installer handles the remaining CLI dependencies itself: `uv`, Python 3.11, Node.js v22, ripgrep, and ffmpeg. This lab does **not** use Hermes Desktop, so do not install `g++` or `build-essential` for Hermes Desktop.

### Docker requirement for the demo website

Docker Engine and Docker Compose are separate requirements for the demo website; Hermes does not install them. For a disposable seminar VM, Docker's official convenience installer is the shortest route:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker "$USER"
newgrp docker
docker --version
docker compose version
```

For a long-lived production system, follow Docker's distribution-specific Engine installation documentation instead of the convenience installer.

## 1. Get the lab

Clone or copy this repository onto the Linux machine, then enter it:

```bash
git clone https://github.com/rqms40/hermes-docker-incident-lab.git
cd hermes-docker-incident-lab
```

If you received the files directly rather than cloning, just `cd` into the project directory.

Make scripts executable once:

```bash
chmod +x scripts/*.sh tests/test_scripts.sh
```

Configure the server address before starting Docker:

```bash
hostname -I
cp .env.example .env
nano .env
```

Replace `192.168.1.50` with the reachable IPv4 address shown by `hostname -I`. Keep only one line in the file:

```dotenv
DEMO_BIND_IP=192.168.1.50
```

Validate the resulting Docker configuration:

```bash
docker compose config --quiet
```

Do not put OpenRouter or Telegram credentials in this project `.env`; Hermes stores them separately.

## 2. Install Hermes Agent

Run the official Hermes installer exactly as published:

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
source ~/.bashrc
hermes --version
hermes doctor
```

Expected result: `hermes --version` prints a version and `hermes doctor` reports the environment checks. If `hermes` is not found, close/reopen the terminal or run `source ~/.bashrc` again.

The official installer documentation is the source of truth for platform-specific troubleshooting: <https://hermes-agent.nousresearch.com/docs/getting-started/installation>.

### Apply the lab safety context

Copy the identity and operating-rule templates without overwriting an existing file, then apply the safety settings through Hermes:

```bash
mkdir -p ~/.hermes/memories
cp -n templates/SOUL.md ~/.hermes/SOUL.md
cp -n templates/USER.md ~/.hermes/memories/USER.md
cp -n templates/AGENTS.md ./AGENTS.md
hermes config set approvals.mode manual
hermes config set approvals.cron_mode deny
hermes config set terminal.backend local
hermes config set terminal.cwd "$(pwd)"
```

`terminal.cwd` is important for Telegram: gateway requests must start inside this lab repository so Hermes can find only the documented scripts and reports. `templates/config.yaml` remains a readable reference; the commands above avoid overwriting an existing Hermes configuration.

## 3. Configure OpenRouter with a free model

1. Create an OpenRouter account and API key at <https://openrouter.ai/keys>.
2. Run the local configuration helper:

   ```bash
   ./scripts/configure-openrouter.sh
   ```

3. Paste the key only when the script asks. Input is hidden. The helper stores it in Hermes' local configuration, not this repository.

The starter model is:

```text
openai/gpt-oss-20b:free
```

OpenRouter's free-model availability can change. To choose another current free model, open <https://openrouter.ai/models>, select a model ending in `:free`, then run:

```bash
hermes model
```

Choose OpenRouter and paste the current model ID when the wizard asks.

## 4. Connect Telegram securely

1. In Telegram, open `@BotFather`, send `/newbot`, and save the token privately.
2. Start a direct message with your new bot and send it one message such as `hello`.
3. Find your numeric Telegram user ID with a bot such as `@userinfobot`; save the number privately.
4. Run Hermes' supported interactive messaging setup:

   ```bash
   hermes gateway setup
   ```

5. Select Telegram. Enter the BotFather token and configure **only your numeric user ID** as the allowed user. Do not enable an allow-all option. Do not use this seminar bot in a public group.
6. Let the setup wizard start the gateway when it offers. Send your bot a direct message and confirm Hermes replies.

Hermes' messaging documentation describes the gateway and allowlist behavior: <https://hermes-agent.nousresearch.com/docs/user-guide/messaging>.

## 5. Start and verify the demo website

Start only the local service:

```bash
./scripts/start-demo.sh
./scripts/check-demo.sh
docker compose ps
```

The start script prints the exact URL. Open `http://YOUR_SERVER_IP:8080` from a machine that can reach the configured address. You should see **Hermes Docker Incident Lab** and a green `HEALTHY` marker.

## 6. Run the safe attack simulation

Run:

```bash
./scripts/simulate-attack.sh
./scripts/check-demo.sh
```

The simulation uses Docker to deliver `SIGKILL` to `demo-web`, producing an abrupt termination similar to the visible effect of a denial-of-service or malicious process kill. It does not exploit Nginx, generate traffic, or touch another service.

The second command is expected to fail. Confirm the container stopped and inspect its exit evidence:

```bash
docker compose ps
docker inspect demo-web --format 'status={{.State.Status}} exit={{.State.ExitCode}} oom={{.State.OOMKilled}} finished={{.State.FinishedAt}}'
docker compose logs --tail 100 demo-web
```

Expected evidence includes `status=exited` and commonly `exit=137`, showing forced termination. Only this lab container is targeted.

## 7. Ask Hermes to investigate through Telegram

Open [prompts/telegram-incident-response.md](prompts/telegram-incident-response.md) and send the first message to your bot. Hermes should:

1. run `scripts/collect-incident.sh`;
2. inspect the generated Markdown/JSON evidence in `reports/`;
3. report the unavailable website, the stopped `demo-web` service, and the relevant logs;
4. request explicit approval before changing anything.

You can inspect the exact local artifact too:

```bash
ls -lt reports/
cat "$(ls -t reports/*.md | head -n 1)"
```

## 8. Approve recovery

Only after Hermes reports the cause, send the approval message from the same prompt file. It permits recovery of **`demo-web` only**.

Hermes runs:

```bash
./scripts/recover-demo.sh
```

The script starts only `demo-web`, waits for the configured server-IP URL, and reports either `RECOVERED` or `RECOVERY_FAILED`. Verify yourself:

```bash
./scripts/check-demo.sh
docker compose ps
```

## Seminar presentation flow

1. Explain Hermes, Docker, Telegram, the server-IP binding, and the approval boundary.
2. Install Hermes, run `hermes doctor`, and configure the OpenRouter free model.
3. Connect the owner-allowlisted Telegram bot.
4. Start `demo-web` and open it using the configured server IP.
5. Run `scripts/simulate-attack.sh` and show that the website is unreachable.
6. Ask Hermes through Telegram to collect Docker state, inspect data, and logs.
7. Review Hermes' evidence-backed incident report before approving any action.
8. Send the explicit approval message, recover only `demo-web`, and verify the server-IP URL.
9. Explain how the same inspect-report-approve-verify pattern applies to real services without making autonomous production repairs.

## Troubleshooting

| Symptom | Check | Fix |
|---|---|---|
| `hermes: command not found` | `echo "$PATH"` | Run `source ~/.bashrc`, then reopen the shell. |
| Docker permission denied | `docker ps` | Run `newgrp docker` after adding the user to the Docker group, then retry. |
| Compose says `DEMO_BIND_IP` is missing | `cat .env` | Copy `.env.example` to `.env` and set the host's reachable IPv4 address. |
| `cannot assign requested address` | `ip -4 addr` | Use an IPv4 address actually assigned to one of the host's interfaces. |
| Port 8080 is occupied | `ss -ltnp | grep 8080` | Stop the conflicting service or change the published port consistently in Compose and the scripts. |
| Bot does not reply | Confirm the token and owner user ID in `hermes gateway setup` | Start a DM with the bot, confirm the allowlist, then restart/setup the gateway. |
| OpenRouter model fails | Check the selected model ID at OpenRouter | Select another currently available model ending in `:free` with `hermes model`. |
| Report has no Docker data | Run `docker compose ps` manually | Run Hermes from the same Linux user that can execute Docker. |

## Optional: read-only recurring monitoring

After the live seminar, add a read-only schedule only after testing the script manually. The job should run `scripts/collect-incident.sh`, notify Telegram only when the configured server-IP URL fails, and use `[SILENT]` when healthy. Do not schedule `scripts/recover-demo.sh`; this lab intentionally requires a person to approve recovery.

## Contributor checks

Run these before committing changes:

```bash
./tests/test_scripts.sh
bash -n scripts/*.sh tests/test_scripts.sh
docker compose config --quiet
git status --short
git grep -nE 'sk-[A-Za-z0-9]|OPENROUTER_API_KEY=[^r]|TELEGRAM_BOT_TOKEN=[^r]' -- . ':!.env.example' || true
```

The final secret scan must return no real credentials. `.env`, `.hermes/`, and `reports/` are intentionally ignored.
