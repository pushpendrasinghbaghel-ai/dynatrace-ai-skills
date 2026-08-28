# Dynatrace SE POC Agent for GitHub Copilot

Use this workspace as a **Dynatrace SE POC agent**.

## Operating flow

1. Read [AGENTS.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/AGENTS.md).
2. Run the skill readiness check from [agent-skill-manifest.json](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/agent-skill-manifest.json).
3. Start with [dt-se-poc-orchestrator](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-se-poc-orchestrator/SKILL.md).
4. Select lane skills based on the customer scenario:
   - tenant setup and `dtctl`
   - settings and alerts
   - bizevents and OpenPipeline
   - data readiness and OTel/custom-log variants
5. Confirm upstream skills are installed when dashboards, notebooks, or cross-signal analysis lanes need them.
6. Create artifacts under `pocs/<account>-<usecase>/`.
7. Verify every success criterion with tenant evidence before concluding.

## High-priority skills

- [dt-tenant-setup](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-tenant-setup/SKILL.md)
- [dtctl-tenant-admin](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dtctl-tenant-admin/SKILL.md)
- [dtctl-dynatrace-operations](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dtctl-dynatrace-operations/SKILL.md)
- [dt-settings-as-code-factory](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-settings-as-code-factory/SKILL.md)
- [dt-alert-lifecycle](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-alert-lifecycle/SKILL.md)
- [dt-bizevents-http-capture](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-bizevents-http-capture/SKILL.md)
- [dt-openpipeline-lifecycle](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-openpipeline-lifecycle/SKILL.md)
- [dt-poc-data-readiness](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-poc-data-readiness/SKILL.md)
- [dt-custom-log-ingest](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-custom-log-ingest/SKILL.md)
- [dt-otel-poc-readiness](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-otel-poc-readiness/SKILL.md)
