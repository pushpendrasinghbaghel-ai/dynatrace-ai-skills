---
name: dt-otel-poc-readiness
description: "Run Dynatrace POCs in OpenTelemetry-first environments without assuming OneAgent everywhere. Use when: traces, logs, and metrics come from OTel SDKs or collectors; when the customer only has partial OneAgent coverage; or when a POC must verify signal completeness, semantic conventions, and correlation in an OTel pipeline."
argument-hint: "Service or workload plus OTel context, e.g. 'checkout service via otel collector' or 'mixed OTel traces/logs and no OneAgent on app hosts'"
---

# Dynatrace OpenTelemetry POC Readiness

This skill helps you adapt the POC to the customer's actual telemetry shape instead of assuming classic OneAgent coverage.

## Authoritative references

- [OpenTelemetry and Dynatrace](https://docs.dynatrace.com/docs/ingest-from/opentelemetry) — supported OTel ingest options and mixed-instrumentation positioning.
- [Dynatrace Platform Services](https://developer.dynatrace.com/develop/platform-services/) — platform-service context for querying and analyzing ingested signals.
- [Dynatrace SDK for TypeScript](https://developer.dynatrace.com/develop/sdks/) — follow-on implementation surface when turning the readiness result into dashboards, notebooks, or apps.

## Grounding notes

The OTel support model is grounded in Dynatrace documentation. The readiness criteria and fallback planning are SE heuristics for deciding how ambitious a customer POC can safely be.

## When to Use

- The customer uses OpenTelemetry SDKs or collectors for traces, logs, or metrics.
- OneAgent is absent on some or all application hosts.
- You need to verify whether an OTel pipeline is good enough for the promised POC outcome.
- Signal correlation depends on resource attributes and semantic conventions rather than host-side auto-instrumentation.

## Inputs needed

- Key services or workloads
- Which signals come from OTel: traces, logs, metrics, or all three
- Collector/export path if known
- POC success criteria

## Phase 1 - Determine the telemetry contract

Write down what the customer actually sends:

- traces only
- traces + metrics
- traces + logs + metrics
- mixed OTel and OneAgent

Then identify the minimum required fields:

- `service.name`
- environment or namespace markers
- correlation fields such as `trace_id`
- business identifiers if the use case needs them

## Phase 2 - Verify each signal separately

Traces:

```dql
fetch spans, from: now()-30m
| fields timestamp, span.name, dt.entity.service
| limit 20
```

Logs:

```dql
fetch logs, from: now()-30m
| fields timestamp, log.source, content
| limit 20
```

Metrics:

```dql
timeseries { value = avg(<metric-name>) }, from: now()-30m
```

If metric names are unknown, discover them first from the tenant instead of promising a metric-based story immediately.

## Phase 3 - Verify correlation, not just presence

An OTel-first POC is viable when:

- traces identify the service/workload clearly,
- logs can be filtered to the same service or trace context,
- metrics describe the same component or transaction class,
- the signals are fresh enough for the demo window.

If any of these fail, adapt the POC plan rather than forcing a OneAgent-style workflow.

## Phase 4 - Choose the right fallback

If OTel traces exist but logs do not:

- keep root-cause work trace-centric,
- use collector-based custom log ingest if the customer approves it.

If metrics are missing:

- use traces and logs for the functional demo,
- downgrade trend promises until a metric source is confirmed.

If resource attributes are weak:

- normalize them during collection or ingest,
- or narrow the scenario to the services that are already well tagged.

## OTel-specific pitfalls

- `service.name` missing or inconsistent across services
- logs ingested without trace correlation fields
- metrics present, but unrelated to the application story
- collector pipeline exists, but exporters or attributes differ by environment
- customer says "we use OTel" but only traces are actually reaching Dynatrace

## Checklist

- [ ] OTel signal mix is explicit
- [ ] Each signal was verified with tenant data
- [ ] Correlation fields and resource attributes were checked
- [ ] POC promises were adapted to actual telemetry strength
- [ ] Any fallback ingest or normalization steps are documented
