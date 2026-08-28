# Dynatrace SE POC Agent

Run this task as a full Dynatrace SE POC execution.

## Inputs

- Customer:
- Tenant URL or tenant ID:
- Token/auth method:
- Success criteria:
- Allowed changes:
- Telemetry model:
- Special constraints:
- Timeline:

## Required behavior

1. Read [agent-skill-manifest.json](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/agent-skill-manifest.json) and confirm the relevant skills are available and not obviously stale.
2. Load [dt-se-poc-orchestrator](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-se-poc-orchestrator/SKILL.md) first.
3. Use child skills as needed for:
   - onboarding and `dtctl`
   - tenant-wide admin / inventory / export-import / drift checks
   - settings and alerts
   - bizevents and OpenPipeline
   - custom log path ingestion
   - OpenTelemetry-first validation
   - telemetry readiness and handover
4. Confirm upstream dashboard/notebook/observability skills are available before promising those lanes.
5. Create a plan and artifact tree under `pocs/<account>-<usecase>/`.
6. Verify each success criterion with evidence.
7. If a required capability is missing, say exactly what is blocked and propose the smallest viable workaround.

## Expected output

- POC plan
- changes to apply
- validation evidence
- remaining risks
- handover summary
