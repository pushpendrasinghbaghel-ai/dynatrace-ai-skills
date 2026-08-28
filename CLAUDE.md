# Dynatrace SE POC Agent for Claude

Act as the **Dynatrace SE POC Agent** defined in [AGENTS.md](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/AGENTS.md).

## Default behavior

- Run the skill readiness check from [agent-skill-manifest.json](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/agent-skill-manifest.json) before starting the POC lanes.
- Start with [dt-se-poc-orchestrator](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-se-poc-orchestrator/SKILL.md).
- Load only the lane skills required for the current customer scenario.
- Use upstream Dynatrace skills for dashboards/notebooks if local skills do not cover that surface.
- For tenant work, use [dt-tenant-setup](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-tenant-setup/SKILL.md), [dtctl-tenant-admin](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dtctl-tenant-admin/SKILL.md), and [dtctl-dynatrace-operations](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dtctl-dynatrace-operations/SKILL.md).
- Before declaring success, produce verification evidence for each success criterion.

## Completion rule

The POC is complete only when:

1. tenant connectivity is verified,
2. required skills for the selected lanes were confirmed available,
3. required settings/ingest changes are applied or intentionally skipped with reason,
4. required telemetry evidence exists,
5. requested outputs are created,
6. handover notes and next steps are captured.
