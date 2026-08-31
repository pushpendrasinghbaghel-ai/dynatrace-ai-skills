---
name: dtctl-tenant-admin
description: "Manage a Dynatrace tenant end-to-end with dtctl when you need broad control-plane operations: discovery, queries, settings export/import, bulk config changes, drift checks, safe rollback, and workspace-driven repeatability."
argument-hint: "Tenant nickname or ID and the control-plane goal, e.g. 'audit and update tenant xqv46417' or 'export all alert and workflow settings for HID'"
metadata:
  category: tenant-control-plane
  code-specific: "true"
---

# Dynatrace dtctl Tenant Admin

Use this when you want the agent to operate the tenant like a control plane, not just run one-off commands.

This is your **tenant-control-plane** skill for broad dtctl management.

## Authoritative references

- [dtctl repository](https://github.com/dynatrace-oss/dtctl) — canonical CLI behavior and command surface.
- [Dynatrace Platform Services](https://developer.dynatrace.com/develop/platform-services/) — platform capability context behind tenant-level operations.
- [Dynatrace MCP server docs](https://docs.dynatrace.com/docs/shortlink/dynatrace-mcp-server) — useful when dtctl work happens alongside MCP-based tenant access.

## Grounding notes

This skill is grounded in the dtctl CLI and Dynatrace platform docs. The deeper procedures below are a repeatable control-plane pattern for SE POCs: inventory first, change second, verify third, rollback always available.

## When to Use

- You need to understand what is deployed in a tenant before touching it.
- You want to export, review, update, and re-import settings in a controlled loop.
- You need a fast tenant-wide smoke test before a demo or workshop.
- You need to detect drift between intended config and actual tenant config.
- You want a reusable dtctl workspace that can survive multiple customer sessions.

## The control-plane loop

Think in this order:

1. **Inventory** — what exists?
2. **Scope** — what do I need to change?
3. **Edit** — change only the minimal files.
4. **Apply** — push with `dtctl`.
5. **Verify** — query or inspect the tenant.
6. **Rollback** — keep a known-good copy ready.

If you skip inventory, you tend to make the wrong change in the wrong tenant.

## Phase 1 - Build a workspace

Create a tenant-specific folder so all commands, exports, and queries stay together:

```text
pocs/<account>-<usecase>/
  01-tenant/
  02-settings/
  03-ingest/
  05-validation/
```

Put in it:

- `context.md`
- `inventory.md`
- exported YAML/JSON
- reusable DQL files
- rollback notes

## Phase 2 - Confirm context and tenant health

```bash
dtctl version
dtctl config current-context
dtctl query "fetch dt.entity.host | limit 1"
```

If the tenant is wrong, switch before doing anything else:

```bash
dtctl config use-context <nickname>
```

If auth fails, repair the stored credentials or token reference before trying to work around it.

## Phase 3 - Inventory the tenant

Use dtctl to discover what matters for the POC:

- settings objects
- alerting config
- workflows / routes
- services / hosts / problems
- business events or ingest artifacts

Keep the queries small and reusable. Save them to files in the workspace so future runs do not have to rediscover the same inventory.

Example inventory queries:

```bash
dtctl query "fetch dt.entity.service | limit 50"
dtctl query "fetch dt.entity.host | limit 50"
dtctl query "fetch problems, from: now()-24h | limit 20"
dtctl query "fetch logs, from: now()-30m | limit 20"
```

If a surface needs an upstream skill for better analysis, note that in `inventory.md` instead of pretending the CLI alone is enough.

## Phase 4 - Export before you edit

Before editing anything important:

1. export the current object or object set,
2. store it under the workspace,
3. record the object IDs,
4. note the intended diff.

That gives you a clean rollback path and makes the change reviewable.

## Phase 5 - Bulk changes safely

For repeated changes across many similar objects:

- normalize the YAML first,
- keep one object per file when possible,
- use consistent naming,
- apply in a controlled batch,
- verify after each logical batch instead of waiting until the end.

Do not make a huge multi-tenant or multi-object change without a checkpoint.

## Phase 6 - Drift check

After applying changes, compare:

- what the file says,
- what the tenant now has,
- what the POC success criteria require.

If the drift is caused by a missing upstream capability, document the gap and switch the lane to the correct upstream skill or fallback.

Run a drift check after every significant batch so the tenant-control-plane state stays aligned with the intended files.

## Phase 7 - Tenant recovery and rollback

Maintain:

- previous exports,
- a known-good snapshot,
- the exact commands used,
- the order of operations.

Rollback options:

1. re-apply the last good export,
2. disable the object,
3. restore the previous objectId-backed file,
4. only delete if the object is clearly disposable.

## What this skill is good for

- tenant audits
- tenant-wide smoke tests
- settings export/import loops
- drift detection
- config promotion between environments
- high-volume control-plane changes

## What this skill does not replace

- dashboard/notebook building
- deep observability analysis
- brand packaging
- OpenPipeline parsing design

Those still belong to the dedicated skills and upstream repo where appropriate.

## Checklist

- [ ] correct context confirmed
- [ ] inventory captured before edits
- [ ] exports stored before changes
- [ ] changes applied in controlled batches
- [ ] tenant verified after each batch
- [ ] rollback path preserved
