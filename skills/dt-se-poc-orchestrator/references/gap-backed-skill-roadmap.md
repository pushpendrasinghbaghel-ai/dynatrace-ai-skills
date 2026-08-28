# Gap-backed skill roadmap (POC-centric, complementary to dynatrace-for-ai)

The official `Dynatrace/dynatrace-for-ai` repo already covers broad observability, security, DQL, migration, and platform basics well.

See [dynatrace-coverage-gap-analysis.md](dynatrace-coverage-gap-analysis.md) for the current documentation-backed completeness boundary.

For SE-led POCs, the largest remaining leverage is **workflow automation + repeatable delivery patterns**.

## Implemented in this repo

- `dt-settings-as-code-factory`
- `dt-openpipeline-lifecycle`
- `dt-poc-data-readiness`
- `dt-custom-log-ingest`
- `dt-otel-poc-readiness`
- `dtctl-dynatrace-operations`
- `dt-alert-lifecycle`

## Priority 1 (build next)

### 1) `dt-poc-handover-packager`

**Why this is a gap**
- Teams repeatedly rebuild handover documents manually.

**What it should do**
- Build a standard handover bundle:
  - implemented scope
  - deployed artifacts
  - validation evidence
  - known gaps
  - productionization backlog

## Priority 2

### 2) `dt-dashboard-storyliner`

**Focus**
- Turn technical telemetry into role-based demo stories (CIO/CTO/SRE/App owner views) with a fixed narrative structure and fallback tiles if data is sparse.

### 3) `dt-workflow-notification-factory`

**Focus**
- Standardized problem-type-to-team notification routing (Slack/email/webhook) with test events and runbook snippets.

This still complements `dt-alert-lifecycle` by specializing in reusable workflow-routing packs rather than the broader alert lifecycle.

## Priority 2

**Focus**
- Expand scenario-specific accelerator skills after the core lanes are stable.

### 4) `dt-poc-multi-tenant-rollout`

**Focus**
- Clone one validated POC pattern across many tenant contexts with per-tenant overrides and drift detection.

### 5) `dt-se-demo-data-seeding`

**Focus**
- Safe synthetic/demo data generation and ingest patterns for low-data environments, with strict "simulated data" labeling.

## Anti-overlap rule

Before creating a new skill:

1. Check if the official repo already solves the same outcome directly.
2. If yes, do not duplicate; add only:
   - POC execution sequencing,
   - operational guardrails,
   - reusable artifact templates,
   - SE delivery heuristics.
3. If partially overlapping, explicitly document "this skill extends X by adding Y."

## Suggested KPI targets

- POC setup time: reduce by 30-50%.
- Rework due to missing telemetry fields: reduce by 40%+.
- First-pass dashboard acceptance rate: increase to 80%+.
- Token usage per POC run: reduce by 25%+ via template reuse and narrow-context loading.
