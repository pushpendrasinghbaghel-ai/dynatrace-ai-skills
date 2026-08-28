---
name: dt-custom-log-ingest
description: "Handle customer scenarios where logs live on custom paths or are not already flowing to Dynatrace. Use when: application logs are under non-default folders, Windows drive paths, mounted volumes, or bespoke rotation schemes; when log collection must be configured; or when POCs need fallback ingestion through OpenTelemetry Collector instead of OneAgent."
argument-hint: "Log path, platform, and desired fields, e.g. 'D:\\Acme\\logs\\orders\\*.log on Windows host' or '/srv/app/logs/*.json on Linux via OTel Collector'"
---

# Dynatrace Custom Log Ingest

This skill covers the common SE reality that the interesting logs are not always already present in Grail.

## Authoritative references

- [OpenTelemetry and Dynatrace](https://docs.dynatrace.com/docs/ingest-from/opentelemetry) — supported OTel ingest paths and collector choices.
- [Dynatrace data and storage guide](https://developer.dynatrace.com/develop/guides/data/) — platform-side data handling context for follow-up processing and storage decisions.
- Local operational reference: [log-monitoring-setup.md](../dt-bizevents-http-capture/references/log-monitoring-setup.md).

## Grounding notes

The OTel fallback and Dynatrace data model context are doc-grounded. The exact path-verification, permission, and rotation guidance is based on recurring SE onboarding patterns.

## When to Use

- Logs are on a custom file-system path instead of a default monitored location.
- The customer uses Windows drive-letter paths, mounted shares, or unusual rotation conventions.
- OneAgent is unavailable or incomplete, so logs need an OpenTelemetry Collector fallback.
- A POC depends on logs being searchable and correlated quickly.

## Inputs needed

- Exact log path or glob
- Operating system and runtime location
- Sample log lines
- Whether OneAgent is present on the host
- Whether OpenTelemetry Collector is available

## Phase 1 - Prove the current state

Before changing collection, verify whether the logs are already ingested:

```dql
fetch logs, from: now()-30m
| filter log.source contains "orders"
| fields timestamp, log.source
| limit 20
```

If logs are already present, avoid re-ingesting the same source.

## Phase 2 - Choose the ingestion path

### Path A - OneAgent-based collection

Use when the host is already monitored and log collection can be enabled/configured there.

Checklist:

- path exists on the monitored host
- process/user can read the files
- rotation pattern is understood
- source path pattern is exact enough to avoid noise

### Path B - OpenTelemetry Collector fallback

Use when OneAgent is unavailable, incomplete, or not approved for this host.

Example filelog receiver snippet:

```yaml
receivers:
  filelog/orders:
    include:
      - D:\\Acme\\logs\\orders\\*.log

service:
  pipelines:
    logs:
      receivers: [filelog/orders]
```

Preserve resource attributes such as `service.name`, `host.name`, `deployment.environment`, and any business dimensions you already know you will need downstream.

## Phase 3 - Validate the ingest path

After enabling collection:

```dql
fetch logs, from: now()-15m
| filter log.source contains "orders"
| summarize total=count(), latest=max(timestamp)
```

Then inspect a few records:

```dql
fetch logs, from: now()-15m
| filter log.source contains "orders"
| fields timestamp, log.source, content
| limit 10
```

## Phase 4 - Improve correlation

If the POC needs root cause, trend, or workflow use cases, make sure logs also carry at least some of:

- `service.name`
- `host.name`
- `trace_id` / `span_id`
- environment or tenant markers

If those attributes are absent, document the impact. Do not pretend "logs are ready" when they are isolated text blobs.

## Common pitfalls

- Path globs that are too broad and ingest unrelated files
- Windows backslashes not escaped in collector config
- Rotated files matching a pattern unexpectedly
- Logs ingested without resource attributes, breaking correlation
- Customer says "logs exist" but the agent lacks read permission

## Checklist

- [ ] Exact custom path confirmed
- [ ] Existing ingest checked first
- [ ] Collection path chosen intentionally: OneAgent or OpenTelemetry Collector
- [ ] Validation query proves new logs are arriving
- [ ] Correlation attributes were checked, not assumed
