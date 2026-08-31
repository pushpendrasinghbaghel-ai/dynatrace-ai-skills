# Capture Rule Anatomy

Full reference for `builtin:bizevents.http.incoming` YAML fields.

## Top-Level Structure

```yaml
objectId: ""              # Include after first deploy for updates. Omit for new rules.
schemaId: builtin:bizevents.http.incoming
scope: environment        # Always "environment" for HTTP capture rules
value:
  enabled: true
  ruleName: "App Name - Endpoint Description"
  triggers: [...]
  event:
    provider: {...}
    category: {...}
    type: {...}
    data: [...]
```

---

## Triggers

Multiple triggers are ANDed together.

```yaml
triggers:
  - source:
      dataSource: request.path
    type: EQUALS          # EQUALS | CONTAINS | STARTS_WITH | ENDS_WITH | MATCHES
    value: "/api/Save"
    caseSensitive: true

  - source:
      dataSource: request.method
    type: EQUALS
    value: "POST"
    caseSensitive: false
```

### dataSource options
- `request.path` — URL path (no query string)
- `request.method` — GET, POST, PUT, DELETE, etc.
- `response.statusCode` — integer as string, e.g. "200"
- `request.headers` — a specific header value (add `name:` field)
- `response.body` — a specific response body field (add `path:` field)

### Trigger Tips
- Use `CONTAINS` for parameterized paths: `/api/detail/` matches `/api/detail/1/14144/41432`
- Use `EQUALS` for fixed paths: `/api/Save` won't accidentally match `/api/SaveAll`
- Add method trigger (`POST` / `GET`) when the same path serves multiple methods differently

---

## Event Identity Fields

```yaml
event:
  provider:
    source: "MY-APP-NAME"     # Identifies the producing application
    sourceType: constant.string
  category:
    source: "Domain"          # Logical grouping, e.g. "JobCard", "Order", "Payment"
    sourceType: constant.string
  type:
    source: "biz.domain.action"   # Naming convention: biz.{domain}.{verb}
    sourceType: constant.string
```

### Naming Convention for event.type
```
biz.{domain}.{action}

Examples:
  biz.jobcard.save
  biz.jobcard.detail
  biz.order.create
  biz.payment.confirm
  biz.inventory.adjust
```

---

## Data Fields — Full Reference

### Always include

```yaml
data:
  - name: "req.path"
    source:
      sourceType: request.path     # Full URL path

  - name: "http.status"
    source:
      sourceType: response.statusCode
```

### Request body (JSON POST)

```yaml
  - name: "dealer.code"
    source:
      path: "DealerCode"           # Top-level JSON field
      sourceType: request.body

  - name: "user.id"
    source:
      path: "UserId"
      sourceType: request.body

  - name: "order.items"            # Nested field
    source:
      path: "Order.Items"
      sourceType: request.body

  - name: "req.body"               # Whole body as string (debug only, JSON only)
    source:
      path: "*"
      sourceType: request.body
```

> **Warning:** `request.body` only works for `application/json` content type.
> Form-encoded (`application/x-www-form-urlencoded`) and multipart bodies are NOT extractable.

### Response body (JSON)

```yaml
  - name: "save.result"
    source:
      path: "statusCode"           # Top-level: {"statusCode": 200, ...}
      sourceType: response.body

  - name: "save.message"
    source:
      path: "statusMessage"
      sourceType: response.body

  - name: "jobcard.id"             # Integer scalar: {"OutputList": 51749}
    source:
      path: "OutputList"
      sourceType: response.body

  - name: "jobcard.no"             # Nested: {"OutputList": {"JOB_CARD_NO": "JC001"}}
    source:
      path: "OutputList.JOB_CARD_NO"
      sourceType: response.body

  - name: "share.status"           # String scalar: {"OutputList": "Shared successfully"}
    source:
      path: "OutputList"
      sourceType: response.body
```

### Request headers

```yaml
  - name: "correlation.id"
    source:
      path: "X-Correlation-ID"
      sourceType: request.headers

  - name: "client.app.version"
    source:
      path: "X-App-Version"
      sourceType: request.headers
```

> **Never capture `Authorization`, `Cookie`, `X-Api-Key`, or any other credential-bearing
> header into a bizevent field.** Doing so copies live secrets/bearer tokens into Grail,
> where they are retained, queryable, and visible to anyone with bizevent read access.
> Use non-sensitive correlation identifiers (`X-Correlation-ID`, `X-Request-ID`) instead. If
> you need to know *whether* a request was authenticated, capture a boolean/derived field
> (e.g. `auth.present`) via OpenPipeline rather than the raw header value.

### Response headers

```yaml
  - name: "rate.limit.remaining"
    source:
      path: "X-RateLimit-Remaining"
      sourceType: response.headers
```

---

## Common Response Shapes

### Shape 1: Wrapper object
```json
{"statusCode": 200, "statusMessage": "Success", "OutputList": <value>}
```
```yaml
- name: "result.code"   → path: "statusCode"
- name: "result.msg"    → path: "statusMessage"
- name: "result.data"   → path: "OutputList"          # scalar
- name: "item.id"       → path: "OutputList.ITEM_ID"  # nested object
```

### Shape 2: Direct object
```json
{"id": 123, "status": "active", "customer": {"name": "John", "mobile": "..."}}
```
```yaml
- name: "item.id"         → path: "id"
- name: "item.status"     → path: "status"
- name: "customer.name"   → path: "customer.name"
```

### Shape 3: Array response
```json
{"items": [{"id": 1, "name": "..."}, ...]}
```
> Array extraction is not supported in capture rules. Use OpenPipeline DQL processor for array parsing.

---

## Critical Pitfalls

### ❌ JSONPath `$.` prefix
```yaml
# WRONG — Dynatrace does NOT use JSONPath syntax
path: "$.statusCode"
path: "$.OutputList.JOB_CARD_ID"

# CORRECT — plain dot-notation only
path: "statusCode"
path: "OutputList.JOB_CARD_ID"
```

### ❌ Wrong source for dealer/user
```yaml
# WRONG — if DealerCode is in the POST JSON body, not headers
source:
  path: "DealerCode"
  sourceType: request.headers   # returns null

# CORRECT
source:
  path: "DealerCode"
  sourceType: request.body      # returns the value
```

### ❌ Scope typo
```yaml
scope: Environment   # WRONG — capital E
scope: environment   # CORRECT — lowercase
```

### ❌ Missing objectId on update
Without `objectId`, every `dtctl apply` creates a new duplicate rule.
After first deploy: `dtctl get settings --schema builtin:bizevents.http.incoming`
Copy the `objectId` from the response and add it to the YAML.

---

## Checking Rule Execution Order

Rules are evaluated in order. If two rules match the same request, both fire.
To see current order: `dtctl get settings --schema builtin:bizevents.http.incoming`

To avoid duplicate events, make triggers specific:
- Use `EQUALS` not `CONTAINS` for fixed paths
- Add method trigger to differentiate GET vs POST on the same path
