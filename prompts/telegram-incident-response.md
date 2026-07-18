# Telegram Incident-Response Prompts

Use these messages only after you have completed the local setup in the README.

## 1. Investigate the safe attack simulation

```text
We are running the Hermes Docker Incident Lab. The website on the server IP configured in the project .env is unavailable after a planned safe attack simulation force-terminated demo-web. Work only inside the hermes-docker-incident-lab repository. Run scripts/collect-incident.sh first. Inspect the report, Docker state, container exit code, and logs. Send me a concise incident report with: affected URL, symptom, evidence, likely cause, and the exact scoped recovery command. Treat this as a simulation and do not claim there was a real external attacker. Do not recover anything yet.
```

## 2. Approve recovery

```text
APPROVE RECOVERY: I approve recovery of the lab service demo-web only. Run scripts/recover-demo.sh, verify the server-IP URL configured in .env, and report the result. Do not change any other container or host service.
```

## 3. Healthy check

```text
Run scripts/check-demo.sh for the local Hermes Docker Incident Lab. Report only the health result. Do not change anything.
```
