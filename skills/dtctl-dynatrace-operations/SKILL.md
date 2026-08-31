---
name: dtctl-dynatrace-operations
description: "Operate Dynatrace safely with dtctl for common SE and admin workflows. Use when: onboarding a tenant into dtctl, running DQL queries, exporting or applying settings YAML, promoting config across tenants, checking the current context, or troubleshooting dtctl auth and token-ref issues."
argument-hint: "Goal and tenant context, e.g. 'run DQL for checkout service on HID tenant' or 'apply alert settings YAML to xqv46417'"
metadata:
  category: tenant-control-plane
  code-specific: "true"
---

# Dynatrace dtctl Operations

Use this as the local CLI playbook for day-to-day Dynatrace work with `dtctl`.

## Authoritative references

- [dtctl repository](https://github.com/dynatrace-oss/dtctl) — canonical CLI behavior and command surface.
- [Dynatrace MCP server docs](https://docs.dynatrace.com/docs/shortlink/dynatrace-mcp-server) — relevant when dtctl onboarding is paired with MCP setup.
- [Dynatrace Platform Services](https://developer.dynatrace.com/develop/platform-services/) — platform capability context behind the queries and configuration you manage.

## Grounding notes

The CLI usage patterns here are grounded in the `dtctl` tool surface and adjacent Dynatrace docs. The ordering, guardrails, and troubleshooting flow are operational SE guidance for safe repeatable execution.

## When to Use

- You need to run a DQL query from the command line.
- You need to create or switch a tenant context in `dtctl`.
- You want to deploy a settings YAML file with `dtctl apply -f`.
- You need to verify which tenant you are about to change.
- You hit auth or token-reference issues and need a predictable recovery path.

## Phase 1 - Check the active context first

Always confirm the target tenant before querying or applying changes:

```bash
dtctl version
dtctl config current-context
```

If the expected tenant is not active, switch it explicitly:

```bash
dtctl config use-context <nickname>
```

## Phase 2 - Create or repair a tenant context

Create the base context:

```bash
dtctl config set-context <nickname> --environment https://<TENANT_ID>.apps.dynatrace.com
```

Authenticate with a token already provided by the user:

```bash
dtctl config set-credentials <nickname> --token <TOKEN>
dtctl config set-context <nickname> --environment https://<TENANT_ID>.apps.dynatrace.com --token-ref <nickname>
```

Or use the OAuth browser flow:

```bash
dtctl auth login --context <nickname> --environment https://<TENANT_ID>.apps.dynatrace.com
```

If queries fail with `token "" not found`, re-run `set-context` with the correct `--token-ref`.

## Phase 3 - Run DQL from dtctl

Minimal connectivity query:

```bash
dtctl query "fetch dt.entity.host | limit 1"
```

Service-level troubleshooting example:

```bash
dtctl query "fetch spans, from: now()-30m | filter dt.entity.service == \"SERVICE-XXXX\" | summarize count=count()"
```

Log sample example:

```bash
dtctl query "fetch logs, from: now()-30m | filter matchesPhrase(content, \"error\") | limit 20"
```

Rules:

- Keep time windows tight first.
- Prefer known entity filters over broad scans.
- Persist reusable DQL in files when the same query will be reused across customers.

## Phase 4 - Apply settings as code

For versioned YAML:

```bash
dtctl apply -f 02-settings\my-object.yaml
```

Recommended file pattern:

```yaml
schemaId: <schema-id>
scope: environment
objectId: "<existing-object-id>"
value:
  enabled: true
```

Create/update guidance:

- Omit `objectId` on first create.
- Write the returned `objectId` back for later updates.
- Re-apply the same file for in-place updates.

## Phase 5 - Export, inspect, and verify

Use `dtctl` to inspect what exists before editing. If the exact command/resource shape is uncertain, discover it first from the tenant or docs instead of guessing.

After any apply:

1. confirm the object exists,
2. confirm the expected values are present,
3. run one DQL or product-specific smoke test tied to the change.

## Phase 6 - Typical tasks this skill covers

- tenant onboarding
- DQL execution
- settings lifecycle
- preflight environment verification
- cross-tenant promotion with file-based artifacts

For tenant-wide inventory, export/import loops, drift checks, and broader control-plane work, escalate to [dtctl-tenant-admin](../dtctl-tenant-admin/SKILL.md).

## Common failure modes

- wrong current context
- token saved but not referenced with `--token-ref`
- broad DQL query causing noise or cost
- settings file updated locally but `objectId` missing, creating duplicates
- changing the right schema in the wrong tenant

## Checklist

- [ ] `dtctl version` works
- [ ] correct context is active
- [ ] connectivity query succeeds
- [ ] DQL is scoped to the use case
- [ ] settings file is versioned and reviewable
- [ ] `dtctl apply -f` result is verified
