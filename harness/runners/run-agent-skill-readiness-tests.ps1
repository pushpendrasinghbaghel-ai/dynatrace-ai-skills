param(
    [string]$RepoRoot = "",
    [double]$MinPassRate = 1.0
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$manifestPath = Join-Path $RepoRoot "agent-skill-manifest.json"
$reportsRoot = Join-Path $RepoRoot "harness\reports"
New-Item -ItemType Directory -Path $reportsRoot -Force | Out-Null

$results = @()

if (-not (Test-Path $manifestPath)) {
    throw "Missing agent skill manifest: $manifestPath"
}

$manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json

$localSkillNames = @()
foreach ($skill in $manifest.localSkills) {
    $skillPath = Join-Path $RepoRoot $skill.path
    $exists = Test-Path $skillPath
    $localSkillNames += $skill.name

    $results += [pscustomobject]@{
        type = "local-skill"
        subject = $skill.name
        passed = $exists
        details = if ($exists) { $skill.path } else { "Missing local skill path: $($skill.path)" }
    }
}

$duplicateNames = @($localSkillNames | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name)
$results += [pscustomobject]@{
    type = "manifest"
    subject = "local-skill-name-uniqueness"
    passed = ($duplicateNames.Count -eq 0)
    details = if ($duplicateNames.Count -eq 0) { "No duplicate local skill names" } else { "Duplicate local skill names: $($duplicateNames -join ', ')" }
}

$wrapperChecks = @(
    @{ path = "AGENTS.md"; required = @("Skill readiness check", "agent-skill-manifest.json") },
    @{ path = "CLAUDE.md"; required = @("agent-skill-manifest.json", "required skills") },
    @{ path = "copilot-instructions.md"; required = @("agent-skill-manifest.json", "upstream skills") },
    @{ path = "prompts\dynatrace-se-poc-agent.prompt.md"; required = @("agent-skill-manifest.json", "relevant skills are available") }
)

foreach ($check in $wrapperChecks) {
    $filePath = Join-Path $RepoRoot $check.path
    $exists = Test-Path $filePath
    $missing = @()

    if ($exists) {
        $content = Get-Content -Path $filePath -Raw
        foreach ($pattern in $check.required) {
            if ($content -notmatch [regex]::Escape($pattern)) {
                $missing += $pattern
            }
        }
    } else {
        $missing += "file missing"
    }

    $results += [pscustomobject]@{
        type = "wrapper-file"
        subject = $check.path
        passed = $exists -and ($missing.Count -eq 0)
        details = if ($missing.Count -eq 0) { "All readiness markers present" } else { "Missing: $($missing -join ', ')" }
    }
}

$summary = [pscustomobject]@{
    suite = "agent-skill-readiness"
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

$outFile = Join-Path $reportsRoot "agent-skill-readiness-report.json"
$report | ConvertTo-Json -Depth 6 | Set-Content -Path $outFile -Encoding UTF8

Write-Host "Agent skill readiness tests complete: $($summary.passed)/$($summary.total) passed"
Write-Host "Pass rate: $($summary.passRate)"
Write-Host "Report: $outFile"

if ($summary.passRate -lt $MinPassRate) {
    exit 1
}
