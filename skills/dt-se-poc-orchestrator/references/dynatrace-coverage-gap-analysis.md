# Dynatrace coverage gap analysis

This repo is intentionally **not** a full reimplementation of Dynatrace docs. It is a POC execution overlay.

Use this file to decide what to add next when the goal is to avoid UI as much as possible.

## Already covered locally

- tenant onboarding and CLI context setup
- settings lifecycle and bulk config changes
- OpenPipeline lifecycle
- HTTP bizevents capture
- telemetry readiness and custom log / OTel variants
- alert lifecycle and routing
- POC orchestration and handover structure

## Official upstream skills that should be treated as part of coverage

Do **not** duplicate these here; install/reference them from `Dynatrace/dynatrace-for-ai`:

- `dt-dql-essentials`
- `dt-obs-services`
- `dt-obs-frontends`
- `dt-obs-tracing`
- `dt-obs-hosts`
- `dt-obs-kubernetes`
- `dt-obs-aws`
- `dt-obs-azure`
- `dt-obs-gcp`
- `dt-obs-logs`
- `dt-obs-problems`
- `dt-obs-predictive-analytics`
- `dt-alerting`
- `dt-obs-analytics`
- `dt-obs-ext-monitors`
- `dt-obs-genai`
- `dt-obs-log-semantic-mapping`
- `dt-sec-insights`
- `dt-sec-contextualization`
- `dt-sec-ioc-hunting`
- `dt-sec-semantic-mapping`
- `dt-obs-android`
- `dt-obs-flutter`
- `dt-obs-ios`
- `dt-obs-react-native`
- `dt-app-dashboards`
- `dt-app-notebooks`
- `dt-js-runtime`
- `dt-platform-costs`
- `dt-migration`

## Remaining high-value complementary skills

These are the main gaps where a local skill still adds value instead of duplicating upstream docs.

### 1) `dt-poc-skill-pack-setup`

Install and preflight the local skill pack, official Dynatrace skills, and `dtctl` together before a POC.

### 2) `dt-observability-onboarding`

Cover OneAgent, ActiveGate, Operator/DynaKube, web RUM, cloud connections, connectivity checks, and teardown.

### 3) `dt-native-synthetic-lifecycle`

Cover browser and HTTP synthetic monitors, private locations, credentials, export/import, and rollback.

### 4) `dt-slo-release-guard-factory`

Cover SLOs, error budgets, burn-rate checks, release validation, and quality gates.

### 5) `dt-business-flow-poc`

Cover Business Flow setup, correlation IDs, buckets, KPIs, and completion/drop-off analysis.

### 6) `dt-workflow-as-code`

Cover trigger types, workflow graphs, retries, test execution, permissions, and rollback.

### 7) Demand-driven accelerators

- `dt-database-observability-poc`
- `dt-tenant-governance-as-code`
- `dt-extension-lifecycle`

## Practical conclusion

With the official Dynatrace skills installed, this repo can cover the **majority** of Dynatrace work without UI.

The biggest remaining non-UI gaps are not dashboards/notebooks/DQL anymore; they are:

1. onboarding and rollout,
2. synthetic monitoring,
3. SLO/SRG release validation,
4. Business Flow,
5. workflow-as-code,
6. governance / database / extensions if those are part of the customer scope.
