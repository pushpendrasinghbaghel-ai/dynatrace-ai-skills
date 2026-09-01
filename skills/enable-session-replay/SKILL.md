---
name: enable-session-replay
description: Diagnose and enable Dynatrace Session Replay / RUM for the new Gen3 (Grail-based) apps using dtctl. Use whenever a user reports "session replay not visible in the new app", "sessions missing in the new Sessions/Session Replay app but present in classic", "enable session replay on Grail", "RUM data not in Grail", "replays don't render / look blank", or wants to compare/align RUM Session Replay settings between tenants. Covers the difference between classic and Grail-based RUM, the exact settings schemas to enable, verification via DQL, and required Grail read permissions.
argument-hint: "Optional dtctl context/tenant to target, e.g. 'my-tenant' (defaults to the current dtctl context)"
metadata:
  category: tenant-control-plane
  code-specific: "true"
---

# Enable Dynatrace Session Replay (RUM on Grail)

Diagnose why RUM sessions / Session Replay show in the **classic** apps but not the **new Gen3 (Grail-based)** apps, and enable the required settings with `dtctl`.

> Prerequisite: the `dtctl` CLI is configured and pointed at the target tenant. Confirm with `dtctl auth whoami --plain` and `dtctl config current-context`. All commands below assume the current context is the target tenant; add `--context <name>` to target another.

## Bundled harness (fastest path)

This skill ships runnable automation and templates:

```
enable-session-replay/
  scripts/
    enable-session-replay.ps1   # Windows/PowerShell: diagnose -> enable -> verify (idempotent)
    enable-session-replay.sh     # macOS/Linux (needs dtctl + jq)
  assets/
    diagnostics.dql                        # copy/paste diagnostic queries
    rum-web-enablement.template.json       # builtin:rum.web.enablement
    resource-capturing.template.json       # builtin:sessionreplay.web.resource-capturing
    privacy-preferences.template.json      # builtin:sessionreplay.web.privacy-preferences
  references/
    settings-schema-reference.md           # field-level reference for all 3 schemas
```

The script auto-discovers every web application, then enables RUM+Session Replay on Grail, resource
capturing, and masking for each app **and** the `environment` default — updating existing settings
objects in place (idempotent). Always preview first:

```bash
# PowerShell
./scripts/enable-session-replay.ps1 -Context <tenant> -DiagnoseOnly       # just inspect
./scripts/enable-session-replay.ps1 -Context <tenant> -DryRun             # preview changes
./scripts/enable-session-replay.ps1 -Context <tenant>                     # apply

# bash
./scripts/enable-session-replay.sh --context <tenant> --diagnose-only
./scripts/enable-session-replay.sh --context <tenant> --dry-run
./scripts/enable-session-replay.sh --context <tenant>
```

Prefer the script for the end-to-end fix; use the manual steps below to understand or customize it.

## Core concept — why the new app is empty

- **Classic** RUM apps (User Sessions, classic Session Replay) read the **legacy session store**.
- **New Gen3** apps (Sessions / Session Replay powered by Grail) read **Grail** tables:
  - `user.sessions`  (buckets `default_user_sessions`, `default_synthetic_user_sessions`)
  - `user.replays`   (buckets `default_web_user_replays`, `default_mobile_user_replays`)
- If RUM data is not being written to Grail, the new apps are empty even though classic works.

**Three independent things must be true for replays to show and render in the new app:**
1. `rum.enabledOnGrail = true` — RUM sessions are written to Grail.
2. `sessionReplay.enabled = true` **and** `sessionReplay.enabledOnGrail = true` — replays are captured and written to Grail.
3. `resource-capturing` `enableResourceCapturing = true` — CSS/images/fonts are captured so the replay renders faithfully (without it replays can look blank/unstyled).

Plus: the **viewing user** needs Grail read permissions (see Permissions section), and the app **timeframe** must cover when Grail data started.

## Step 1 — Diagnose: is RUM data actually in Grail?

```bash
# Do the Grail RUM tables have data, and how recent?
dtctl query 'fetch user.sessions, from:now()-7d
| summarize sessions=count(), with_replay=countIf(characteristics.has_replay==true), earliest=min(start_time), latest=max(start_time)' -o json --plain

dtctl query 'fetch user.replays, from:now()-7d | summarize replays=count(), by:{dt.system.bucket}' -o json --plain
```

Interpretation:
- `sessions = 0` → RUM is **not** flowing to Grail → fix settings in Step 2.
- `sessions > 0` but `earliest` is only a few hours old → Grail RUM was **recently enabled**; the new app only shows data from that point forward (classic keeps full history). Widen the app timeframe (Today / Last 4h) — RUM ingest is often **bursty**, so a 30-minute window can look empty.
- `with_replay = 0` → sessions are in Grail but replays aren't being captured/stored → check `sessionReplay.*` and `resource-capturing` in Step 2.

> Note: `user.sessions` records use `start_time` / `end_time`, **not** `timestamp`. `min(timestamp)` returns null — always use `start_time` for recency.

Confirm the buckets exist and you have access:

```bash
dtctl query 'fetch dt.system.buckets' -o json --plain
# look for default_user_sessions / default_web_user_replays; has_access should be true
```

## Step 2 — Enable the required settings

Three schemas control this. Inspect current state first (all scopes: `environment` default + per-`APPLICATION-*` overrides). A per-application object **overrides** the environment default.

```bash
dtctl get settings --schema builtin:rum.web.enablement -o json --plain
dtctl get settings --schema builtin:sessionreplay.web.resource-capturing -o json --plain
dtctl get settings --schema builtin:sessionreplay.web.privacy-preferences -o json --plain
```

