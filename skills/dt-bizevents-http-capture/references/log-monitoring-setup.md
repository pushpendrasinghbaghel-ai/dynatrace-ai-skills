# IIS Log Monitoring Setup

When bizevents POST request body extraction fails (form-encoded body, non-JSON), enabling IIS access logs provides a second source for dealer ID, user ID, and other query parameters.

Schema: `builtin:logmonitoring.custom-log-source-settings`

---

## Why IIS Logs Help

IIS W3C access logs capture every HTTP request including:
- `uri-stem` — the URL path
- `uri-query` — query string parameters (for GET requests AND form POST query strings)
- `cs-method` — HTTP method
- `c-ip` — client IP (useful for cross-event correlation)
- `time-taken` — response time in ms
- `sc-status` — HTTP status code

Even for POST requests, if parameters are in the query string (e.g. `POST /api/Save?DealerCode=14144`), they appear in `uri-query`.

---

## Check if Logs Already Exist

```dql
fetch logs, from: now()-30m
| filter matchesPhrase(content, "/your/api/path")
| fields timestamp, content, log.source, dt.entity.host
| limit 5
```

If empty, the host either has no log monitoring or the log path isn't configured.

---

## Enable IIS Log Collection on a Host

```yaml
schemaId: builtin:logmonitoring.custom-log-source-settings
scope: HOST-XXXXXXXXXXXXXXXX    # The specific host entity ID
value:
  config-item-title: "App Name - IIS Access Logs"   # Must be unique
  enabled: true
  custom-log-source:
    type: LOG_PATH_PATTERN
    values-and-enrichment:
      - path: "C:\\inetpub\\logs\\LogFiles\\W3SVC*\\*.log"
        enrichment:
          - type: attribute
            key: "log.source.application"
            value: "your-app-iis"
```

### Find the Host Entity ID

```dql
fetch dt.entity.host, from: now()-1h
| filter matchesPhrase(entity.name, "your-hostname")
| fields entity.id, entity.name
```

Or from the Dynatrace UI: Infrastructure → Hosts → click host → entity ID in URL.

### Apply

```bash
dtctl apply -f iis-log-monitoring.yaml
```

OneAgent picks up the new log source configuration in ~2–5 minutes. Logs start flowing immediately after.

---

## Parse IIS Log Lines

IIS W3C log format (standard):
```
date time s-ip cs-method cs-uri-stem cs-uri-query s-port cs-username c-ip cs(User-Agent) cs(Referer) sc-status sc-substatus sc-win32-status sc-bytes cs-bytes time-taken
```

DQL parse pattern:
```dql
parse content, "LD:date ' ' LD:time ' ' LD:s_ip ' ' LD:method ' ' LD:uri_stem ' ' LD:uri_query ' ' LD:port ' ' LD:cs_username ' ' LD:c_ip ' '"
```

### Extract Specific Parameters from Query String

```dql
-- Extract DealerCode from query string
parse uri_query, "LD 'DealerCode=' LD:dealer_code '&'"

-- Extract multiple parameters
parse uri_query, "LD 'DealerCode=' LD:dealer_code '&' LD 'UserId=' LD:user_id '&'"

-- When parameter might be last (no trailing &)
parse uri_query, "LD 'DealerCode=' LD:dealer_code"
```

---

## Correlate IIS Logs with Bizevents

Since bizevents and IIS logs are separate streams, join them by **timestamp window** and **client IP** (if available in both), or just by timestamp if single-client scenarios.

### By Timestamp (Simple)

```dql
fetch logs, from: now()-1h
| filter log.source == "C:\\inetpub\\logs\\LogFiles\\W3SVC*\\*.log"
| filter matchesPhrase(content, "JobCard/Save")
| parse content, "LD:date ' ' LD:time ' ' LD:s_ip ' ' LD:method ' ' LD:uri_stem ' ' LD:uri_query ' '"
| parse uri_query, "LD 'DealerCode=' LD:dealer_code"
| filter isNotNull(dealer_code)
| fields timestamp, uri_stem, dealer_code
| sort timestamp desc
```

### Aggregate Dealer Activity from Logs

```dql
fetch logs, from: now()-24h
| filter log.source == "C:\\inetpub\\logs\\LogFiles\\W3SVC*\\*.log"
| filter matchesPhrase(content, "/wip/JobCard/Save")
| parse content, "LD:date ' ' LD:time ' ' LD:s_ip ' ' LD:method ' ' LD:uri_stem ' ' LD:uri_query ' ' LD:port ' ' LD:cs_username ' ' LD:c_ip ' ' LD:useragent ' ' LD:referer ' ' INT:status ' '"
| parse uri_query, "LD 'DealerCode=' LD:dealer_code"
| summarize save_count=count(), by: dealer_code
| sort save_count desc
```

---

## Log Storage — Ensure Logs Are Retained

By default, logs matching certain process types are stored. To ensure IIS logs are stored in Grail:

```bash
dtctl get settings --schema builtin:logmonitoring.log-storage-settings
```

If no rule covers IIS logs, add one:

```yaml
schemaId: builtin:logmonitoring.log-storage-settings
scope: environment
value:
  config-item-title: "Store IIS access logs"
  enabled: true
  matchers:
    - attribute: log.source
      operator: MATCHES
      values:
        - "*inetpub*"
        - "*W3SVC*"
  send-to-storage: true
```

---

## Sensitive Data Masking

IIS logs may contain PII. Dynatrace automatically masks some values. Check what's being masked:

```dql
fetch logs, from: now()-30m
| filter log.source == "C:\\inetpub\\logs\\LogFiles\\W3SVC*\\*.log"
| filter matchesPhrase(content, "masked-value")
| fields content
| limit 3
```

Values like `<masked-value-log>` indicate the log monitoring sensitive data masking rules are active. `UserId` and mobile numbers are typically masked. `DealerCode` may remain unmasked (it's not PII).

To view/modify masking rules: `dtctl get settings --schema builtin:logmonitoring.sensitive-data-masking-settings`
