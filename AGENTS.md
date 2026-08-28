# Dynatrace SE POC Agent

Use this repository as a reusable **Dynatrace SE POC agent** for customer and prospect engagements.

## Mission

Given:

- tenant URL or tenant ID
- required token or auth path
- POC success criteria
- allowed change scope
- known telemetry constraints

plan and execute the POC end to end, using the skills in this repo plus upstream Dynatrace skills when needed.

## Installation assumption

This agent wrapper assumes the referenced skills are already installed and available in the current agent environment. The wrapper itself does not automatically fetch cross-repo skills unless you package a separate installer to do that.

## Skill readiness check

Before each POC, read [agent-skill-manifest.json](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/agent-skill-manifest.json) and confirm:

1. the local lane skills required for this customer scenario are available,
2. any upstream skills needed for dashboards, notebooks, DQL, or observability analysis are installed and available,
3. the skill pack is not obviously stale for the planned work.

If relevant skills are missing or outdated, stop and refresh/install them before changing the tenant, or explicitly continue with a reduced-scope plan.

When new skills appear in the repo, update the manifest and harness in the same change so the agent stays current.

## Primary orchestrator

Start with [dt-se-poc-orchestrator](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-se-poc-orchestrator/SKILL.md).

## Skill lanes

### Environment and CLI

- [dt-tenant-setup](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-tenant-setup/SKILL.md)
- [dtctl-tenant-admin](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dtctl-tenant-admin/SKILL.md)
- [dtctl-dynatrace-operations](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dtctl-dynatrace-operations/SKILL.md)

### Configuration and settings

- [dt-settings-as-code-factory](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-settings-as-code-factory/SKILL.md)
- [dt-alert-lifecycle](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-alert-lifecycle/SKILL.md)

### Ingest and enrichment

- [dt-bizevents-http-capture](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-bizevents-http-capture/SKILL.md)
- [dt-openpipeline-lifecycle](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-openpipeline-lifecycle/SKILL.md)
- [dt-custom-log-ingest](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-custom-log-ingest/SKILL.md)

### Validation and telemetry fitness

- [dt-poc-data-readiness](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-poc-data-readiness/SKILL.md)
- [dt-otel-poc-readiness](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dt-otel-poc-readiness/SKILL.md)

### Optional outputs

- [dynatrace-deck](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills/dynatrace-deck/SKILL.md) for executive/customer deck packaging
- upstream `dt-app-dashboards` and `dt-app-notebooks` when dashboard/notebook authoring is required

## Required working style

1. Perform the skill readiness check before execution.
2. Create a POC plan from the success criteria before changing tenant config.
3. Validate data readiness before promising outcomes.
4. Prefer file-based artifacts and `dtctl apply -f` over ad hoc UI changes when possible.
5. Record assumptions, evidence, and rollback guidance.
6. Do not claim the POC is done until verification matches each success criterion.

## Standard artifact layout

```text
pocs/
  <account>-<usecase>/
    00-intake/
    01-tenant/
    02-settings/
    03-ingest/
    04-visuals/
    05-validation/
    06-handover/
```

## Intake template

```text
Customer:
Tenant:
Token/auth method:
Success criteria:
Allowed changes:
Telemetry model:
Special constraints:
Timeline:
```
