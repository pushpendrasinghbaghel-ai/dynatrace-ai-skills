---
name: dt-bizevents-http-capture
description: "Capture business events from HTTP APIs using Dynatrace OneAgent. Use when: setting up bizevents capture rules, builtin:bizevents.http.incoming, extracting fields from request body, response body, or URL path, configuring event type and provider, fixing empty fields in capture rules, enriching events via OpenPipeline DQL processor, parsing URL path parameters at ingest, enabling IIS log monitoring for correlation, verifying capture rules with DQL, capture rule YAML dtctl deploy."
argument-hint: "Service name or API path prefix, e.g. 'my-app /api/JobCard'"
metadata:
  category: tenant-control-plane
  code-specific: "true"
---

# Dynatrace Bizevents HTTP Capture

End-to-end workflow for capturing business events from HTTP APIs monitored by OneAgent — from discovery through deployment, enrichment, and verification.

## Authoritative references

- [OpenPipeline](https://docs.dynatrace.com/docs/platform/openpipeline) — supported ingest-time processing model and pipeline concepts.
- [OpenTelemetry and Dynatrace](https://docs.dynatrace.com/docs/ingest-from/opentelemetry) — ingest-path context and collector-based alternatives when OneAgent assumptions do not hold.
- Internal repo references: [capture-rule-anatomy.md](./references/capture-rule-anatomy.md), [openpipeline-enrichment.md](./references/openpipeline-enrichment.md), and [log-monitoring-setup.md](./references/log-monitoring-setup.md).

## Grounding notes

The product concepts are grounded in Dynatrace documentation; the capture-rule patterns, pitfalls, and verification flow are grounded in validated field usage captured in this repo.

## When to Use

- Setting up `builtin:bizevents.http.incoming` capture rules for new APIs
- Fields are empty / "Missing attributes" in captured events
- Need to extract dealer ID, user ID, job card ID from request/response
- Want to enrich events with URL path segments at ingest (OpenPipeline)
- Enabling IIS/access log monitoring to correlate with bizevents
- Redeploying capture rules to a different tenant via dtctl

---

## Phase 1 — Discover the API Surface

Before writing rules, understand what paths exist and how data flows.

### 1a. Find Services and Span Templates

```dql
fetch spans, from: now()-1h
| filter matchesPhrase(span.name, "YOUR_KEYWORD")
| fields span.name, dt.entity.service
| dedup span.name
| limit 30
```

Span names give you the **exact URL template** used by the framework, e.g.:
- `GET JobCard/detail/{branchid}/{dealerid}/{id}` — path segments are named here
- `POST JobCard/Save` — no path params → data is in POST body

### 1b. Sample Real Traffic

```dql
fetch spans, from: now()-30m
| filter dt.entity.service == "SERVICE-XXXX"
| fields span.name, span.http.url, span.http.status_code
| dedup span.name
| limit 20
```

### 1c. Inspect IIS Logs for Parameter Names

```dql
fetch logs, from: now()-30m
| filter log.source == "C:\\inetpub\\logs\\LogFiles\\W3SVC1\\*.log"
| parse content, "LD:date ' ' LD:time ' ' LD:s_ip ' ' LD:method ' ' LD:uri_stem ' ' LD:uri_query ' '"
| filter matchesPhrase(uri_stem, "/YOUR/PATH")
| fields uri_stem, uri_query
| limit 10
```

IIS query strings reveal the exact parameter names: `DealerCode=14460&UserId=...`

### 1d. Ghost Events (Capture Already Running)

If events exist but lack structured fields:
```dql
fetch bizevents, from: now()-1h
| filter event.provider == "YOUR_PROVIDER"
| fields timestamp, event.type, req.path, http.status
| limit 5
```

---

## Phase 2 — Design Capture Rules

### Schema
`builtin:bizevents.http.incoming`

### Rule YAML Structure

```yaml
objectId: ""          # omit for new rules; add after first deploy
schemaId: builtin:bizevents.http.incoming
scope: environment
value:
  enabled: true
  ruleName: "Your App - Endpoint Name"
  triggers:
    - caseSensitive: true
      source:
        dataSource: request.path
      type: EQUALS           # or CONTAINS for path prefixes
      value: "/your/api/path"
    - caseSensitive: false
      source:
        dataSource: request.method
      type: EQUALS
      value: "POST"          # omit if any method
  event:
    provider:
      source: "YOUR-APP-NAME"
      sourceType: constant.string
    category:
      source: "YourDomain"
      sourceType: constant.string
    type:
      source: "biz.your.event"
      sourceType: constant.string
    data:
      - name: "req.path"
        source:
          sourceType: request.path
      - name: "http.status"
        source:
          sourceType: response.statusCode
      # See extraction patterns below
```

See [capture-rule-anatomy.md](./references/capture-rule-anatomy.md) for full field extraction patterns.

### Trigger Types

| Scenario | type | value |
|---|---|---|
| Exact path `/api/Save` | `EQUALS` | `/api/Save` |
| Any sub-path `/api/detail/1/2/3` | `CONTAINS` | `/api/detail/` |
| POST only | `EQUALS` on `request.method` | `POST` |
| Any method | omit method trigger | — |

---

## Phase 3 — Field Extraction

### ⚠️ Critical Pitfalls

| Wrong | Correct | Why |
|---|---|---|
| `path: "$.statusCode"` | `path: "statusCode"` | No `$.` prefix — DT uses dot-notation only |
| `path: "$.OutputList.JOB_CARD_ID"` | `path: "OutputList.JOB_CARD_ID"` | Same — no `$` |
| `sourceType: request.headers` for dealer | `sourceType: request.body` | Most modern APIs send context in JSON body, not headers |
| `path: "*"` on request.body (POST form) | Not extractable | Only works for `application/json` bodies |

### Source Types

| sourceType | What it captures | Works with `path:` |
|---|---|---|
| `request.path` | Full URL path (no query string) | No |
| `request.headers` | HTTP request header by name | Yes — header name |
| `request.body` | JSON request body field | Yes — dot-notation |
| `response.statusCode` | HTTP status integer | No |
| `response.headers` | HTTP response header | Yes — header name |
| `response.body` | JSON response body field | Yes — dot-notation |
| `constant.string` | Hardcoded string | No — inline `source:` |

### Common Extraction Examples

```yaml
# Response body — simple field
- name: "save.result"
  source:
    path: "statusCode"
    sourceType: response.body

# Response body — nested field
- name: "jobcard.id"
  source:
    path: "OutputList.JOB_CARD_ID"
    sourceType: response.body

# Response body — whole body as string (JSON only)
- name: "req.body"
  source:
    path: "*"
    sourceType: request.body

# Request body — POST JSON field
- name: "dealer.code"
  source:
    path: "DealerCode"
    sourceType: request.body

# Request header
- name: "auth.token"
  source:
    path: "Authorization"
    sourceType: request.headers
```

---

## Phase 4 — Deploy with dtctl

```bash
# New rule (no objectId in YAML)
dtctl apply -f rule-name.yaml

# After first deploy, add the returned objectId to the YAML for future updates
# objectId: "vu9U3hXa3q0AAAA..."

# Update existing rule
dtctl apply -f rule-name.yaml   # objectId present → updates in place

# Verify deployment
dtctl get settings --schema builtin:bizevents.http.incoming
```

---

## Phase 5 — Verify

Wait ~2 minutes after deploy, then:

### Check events are flowing
```dql
fetch bizevents, from: now()-10m
| filter event.provider == "YOUR-PROVIDER"
| summarize count=count(), by: event.type
```

### Check field fill rates
```dql
fetch bizevents, from: now()-1h
| filter event.provider == "YOUR-PROVIDER" and event.type == "biz.your.event"
| summarize total=count(),
            has_dealer=countIf(isNotNull(dealer.code)),
            has_jobcard=countIf(isNotNull(jobcard.id))
```

### Debug empty fields — sample raw event
```dql
fetch bizevents, from: now()-10m
| filter event.provider == "YOUR-PROVIDER" and event.type == "biz.your.event"
| fields timestamp, req.path, http.status, dealer.code, jobcard.id
| sort timestamp desc
| limit 5
```

---

## Phase 6 — OpenPipeline Path Enrichment

For events where dealer/job ID is in the URL path (e.g. `/api/detail/{branchid}/{dealerid}/{id}`), extract at ingest using an OpenPipeline DQL processor.

> **Note:** OneAgent HTTP bizevents currently bypass OpenPipeline enrichment. Use `parse req.path, "..."` at **query time** in DQL instead. OpenPipeline works for API-ingested bizevents.

### Query-time parsing (recommended)
```dql
fetch bizevents, from: now()-1h
| filter event.type == "biz.your.detail"
| parse req.path, "'/api/detail/' INT:path.branchid '/' LONG:path.dealer_id '/' LONG:path.item_id"
| summarize count=count(), by: path.dealer_id
```

### OpenPipeline config (for API-ingested events)
See [openpipeline-enrichment.md](./references/openpipeline-enrichment.md) and [openpipeline-path-parser.yaml](./assets/openpipeline-path-parser.yaml).

---

## Phase 7 — IIS Log Monitoring (when body extraction fails)

When POST request body fields can't be extracted (form-encoded, non-JSON), enable IIS access log collection and join by timestamp.

See [log-monitoring-setup.md](./references/log-monitoring-setup.md).

**Query to correlate IIS logs with bizevents:**
```dql
fetch logs, from: now()-1h
| filter log.source == "C:\\inetpub\\logs\\LogFiles\\W3SVC*\\*.log"
| filter matchesPhrase(content, "/wip/JobCard/Save")
| parse content, "LD:date ' ' LD:time ' ' LD:s_ip ' ' LD:method ' ' LD:uri_stem ' ' LD:uri_query ' '"
| parse uri_query, "LD 'DealerCode=' LD:dealer_code '&'"
| fields timestamp, uri_stem, dealer_code
```
