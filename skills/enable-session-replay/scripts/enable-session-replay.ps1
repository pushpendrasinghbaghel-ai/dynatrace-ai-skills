<#
.SYNOPSIS
  Diagnose and enable Dynatrace Session Replay / RUM on Grail for the new Gen3 apps.

.DESCRIPTION
  Idempotent harness that:
    1. Diagnoses whether RUM sessions/replays are landing in Grail (user.sessions / user.replays).
    2. Discovers all web applications.
    3. Enables (per application AND the environment default):
         - builtin:rum.web.enablement                    (rum + sessionReplay: enabled + enabledOnGrail)
         - builtin:sessionreplay.web.resource-capturing  (enableResourceCapturing = true)
         - builtin:sessionreplay.web.privacy-preferences (masking presets)
       Existing objects are UPDATED (objectId reused); missing ones are CREATED.
    4. Verifies the resulting configuration.

  Requires: dtctl on PATH, authenticated (`dtctl auth whoami`).

.EXAMPLE
  ./enable-session-replay.ps1 -DiagnoseOnly
.EXAMPLE
  ./enable-session-replay.ps1 -Context my-tenant -DryRun
.EXAMPLE
  ./enable-session-replay.ps1 -Context my-tenant -RecordingMasking MASK_ALL -PlaybackMasking MASK_ALL
#>
[CmdletBinding()]
param(
  [string]$Context,
  [ValidateSet('MASK_ALL','MASK_USER_INPUT','ALLOW_ALL')][string]$RecordingMasking = 'MASK_ALL',
  [ValidateSet('MASK_ALL','MASK_USER_INPUT','ALLOW_ALL')][string]$PlaybackMasking  = 'MASK_ALL',
  [int]$CostAndTrafficControl = 100,
  [switch]$DryRun,
  [switch]$DiagnoseOnly
)

$ErrorActionPreference = 'Stop'

function Invoke-Dtctl {
  param([string[]]$DtArgs)
  $full = @($DtArgs)
  if ($Context) { $full += @('--context', $Context) }
  & dtctl @full 2>&1 | Out-String
}

