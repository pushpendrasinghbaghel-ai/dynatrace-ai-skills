#!/usr/bin/env bash
# Diagnose and enable Dynatrace Session Replay / RUM on Grail for the new Gen3 apps.
# Idempotent: existing settings objects are UPDATED (objectId reused); missing ones CREATED.
# Requires: dtctl (authenticated) and jq on PATH.
#
# Usage:
#   ./enable-session-replay.sh --diagnose-only
#   ./enable-session-replay.sh --context my-tenant --dry-run
#   ./enable-session-replay.sh --context my-tenant --recording-masking MASK_ALL --playback-masking MASK_ALL
set -euo pipefail

CONTEXT=""
REC_MASK="MASK_ALL"
PB_MASK="MASK_ALL"
CTC=100
DRY_RUN=0
DIAGNOSE_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context) CONTEXT="$2"; shift 2;;
    --recording-masking) REC_MASK="$2"; shift 2;;
    --playback-masking) PB_MASK="$2"; shift 2;;
    --cost-and-traffic-control) CTC="$2"; shift 2;;
    --dry-run) DRY_RUN=1; shift;;
    --diagnose-only) DIAGNOSE_ONLY=1; shift;;
    *) echo "Unknown arg: $1" >&2; exit 2;;
  esac
done

CTX=(); [[ -n "$CONTEXT" ]] && CTX=(--context "$CONTEXT")
dt() { dtctl "$@" "${CTX[@]}"; }
dq() { local f; f="$(mktemp)"; printf '%s' "$1" > "$f"; dt query -f "$f" -o json --plain; rm -f "$f"; }

echo "== Context =="
dt auth whoami --plain 2>&1 | grep -E 'Context|Environment' || true

echo; echo "== Diagnose: RUM data in Grail =="
dq 'fetch user.sessions, from:now()-7d
| summarize sessions=count(), with_replay=countIf(characteristics.has_replay==true), earliest=min(start_time), latest=max(start_time)' | jq '.records'
echo -n "Replay records (7d): "
dq 'fetch user.replays, from:now()-7d | summarize replays=count()' | jq -r '.records[0].replays // 0'

[[ "$DIAGNOSE_ONLY" -eq 1 ]] && { echo "diagnose-only set - stopping."; exit 0; }

echo; echo "== Discover web applications =="
APPS_JSON="$(dq 'fetch dt.entity.application | fields id, entity.name | limit 200' | jq -c '.records')"
echo "$APPS_JSON" | jq -r '.[] | " - \(.id)  (\(."entity.name"))"'

# scope -> objectId maps for idempotent updates
map_of() { dt get settings --schema "$1" -o json --plain 2>/dev/null | jq -c 'map({(.scope): .objectId}) | add // {}'; }
EN_MAP="$(map_of builtin:rum.web.enablement)"
RC_MAP="$(map_of builtin:sessionreplay.web.resource-capturing)"
PP_MAP="$(map_of builtin:sessionreplay.web.privacy-preferences)"

EN_VALUE="$(jq -n --argjson ctc "$CTC" '{rum:{enabled:true,enabledOnGrail:true,costAndTrafficControl:$ctc}, sessionReplay:{enabled:true,enabledOnGrail:true,costAndTrafficControl:$ctc}}')"
RC_VALUE='{"enableResourceCapturing":true,"resourceCaptureUrlExclusionPatternList":[]}'
PP_VALUE="$(jq -n --arg pb "$PB_MASK" --arg rec "$REC_MASK" '{enableOptInMode:false, maskingPresets:{playbackMaskingPreset:$pb, recordingMaskingPreset:$rec}, urlExclusionPatternList:[]}')"

# Build the settings array
doc() { # schemaId scope valueJson mapJson
  local schema="$1" scope="$2" value="$3" map="$4"
  local oid; oid="$(echo "$map" | jq -r --arg s "$scope" '.[$s] // empty')"
  if [[ -n "$oid" ]]; then
    jq -n --arg o "$oid" --arg s "$schema" --arg sc "$scope" --argjson v "$value" '{objectId:$o, schemaId:$s, scope:$sc, value:$v}'
  else
    jq -n --arg s "$schema" --arg sc "$scope" --argjson v "$value" '{schemaId:$s, scope:$sc, value:$v}'
  fi
}

DOCS="[]"
add() { DOCS="$(jq -c --argjson d "$1" '. + [$d]' <<< "$DOCS")"; }

add "$(doc builtin:rum.web.enablement environment "$EN_VALUE" "$EN_MAP")"
while read -r appid; do
  [[ -z "$appid" ]] && continue
  add "$(doc builtin:rum.web.enablement                 "$appid" "$EN_VALUE" "$EN_MAP")"
  add "$(doc builtin:sessionreplay.web.resource-capturing "$appid" "$RC_VALUE" "$RC_MAP")"
  add "$(doc builtin:sessionreplay.web.privacy-preferences "$appid" "$PP_VALUE" "$PP_MAP")"
done < <(echo "$APPS_JSON" | jq -r '.[].id')

PAYLOAD="$(mktemp)"; echo "$DOCS" > "$PAYLOAD"
COUNT="$(jq 'length' <<< "$DOCS")"

echo; echo "== Apply ($COUNT settings objects)$([[ $DRY_RUN -eq 1 ]] && echo ' [DRY-RUN]') =="
if [[ "$DRY_RUN" -eq 1 ]]; then
  dt apply -f "$PAYLOAD" --dry-run -o json --plain
  rm -f "$PAYLOAD"; echo "Dry-run only - nothing persisted."; exit 0
fi
dt apply -f "$PAYLOAD" -o json --plain
rm -f "$PAYLOAD"

echo; echo "== Verify =="
echo -n "rum.web.enablement objects:   "; dt get settings --schema builtin:rum.web.enablement -o json --plain | jq 'length'
echo -n "resource-capturing objects:   "; dt get settings --schema builtin:sessionreplay.web.resource-capturing -o json --plain | jq 'length'
echo -n "privacy-preferences objects:  "; dt get settings --schema builtin:sessionreplay.web.privacy-preferences -o json --plain | jq 'length'
echo
echo "Open the new Sessions / Session Replay app with a Today / Last-4h timeframe."
echo "Settings apply to NEWLY captured sessions (no historical backfill into Grail)."
