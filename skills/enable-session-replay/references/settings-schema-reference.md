# Settings schema reference — Session Replay / RUM on Grail

Field-level reference for the three schemas this skill manages. Verify against the live tenant with
`dtctl describe schema <schemaId> -o json --plain` if a value is rejected.

## builtin:rum.web.enablement
Scope: `environment` (default) or `APPLICATION-XXXXXXXXXXXXXXXX` (per-app override wins).

| Path | Type | Notes |
|---|---|---|
| `rum.enabled` | boolean | Capture RUM at all. |
| `rum.enabledOnGrail` | boolean | **Write RUM sessions to Grail** (`user.sessions`). Required for the Gen3 Sessions app. |
| `rum.costAndTrafficControl` | int (1–100) | % of traffic captured. |
| `sessionReplay.enabled` | boolean | Capture Session Replay. |
| `sessionReplay.enabledOnGrail` | boolean | **Write replays to Grail** (`user.replays`). Required for the Gen3 Session Replay app. |
| `sessionReplay.costAndTrafficControl` | int (1–100) | % of sessions replayed. |
| `experienceAnalytics.enabled` | boolean | Optional; present on some apps. |

## builtin:sessionreplay.web.resource-capturing
Scope: `APPLICATION-XXXXXXXXXXXXXXXX`.

| Path | Type | Notes |
|---|---|---|
| `enableResourceCapturing` | boolean | Capture CSS/images/fonts so playback renders faithfully. Frequently missing. |
| `resourceCaptureUrlExclusionPatternList` | string[] | URLs to exclude from resource capture. |

## builtin:sessionreplay.web.privacy-preferences
Scope: `APPLICATION-XXXXXXXXXXXXXXXX`.

| Path | Type | Notes |
|---|---|---|
| `enableOptInMode` | boolean | If true, replay only records after explicit end-user opt-in. |
| `maskingPresets.recordingMaskingPreset` | enum | `MASK_ALL` \| `MASK_USER_INPUT` \| `ALLOW_ALL`. What is masked at capture time. |
| `maskingPresets.playbackMaskingPreset` | enum | Same enum; what the analyst sees. May be stricter than recording. |
| `maskingPresets.recordingMaskingAllowListRules` / `...BlockListRules` | object[] | Optional CSS-selector rules (`cssExpression`, `target`, `hideUserInteraction`, …). |
| `urlExclusionPatternList` | string[] | URLs where replay is not recorded. |

Recommended defaults for PII/finance tenants: `recordingMaskingPreset = MASK_ALL`, `playbackMaskingPreset = MASK_ALL`, `enableOptInMode = false`.

## Grail data model (for verification)
- Table `user.sessions` — buckets `default_user_sessions`, `default_synthetic_user_sessions`. Time fields: `start_time`, `end_time` (NOT `timestamp`). Replay flag: `characteristics.has_replay`.
- Table `user.replays` — buckets `default_web_user_replays`, `default_mobile_user_replays`.

## Required Grail read permissions (viewing user, Account Management → Policies)
`storage:user.sessions:read`, `storage:user.events:read`, `storage:user.replays:read`, `storage:bizevents:read`, `storage:buckets:read`.
