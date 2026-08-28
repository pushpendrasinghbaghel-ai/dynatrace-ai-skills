param(
    [string]$RepoRoot = "",
    [double]$MinPassRate = 1.0
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$manifestPath = Join-Path $RepoRoot "agent-skill-manifest.json"
$skillsRoot = Join-Path $RepoRoot "skills"
$reportsRoot = Join-Path $RepoRoot "harness\reports"
New-Item -ItemType Directory -Path $reportsRoot -Force | Out-Null

if (-not (Test-Path $manifestPath)) {
    throw "Missing agent skill manifest: $manifestPath"
}

$manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
$manifestSkillNames = @($manifest.localSkills | ForEach-Object { $_.name })
$skillDirs = Get-ChildItem -Path $skillsRoot -Directory

$results = @()

foreach ($skillDir in $skillDirs) {
    $skillFile = Join-Path $skillDir.FullName "SKILL.md"
    if (-not (Test-Path $skillFile)) {
        continue
    }

    $skillName = $skillDir.Name
    $inManifest = $manifestSkillNames -contains $skillName

    $results += [pscustomobject]@{
        skill = $skillName
        inManifest = $inManifest
        passed = $inManifest
        details = if ($inManifest) { "Present in agent manifest" } else { "Missing from agent-skill-manifest.json" }
    }
}

$summary = [pscustomobject]@{
    suite = "agent-skill-sync"
    total = $results.Count
    passed = @($results | Where-Object { $_.passed }).Count
    failed = @($results | Where-Object { -not $_.passed }).Count
    passRate = 0
    generatedAt = (Get-Date).ToString("o")
}
$summary.passRate = if ($summary.total -gt 0) { [math]::Round($summary.passed / $summary.total, 4) } else { 0 }

$report = [pscustomobject]@{
    summary = $summary
    results = $results
}

$outFile = Join-Path $reportsRoot "agent-skill-sync-report.json"
$report | ConvertTo-Json -Depth 6 | Set-Content -Path $outFile -Encoding UTF8

Write-Host "Agent skill sync tests complete: $($summary.passed)/$($summary.total) passed"
Write-Host "Pass rate: $($summary.passRate)"
Write-Host "Report: $outFile"

if ($summary.passRate -lt $MinPassRate) {
    exit 1
}