Map application IDs to names:

```bash
dtctl query 'fetch dt.entity.application | fields id, entity.name | limit 100' -o json --plain
```

### 2a. RUM + Session Replay enablement (`builtin:rum.web.enablement`)

Target value (per application **and** the `environment` default so new apps inherit it):

```json
{
  "rum":           { "enabled": true, "enabledOnGrail": true, "costAndTrafficControl": 100 },
  "sessionReplay": { "enabled": true, "enabledOnGrail": true, "costAndTrafficControl": 100 }
}
```

Apply. **Updating an existing object requires its `objectId`** (get it from the `get settings` output above); **creating a new one omits `objectId`**.

```jsonc
// rum-enablement.json  (environment scope example — include "objectId" when updating)
{
  "objectId": "<paste-from-get-settings-or-omit-to-create>",
  "schemaId": "builtin:rum.web.enablement",
  "scope": "environment",
  "value": {
    "rum":           { "enabled": true, "enabledOnGrail": true, "costAndTrafficControl": 100 },
    "sessionReplay": { "enabled": true, "enabledOnGrail": true, "costAndTrafficControl": 100 }
  }
}
```

```bash
dtctl apply -f rum-enablement.json --dry-run -o json --plain   # validate
dtctl apply -f rum-enablement.json -o json --plain             # deploy
```

For a specific app, set `"scope": "APPLICATION-XXXXXXXXXXXXXXXX"`.

### 2b. Resource capturing (`builtin:sessionreplay.web.resource-capturing`)

Makes replays render faithfully. **Commonly missing** — a tenant can capture replays yet show blank playback without it. Create one per application scope:

```json
{
  "schemaId": "builtin:sessionreplay.web.resource-capturing",
  "scope": "APPLICATION-XXXXXXXXXXXXXXXX",
  "value": { "enableResourceCapturing": true, "resourceCaptureUrlExclusionPatternList": [] }
}
```

### 2c. Privacy / masking (`builtin:sessionreplay.web.privacy-preferences`)

Controls masking during recording & playback. `MASK_ALL` is the privacy-safe default (recommended for finance/PII-sensitive tenants). Create one per application scope:

```json
{
  "schemaId": "builtin:sessionreplay.web.privacy-preferences",
  "scope": "APPLICATION-XXXXXXXXXXXXXXXX",
  "value": {
    "enableOptInMode": false,
    "maskingPresets": { "playbackMaskingPreset": "MASK_ALL", "recordingMaskingPreset": "MASK_ALL" },
    "urlExclusionPatternList": []
  }
}
```

Masking preset options: `MASK_ALL` (mask all text/inputs/images), `MASK_USER_INPUT` (mask only user input), `ALLOW_ALL` (no masking — avoid for PII). Playback preset can be stricter than recording. Custom `*BlockListRules` / `*AllowListRules` with CSS selectors are also supported.

> Tip: `dtctl apply -f file.json` accepts a **JSON array** of settings objects, so you can create resource-capturing + privacy-preferences for all applications in one call.

## Step 3 — Verify

```bash
# Settings present on every app + environment
dtctl get settings --schema builtin:rum.web.enablement -o json --plain
dtctl get settings --schema builtin:sessionreplay.web.resource-capturing -o json --plain
dtctl get settings --schema builtin:sessionreplay.web.privacy-preferences -o json --plain

# New RUM sessions/replays landing in Grail (use start_time, wide window)
dtctl query 'fetch user.sessions, from:now()-4h
| summarize sessions=count(), with_replay=countIf(characteristics.has_replay==true), by:{frontend.name}
| sort sessions desc' -o json --plain
```

Then open the new **Sessions / Session Replay** app with a **Today / Last 4h** timeframe. Settings apply to **newly captured** sessions going forward (no backfill of historical replays into Grail).

## Permissions — if data exists in Grail but the user still can't see it

The Gen3 apps enforce Grail read permissions per user (classic uses a different model, which is why classic still works). Ensure the viewing user's IAM policy grants (Account Management → Policies, **not** environment settings):

- `storage:user.sessions:read`
- `storage:user.events:read`
- `storage:user.replays:read`
- `storage:bizevents:read`
- `storage:buckets:read`

## Compare two tenants (align a broken tenant to a working one)```bash
# Working reference tenant vs target — diff each schema
dtctl get settings --schema builtin:rum.web.enablement --context <working> -o json --plain
dtctl get settings --schema builtin:rum.web.enablement --context <target>  -o json --plain
# repeat for sessionreplay.web.resource-capturing and sessionreplay.web.privacy-preferences
```

Common gaps that make the new app empty on the target while a reference tenant works:
1. `environment` `sessionReplay.enabled = false` (or `enabledOnGrail` unset).
2. **No** `resource-capturing` objects at all → replays don't render.
3. **No** `privacy-preferences` objects → relying on implicit defaults.

## Gotchas checklist

- [ ] `rum.enabledOnGrail = true` (sessions → Grail)
- [ ] `sessionReplay.enabled = true` **and** `enabledOnGrail = true` (replays → Grail)
- [ ] `enableResourceCapturing = true` per app (faithful rendering)
- [ ] Privacy/masking configured (default to `MASK_ALL` for PII-sensitive tenants)
- [ ] Set both the `environment` default **and** each existing `APPLICATION-*` (per-app overrides win)
- [ ] Use `start_time` (not `timestamp`) when checking `user.sessions` recency
- [ ] App timeframe covers when Grail data started; account for bursty ingest
- [ ] Viewing user has `storage:user.*:read` / `storage:buckets:read` Grail permissions
- [ ] Include `objectId` to update, omit to create; validate with `--dry-run` first
