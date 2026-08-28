---
name: dt-poc-data-readiness
description: "Assess whether a Dynatrace tenant is ready for a POC and map success criteria to available telemetry. Use when: validating logs, traces, metrics, and business events before a demo; checking whether a tenant can support a use case; identifying signal gaps; or planning fallback paths when data is partial."
argument-hint: "Use case and success criteria, e.g. 'show root cause for failing checkout and alert on error spike' or 'prove order tracking from logs, traces, metrics, and bizevents'"
---

# Dynatrace POC Data Readiness

Use this skill before promising a demo outcome. It converts success criteria into evidence requirements and tests whether the tenant has the necessary telemetry.

## Authoritative references

- [Dynatrace Platform Services](https://developer.dynatrace.com/develop/platform-services/) — official platform-service concepts and query surface context.
- [Dynatrace SDK for TypeScript](https://developer.dynatrace.com/develop/sdks/) — official platform capability catalog when implementing app-side follow-up.
- [OpenTelemetry and Dynatrace](https://docs.dynatrace.com/docs/ingest-from/opentelemetry) — mixed telemetry and OTel signal model context.

## Grounding notes

The signal categories and platform capabilities are doc-grounded. The readiness matrix and verdict model are SE-specific evaluation heuristics for deciding whether a tenant can satisfy a POC promise.

## When to Use

- A customer gave you a tenant and asked, "Can we run this POC here?"
- You need to know whether logs, traces, metrics, and business events are present and fresh enough.
- You suspect a success criterion depends on signals that are missing or only partially correlated.
- You need an honest preflight before building dashboards or workflows.

## Inputs needed

- Named customer use case
- Success criteria
- Key services, apps, hosts, namespaces, or business entities
- Known telemetry model: OneAgent, OpenTelemetry, or mixed

## Phase 1 - Translate success criteria into evidence

Turn each criterion into a measurable check.

Example:

```text
Criterion: Show top failing APIs and likely root cause
Needs:
- spans/traces for request failures
- logs correlated to traces or services
- at least one metric or problem view for trend
```

If a criterion cannot be mapped to observable data, flag it immediately.

## Phase 2 - Check signal existence and freshness

Logs:

```dql
fetch logs, from: now()-30m
| summarize total=count(), latest=max(timestamp)
```

Traces:

```dql
fetch spans, from: now()-30m
| summarize total=count(), latest=max(timestamp)
```

Business events:

```dql
fetch bizevents, from: now()-30m
| summarize total=count(), latest=max(timestamp)
```

Metrics:

```dql
timeseries { value = avg(<metric-name>) }, from: now()-30m
```

If the metric name is not known, discover it first. Do not guess metric identifiers in front of the customer.

## Phase 3 - Check cross-signal correlation

The goal is not just "data exists", but "signals can answer the scenario together."

Ask:

- Can failing spans be tied to a service or workload?
- Can logs be filtered to the same service, host, or trace context?
- Is there at least one trend metric for the same component?
- Are business keys present where the use case needs them?

Typical blockers:

- logs exist but no service or trace linkage
- traces exist but business identifiers are absent
- metrics exist only at host level while the story needs service level
- data is present but too stale for a live demo

## Phase 4 - Produce a readiness verdict

Classify each success criterion as:

- ready
- ready with workaround
- blocked

A workaround could be:

- query-time parsing instead of ingest-time enrichment
- narrower scope to one service
- notebook demo instead of full dashboard
- use logs + traces now, add metrics later

## Suggested artifact

```text
05-validation/
  readiness-matrix.md
```

Matrix columns:

- success criterion
- required signals
- current evidence
- verdict
- workaround

## Checklist

- [ ] Every success criterion is mapped to telemetry requirements
- [ ] Logs, traces, metrics, and business events were checked intentionally
- [ ] Freshness was measured, not assumed
- [ ] Cross-signal correlation gaps are explicit
- [ ] The tenant is classified ready / workaround / blocked per criterion
