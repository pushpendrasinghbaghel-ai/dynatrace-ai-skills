# OpenPipeline Path Enrichment

How to extract URL path parameters as named fields at ingest time using OpenPipeline DQL processors.

Schema: `builtin:openpipeline.bizevents.pipelines`

---

## When to Use

URL paths like `/api/orders/{branchid}/{dealerid}/{orderId}` contain business context but bizevents only capture the raw path string. Use this to:
- Extract `dealer_id`, `branch_id`, `item_id` as queryable fields
- Set `jobcard.id` on events whose response body doesn't include it (share, delete, etc.)
- Enable dimensional analysis by dealer without body field extraction

---

## DQL Parse Syntax for Paths

```dql
-- For /api/detail/{branchid}/{dealerid}/{id}
parse req.path, "'/api/detail/' INT:path.branchid '/' LONG:path.dealer_id '/' LONG:path.item_id"

-- For /api/share/{type}/{dealerid}/{jobcardid}  
parse req.path, "'/api/share/' INT:path.type '/' LONG:path.dealer_id '/' LONG:path.item_id"

-- Extract string segment
parse req.path, "'/api/' LD:path.operation '/' INT:path.branchid '/' LONG:path.dealer_id '/' LONG:path.item_id"
```

### DPL Tokens

| Token | Matches | Example |
|---|---|---|
| `'literal'` | Exact string | `'/api/detail/'` |
| `LD:name` | Leading data (any chars, stops at next literal) | Matches "detail", "share" |
| `INT:name` | Integer (32-bit) | Matches 1, 42 |
| `LONG:name` | Long integer (64-bit) | Matches 14144, 51749 |
| `LD` (no name) | Skip — consume but don't store | Skip a prefix |

> **Note:** Do NOT use `FAIL(false)` in OpenPipeline — it is not supported. Use the `matcher` field to pre-filter events that match the pattern.

---

## OpenPipeline Config YAML

```yaml
objectId: ""    # Add after first deploy
schemaId: builtin:openpipeline.bizevents.pipelines
scope: environment
value:
  customId: your-app-path-enrichment    # Unique, 4-100 chars, no "dt." prefix
  displayName: "Your App - Path Field Extraction"
  routing: routable
  processing:
    processors:

      # Step 1: Parse path segments
      - id: parse-api-path-fields
        type: dql
        description: "Extract branchid, dealer_id, item_id from URL path"
        enabled: true
        # Matcher pre-filters to only paths that match the pattern
        matcher: "event.provider == \"YOUR-APP\" and matchesValue(req.path, \"/api/.+/[0-9]+/[0-9]+/[0-9]+\")"
        dql:
          script: "parse req.path, \"'/api/' LD:path.operation '/' INT:path.branchid '/' LONG:path.dealer_id '/' LONG:path.item_id\""

      # Step 2: Promote path fields to business fields (when body doesn't have them)
      - id: set-item-id-from-path
        type: dql
        description: "Set item.id from path when response body does not provide it"
        enabled: true
        matcher: "event.provider == \"YOUR-APP\" and isNull(item.id) and isNotNull(path.item_id)"
        dql:
          script: "fieldsAdd item.id = toLong(path.item_id)"

      # Step 3: Set dealer from path when body doesn't have it
      - id: set-dealer-from-path
        type: dql
        description: "Set dealer.id from path for events without body dealer field"
        enabled: true
        matcher: "event.provider == \"YOUR-APP\" and isNull(dealer.id) and isNotNull(path.dealer_id)"
        dql:
          script: "fieldsAdd dealer.id = toLong(path.dealer_id)"
```

---

## customId Constraints

- Length: 4–100 characters
- Characters: alphanumeric, hyphens, underscores
- Must NOT start with `dt.` or `dynatrace.`
- Must be unique across all pipelines

---

## Handling Updates

The `customId` must be unique. If you get "duplicate customId" error on `dtctl apply`, the pipeline was already created on a previous run. Get the `objectId` and add it to the YAML:

```bash
dtctl get settings --schema builtin:openpipeline.bizevents.pipelines
# Copy objectId from result → add as first line of YAML
```

---

## Query-Time Alternative (Always Works)

Since OneAgent HTTP bizevents currently bypass OpenPipeline, use `parse` directly in DQL queries:

```dql
fetch bizevents, from: now()-24h
| filter event.provider == "YOUR-APP" and event.type == "biz.your.detail"
| parse req.path, "'/api/detail/' INT:path.branchid '/' LONG:path.dealer_id '/' LONG:path.item_id"
| summarize count=count(), by: path.dealer_id
| sort count desc
```

This works 100% for all events regardless of OpenPipeline routing.

---

## Verify Enrichment is Working

After deploying the pipeline, check new events (last 5 minutes):

```dql
fetch bizevents, from: now()-5m
| filter event.provider == "YOUR-APP"
| summarize total=count(), enriched=countIf(isNotNull(path.dealer_id)), by: event.type
```

If `enriched = 0` for all types, check:
1. The `matcher` expression — test it against a sample event
2. Whether OneAgent bizevents flow through the pipeline (they may not)
3. The `matchesValue` regex pattern matches actual path values
