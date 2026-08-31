---
name: dt-se-poc-orchestrator
description: "Run repeatable Dynatrace SE POCs with one orchestrated workflow across setup, data onboarding, dashboards, validation, and handover. Use when: preparing customer/prospect POCs, reducing repetitive SE tasks, standardizing POC quality, or coordinating sub-agents across Claude Code, GitHub Copilot, and Gemini."
argument-hint: "Customer/prospect name, use case, target environment, and timeline (for example: 'Acme outage analytics POC in 2 weeks on tenant xqv46417')"
metadata:
  category: poc-planning-advisory
  code-specific: "false"
---

# Dynatrace SE POC Orchestrator

This skill is a **conductor** for repetitive SE POC work. It does not replace domain skills; it sequences them into one production-ready delivery flow with clear entry/exit criteria and reusable artifacts.

Use this when you want a consistent "POC factory" across customers while keeping token use under control.

## Authoritative references

- [Dynatrace MCP server docs](https://docs.dynatrace.com/docs/shortlink/dynatrace-mcp-server)
- [Dynatrace Platform Services](https://developer.dynatrace.com/develop/platform-services/)
- [Dynatrace Workflows guide](https://developer.dynatrace.com/develop/guides/workflows/)
- Local lane references: [gap-backed-skill-roadmap.md](./references/gap-backed-skill-roadmap.md) and [tenant-poc-test-playbook.md](./references/tenant-poc-test-playbook.md)

## Grounding notes

This skill is intentionally a workflow/orchestration layer. The product capabilities it sequences are grounded in Dynatrace docs and the child skills; the lane structure, gates, and packaging rules are SE operating conventions.

## Outcomes

By the end of one run, you should have:

1. Tenant access and tooling verified.
2. Settings/config deployed from versioned files.
3. Required telemetry shape available (bizevents, logs, traces, metrics).
4. Dashboards/notebooks ready for demo and troubleshooting.
5. Validation evidence and handover package created.

## Cross-platform contract (Claude + Copilot + Gemini)

To stay portable across agents:

- Keep this skill in standard Agent Skills format (`SKILL.md` + optional `references/` and `assets/`).
- Store prompts as plain markdown templates (no agent-proprietary syntax in core logic).
- Keep MCP/tool details in a compatibility layer:
  - "If MCP tools exist, use MCP."
  - "Else use `dtctl` and checked-in YAML/JSON artifacts."
- Use deterministic artifact paths and names so different agents can continue each other's work.

## Orchestration model

### Orchestrator (primary agent)

Responsibilities:

- Collect POC intent, scope, and success metrics.
- Build the execution plan.
- Launch/coordinate specialists.
- Enforce quality gates.
- Produce final handover summary.

### Specialist lanes (sub-agents or sequential phases)

1. **Environment lane**
   - Tenant onboarding, auth, context setup.
   - Primary skills: `dt-tenant-setup`, `dtctl-tenant-admin`, `dtctl-dynatrace-operations`.
2. **Configuration lane**
   - Settings discovery, YAML authoring, promotion, rollback.
   - Primary skill: `dt-settings-as-code-factory`.
3. **Ingestion lane**
   - Bizevents capture, OpenPipeline enrichment, and custom-path log ingest.
   - Primary skills: `dt-bizevents-http-capture`, `dt-openpipeline-lifecycle`, `dt-custom-log-ingest`.
4. **Visualization lane**
   - Dashboard/notebook authoring and tuning.
   - Complement with `dt-app-dashboards` / `dt-app-notebooks` when available.
5. **Validation lane**
   - Telemetry-readiness checks, DQL checks, field-fill rates, OTel viability, alert sanity, and regression checks.
   - Primary skills: `dt-poc-data-readiness`, `dt-otel-poc-readiness`, `dt-alert-lifecycle`.
   - Complement with `dt-dql-essentials`, `dt-alerting`, and relevant `dt-obs-*` skills.
6. **Packaging lane**
   - Demo storyline, runbook, assumptions, known gaps, rollback steps.

If sub-agents are unavailable, run lanes sequentially but preserve the same outputs.

## Canonical folder layout for every POC

Use a predictable structure per account/opportunity:

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

Minimum artifacts:

- `00-intake/poc-charter.md` (scope, success criteria, timeline, owners)
- `01-tenant/context.md` (tenant URL, auth method, tool verification evidence)
- `02-settings/*.yaml` (settings-as-code)
- `03-ingest/*.yaml` + `*.dql` (capture/enrichment + validation queries)
- `04-visuals/*.json` or `*.md` (dashboards/notebooks)
- `05-validation/acceptance-checks.md`
- `06-handover/runbook.md`

## Token-efficiency rules

1. **Reuse first**: Start from prior POC templates, only diff what changes per customer.
2. **Narrow context loading**: Load only relevant skill references for the current lane.
3. **Artifact-over-chat**: Persist commands, DQL, and settings files instead of repeating in chat.
4. **Strict gatekeeping**: Do not re-run expensive broad queries when a scoped query answers the same question.
5. **Summarize by exception**: Keep long logs out of chat; record pass/fail plus root cause and fix.

## Execution gates (definition of done)

### Gate 1 — Access ready

- `dtctl` context works.
- At least one minimal query succeeds.

### Gate 2 — Config ready

- Required settings deployed from files.
- Object IDs/versions tracked for updates.

### Gate 3 — Data ready

- Expected events/metrics/logs are arriving.
- Required business fields pass fill-rate thresholds.

### Gate 4 — Story ready

- Dashboards/notebooks answer the agreed POC questions.
- Views are explainable to both technical and business stakeholders.

### Gate 5 — Handover ready

- Runbook includes deployment, verification, rollback, and next-step backlog.
- Assumptions and known limitations are explicit.

## Gap-first roadmap (complements official Dynatrace skills)

Use [gap-backed-skill-roadmap.md](./references/gap-backed-skill-roadmap.md) to prioritize new skills that are currently underrepresented and high-leverage for SE POCs.

## Testing full-tenant POC depth

Use [tenant-poc-test-playbook.md](./references/tenant-poc-test-playbook.md) together with the local harness POC depth suite to measure whether the current skill set can actually execute a customer POC end-to-end, including variant handling such as custom log paths and OpenTelemetry-first environments.

## Community-recognition playbook

- Publish reusable skills with real anonymized examples and verification checklists.
- Include "pitfalls that bit us" sections (high trust, high practical value).
- Add before/after token usage and cycle-time improvements where possible.
- Contribute complementary pieces (not duplicates) and reference upstream skills clearly.
