# Tenant POC test playbook

Use this to test whether the agent can run a real customer POC from a tenant, token, and success criteria.

## Inputs to give the agent

Provide:

- tenant URL or tenant ID
- authentication method and token type
- POC success criteria
- scope boundaries
- allowed changes
- telemetry reality on the customer side

Example intake:

```text
Customer: Acme
Tenant: https://xqv46417.apps.dynatrace.com
Token: <provided out of band>
Success criteria:
1. Show top failing APIs and root causes
2. Capture order business events with dealer id and order id
3. Build one dashboard and one notebook for the readout
4. Alert into Slack when failure rate spikes
Customer specifics:
- app logs are on D:\Acme\logs\orders\*.log
- traces and metrics come from OpenTelemetry
- OneAgent is not on all hosts
Allowed changes:
- settings objects, dashboards, notebooks, workflow notifications
```

## Typical flow the agent should execute

### Phase 1 - Intake and planning

Expected behavior:

- restate success criteria as measurable checks
- identify telemetry dependencies and risks
- split work into lanes: onboarding, ingest, visualization, validation, handover

Evidence to look for:

- POC plan artifact
- assumptions list
- explicit gaps called out early

### Phase 2 - Tenant onboarding

Expected behavior:

- configure `dtctl` context
- configure MCP access if requested
- run minimal connectivity query

Evidence to look for:

- working context
- successful smoke-test query

### Phase 3 - Telemetry readiness assessment

Expected behavior:

- determine whether signals exist for logs, traces, metrics, bizevents
- distinguish OneAgent-based assumptions from OpenTelemetry-based realities
- detect custom log path requirements

Evidence to look for:

- queries proving which signals exist
- statement of missing signals and impact on success criteria

### Phase 4 - Implement required changes

Expected behavior:

- deploy settings/config from files
- create capture rules or enrichment logic
- create dashboard/notebook assets
- configure alerting/workflow routing if in scope

Evidence to look for:

- YAML/JSON artifacts
- verification queries
- object IDs or resource references

### Phase 5 - Validate against success criteria

Expected behavior:

- prove each criterion with query evidence or created artifact
- measure fill rates for key fields
- verify dashboards and notebooks answer the promised questions

Evidence to look for:

- pass/fail checklist
- screenshots, IDs, or exported assets where applicable

### Phase 6 - Handover

Expected behavior:

- summarize what was implemented
- note known gaps and next actions
- include rollback/update guidance

## Depth scale

### Level 1 - Onboarding only

Can connect tenant and run smoke-test queries.

### Level 2 - Guided domain execution

Can perform a narrow task like HTTP bizevents capture if prerequisites are already known.

### Level 3 - Multi-lane POC execution

Can plan and execute several linked tasks across onboarding, config, validation, and packaging.

### Level 4 - Variant-aware POC execution

Handles custom log paths, OpenTelemetry-first environments, mixed telemetry maturity, and workflow automation without assuming OneAgent everywhere.

## Current measured ceiling in this repo

Use the harness report, not intuition.

- Baseline OneAgent POC: partial coverage
- Custom log path POC: partial coverage
- OpenTelemetry-first POC: partial coverage
- Workflow automation POC: partial coverage

At the moment, the repo is strongest in:

- tenant onboarding
- HTTP bizevents capture
- app-dev AI setup
- POC orchestration structure

The main missing execution depth is:

- dashboards/notebooks authoring skills in this repo
- generic cross-signal analysis coverage
- custom log path ingestion skill
- OTel-first POC readiness skill
- workflow automation skill
