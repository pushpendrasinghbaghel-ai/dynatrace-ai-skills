param(
    [string]$RepoRoot = "",
    [double]$MinPassRate = 1.0
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$skillsRoot = Join-Path $RepoRoot "skills"
$casesPath = Join-Path $RepoRoot "harness\cases\outcome-cases.json"
$reportsRoot = Join-Path $RepoRoot "harness\reports"
New-Item -ItemType Directory -Path $reportsRoot -Force | Out-Null

$cases = Get-Content -Path $casesPath -Raw | ConvertFrom-Json
$results = @()

foreach ($case in $cases) {
    $skillPath = Join-Path $skillsRoot "$($case.skill)\SKILL.md"
    if (-not (Test-Path $skillPath)) {
        $results += [pscustomobject]@{
            id = $case.id
            skill = $case.skill
            passed = $false
            missingPatterns = @("SKILL.md not found")
        }
        continue
    }

    $content = Get-Content -Path $skillPath -Raw
    $missingPatterns = @()
    foreach ($pattern in $case.requiredPatterns) {
        if ($content -notmatch [regex]::Escape($pattern)) {
            $missingPatterns += $pattern
        }
    }

    $passed = $missingPatterns.Count -eq 0
    $results += [pscustomobject]@{
        id = $case.id
        skill = $case.skill
        passed = $passed
        missingPatterns = $missingPatterns
    }
}

$summary = [pscustomobject]@{
    suite = "outcome"
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

$outFile = Join-Path $reportsRoot "outcome-report.json"
$report | ConvertTo-Json -Depth 6 | Set-Content -Path $outFile -Encoding UTF8

Write-Host "Outcome tests complete: $($summary.passed)/$($summary.total) passed"
Write-Host "Pass rate: $($summary.passRate)"
Write-Host "Report: $outFile"

if ($summary.passRate -lt $MinPassRate) {
    exit 1
}
