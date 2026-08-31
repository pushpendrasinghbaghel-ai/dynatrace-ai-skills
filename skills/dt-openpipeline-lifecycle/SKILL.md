---
name: dt-openpipeline-lifecycle
description: "Design, deploy, and validate OpenPipeline parsing and enrichment for repeatable POCs. Use when: creating processors, normalizing fields, parsing log lines or payloads, enriching business events, validating transformed fields, or troubleshooting why pipeline-enriched data is missing or malformed."
argument-hint: "Signal type, source format, and target fields, e.g. 'logs from custom path, extract order_id and dealer_code' or 'API-ingested bizevents, parse req.path into business IDs'"
metadata:
  category: tenant-control-plane
  code-specific: "true"
---

# Dynatrace OpenPipeline Lifecycle

Use this skill when the challenge is not just writing one parser, but running the full parser/enrichment lifecycle safely and repeatably.

## Authoritative references

- [OpenPipeline](https://docs.dynatrace.com/docs/platform/openpipeline) — pipeline groups, compositions, and supported processing model.
- [OpenTelemetry and Dynatrace](https://docs.dynatrace.com/docs/ingest-from/opentelemetry) — collector-based ingest context and transformation-capable ingest options.
- Local implementation examples under [dt-bizevents-http-capture/assets/](../dt-bizevents-http-capture/assets) and [dt-bizevents-http-capture/references/openpipeline-enrichment.md](../dt-bizevents-http-capture/references/openpipeline-enrichment.md).

## Grounding notes

The ingest model is grounded in Dynatrace documentation. The staged rollout and troubleshooting sequence is an operational pattern designed to reduce failed parser iterations during POCs.

## When to Use

- You need field extraction or normalization before analysts query the data.
- A POC depends on parsed business identifiers, environments, severities, or routing fields.
- You are moving from ad hoc query-time parsing to reusable ingest-time enrichment.
- Data is arriving, but enriched fields are null, partial, or unexpectedly typed.

## Inputs needed

- Signal type: logs, API-ingested business events, or another supported stream.
- A few representative raw records.
- Target fields to create.
- The downstream use case: dashboard, notebook, alert, workflow, or join key.

If the source sample is missing, get one before writing processors. Parser design without real samples creates brittle configs.

## Phase 1 - Define the transformation contract

Before editing the pipeline, write down:

- source field to parse
- expected target fields
- type of each field
- fallback behavior when parsing fails
- which success criterion depends on each field

Good contract example:

```text
Source: content
Target fields:
- order.id (string)
- dealer.code (string)
- env.stage (string)
Failure behavior:
- keep raw record
- add parse_status=failed
```

## Phase 2 - Start simple

Prefer the smallest processor set that proves value:

1. one parser
2. one enrichment or rename
3. one validation query

Avoid building a large chain of transforms until the first derived field is proven in data.

## Phase 3 - Decide ingest-time vs query-time parsing

Use ingest-time processing when:

- the same parsing is needed repeatedly,
- downstream workflows or alerts depend on the derived field,
- the parsing logic should be standardized across users.

Use query-time parsing when:

- the field is only exploratory,
- source shape is still unstable,
- the signal bypasses OpenPipeline for that ingestion path.

Important: OneAgent HTTP business events may require query-time parsing instead of OpenPipeline enrichment. For that case, pair with `dt-bizevents-http-capture` and verify the actual ingest path before assuming enrichment will run.

## Phase 4 - Deploy and validate incrementally

For each processor change:

1. deploy the config from a file,
2. wait for new matching records,
3. validate with a narrow DQL query,
4. inspect failures before adding more logic.

Typical validation questions:

- Did the new field appear at all?
- Is the field type correct?
- What percentage of matching records has the field populated?
- Are parse failures isolated to one log format variant?

## Validation patterns

Field presence:

```dql
fetch logs, from: now()-30m
| filter matchesPhrase(log.source, "orders")
| summarize total=count(), parsed=countIf(isNotNull(order.id))
```

Failure isolation:

```dql
fetch logs, from: now()-30m
| filter isNull(order.id)
| fields timestamp, content
| limit 20
```

## Troubleshooting order

1. Confirm the source records are actually entering the intended pipeline.
2. Confirm the parser targets the real source field.
3. Check for case sensitivity, whitespace, or alternate formats.
4. Check whether the field exists but under a different type or name.
5. Compare a successful sample and a failed sample side by side.

## Artifact layout

```text
03-ingest/
  openpipeline/
    <processor-name>.yaml
    samples.md
    validation.dql
```

## Checklist

- [ ] Real sample records captured
- [ ] Transformation contract written down
- [ ] Ingest-time vs query-time decision is explicit
- [ ] Processor config stored in versioned file
- [ ] Validation DQL proves the target field appears
- [ ] Parse-failure path is understood, not ignored
