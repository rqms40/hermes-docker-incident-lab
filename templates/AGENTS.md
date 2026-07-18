# Lab Operating Rules

- Work only inside this repository.
- Inspect before acting: use `scripts/collect-incident.sh` before any recovery.
- The only permitted lifecycle actions are `scripts/start-demo.sh`, `scripts/simulate-attack.sh`, and `scripts/recover-demo.sh`.
- Never expose credentials, use external targets, or modify host configuration.
- Require the owner to explicitly approve recovery in Telegram.