function Dtctl-Json {
  param([string[]]$DtArgs)
  $raw = Invoke-Dtctl $DtArgs
  if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
  # dtctl may print a warning/notice line to stderr before the JSON; extract the JSON block.
  $start = $raw.IndexOfAny([char[]]@('{','['))
  if ($start -lt 0) { return $null }
  $json = $raw.Substring($start)
  try { return ($json | ConvertFrom-Json) }
  catch { Write-Warning "dtctl JSON parse failed: $($_.Exception.Message)"; Write-Verbose $raw; return $null }
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Dtctl-QueryRecords([string]$dql) {
  $tmp = New-TemporaryFile
  [System.IO.File]::WriteAllText($tmp.FullName, $dql, $utf8NoBom)
  try {
    $o = Dtctl-Json @('query','-f',$tmp.FullName,'-o','json','--plain')
    if ($o -and $o.records) { return @($o.records) } else { return @() }
  } finally { Remove-Item $tmp.FullName -ErrorAction SilentlyContinue }
}

function Dtctl-GetSettings([string]$schema) {
  $o = Dtctl-Json @('get','settings','--schema',$schema,'-o','json','--plain')
  if ($o) { return @($o) } else { return @() }
}

Write-Host "== Context ==" -ForegroundColor Cyan
(Invoke-Dtctl @('auth','whoami','--plain')) -split "`r?`n" | Select-String -Pattern 'Context|Environment'

# ---------------------------------------------------------------- 1. Diagnose
Write-Host "`n== Diagnose: RUM data in Grail ==" -ForegroundColor Cyan
$sess = @(Dtctl-QueryRecords 'fetch user.sessions, from:now()-7d | summarize sessions=count(), with_replay=countIf(characteristics.has_replay==true), earliest=min(start_time), latest=max(start_time)')
if ($sess.Count) { $sess | Format-List } else { Write-Host "(user.sessions returned no rows - RUM may not be flowing to Grail)" -ForegroundColor Yellow }
$rep = @(Dtctl-QueryRecords 'fetch user.replays, from:now()-7d | summarize replays=count()')
$replayCount = if ($rep.Count) { $rep[0].replays } else { 0 }
Write-Host ("Replay records (7d): " + $replayCount)

if ($DiagnoseOnly) { Write-Host "`nDiagnoseOnly set - stopping." -ForegroundColor Yellow; return }

# ---------------------------------------------------------------- 2. Discover apps
Write-Host "`n== Discover web applications ==" -ForegroundColor Cyan
$apps = @(Dtctl-QueryRecords 'fetch dt.entity.application | fields id, entity.name | limit 200')
if (-not $apps.Count) { throw "No applications found (fetch dt.entity.application returned nothing)." }
$apps | ForEach-Object { Write-Host (" - {0}  ({1})" -f $_.id, $_.'entity.name') }

# ---------------------------------------------------------------- Build desired state
$enMap = @{}; Dtctl-GetSettings 'builtin:rum.web.enablement'                   | ForEach-Object { $enMap[$_.scope] = $_.objectId }
$rcMap = @{}; Dtctl-GetSettings 'builtin:sessionreplay.web.resource-capturing'  | ForEach-Object { $rcMap[$_.scope] = $_.objectId }
$ppMap = @{}; Dtctl-GetSettings 'builtin:sessionreplay.web.privacy-preferences' | ForEach-Object { $ppMap[$_.scope] = $_.objectId }

$docs = New-Object System.Collections.ArrayList
function Add-Doc($schemaId, $scope, $value, $objectId) {
  if ($objectId) { [void]$docs.Add([ordered]@{ objectId = $objectId; schemaId = $schemaId; scope = $scope; value = $value }) }
  else           { [void]$docs.Add([ordered]@{ schemaId = $schemaId; scope = $scope; value = $value }) }
}

$enValue = [ordered]@{
  rum           = [ordered]@{ enabled = $true; enabledOnGrail = $true; costAndTrafficControl = $CostAndTrafficControl }
  sessionReplay = [ordered]@{ enabled = $true; enabledOnGrail = $true; costAndTrafficControl = $CostAndTrafficControl }
}
$rcValue = [ordered]@{ enableResourceCapturing = $true; resourceCaptureUrlExclusionPatternList = @() }
$ppValue = [ordered]@{
  enableOptInMode = $false
  maskingPresets  = [ordered]@{ playbackMaskingPreset = $PlaybackMasking; recordingMaskingPreset = $RecordingMasking }
  urlExclusionPatternList = @()
}

Add-Doc 'builtin:rum.web.enablement' 'environment' $enValue $enMap['environment']
foreach ($a in $apps) {
  Add-Doc 'builtin:rum.web.enablement'                    $a.id $enValue $enMap[$a.id]
  Add-Doc 'builtin:sessionreplay.web.resource-capturing'  $a.id $rcValue $rcMap[$a.id]
  Add-Doc 'builtin:sessionreplay.web.privacy-preferences' $a.id $ppValue $ppMap[$a.id]
}

$payload = New-TemporaryFile
[System.IO.File]::WriteAllText($payload.FullName, ($docs | ConvertTo-Json -Depth 10), $utf8NoBom)

# ---------------------------------------------------------------- 3. Apply
Write-Host "`n== Apply ($($docs.Count) settings objects)$(if($DryRun){' [DRY-RUN]'}) ==" -ForegroundColor Cyan
$applyArgs = @('apply','-f', $payload.FullName, '-o','json','--plain')
if ($DryRun) { $applyArgs += '--dry-run' }
Invoke-Dtctl $applyArgs
Remove-Item $payload.FullName -ErrorAction SilentlyContinue

if ($DryRun) { Write-Host "`nDry-run only - nothing persisted." -ForegroundColor Yellow; return }

# ---------------------------------------------------------------- 4. Verify
Write-Host "`n== Verify ==" -ForegroundColor Cyan
Write-Host ("rum.web.enablement objects:   " + @(Dtctl-GetSettings 'builtin:rum.web.enablement').Count)
Write-Host ("resource-capturing objects:   " + @(Dtctl-GetSettings 'builtin:sessionreplay.web.resource-capturing').Count)
Write-Host ("privacy-preferences objects:  " + @(Dtctl-GetSettings 'builtin:sessionreplay.web.privacy-preferences').Count)
Write-Host "`nOpen the new Sessions / Session Replay app with a Today / Last-4h timeframe."
Write-Host "Settings apply to NEWLY captured sessions (no historical backfill into Grail)."
