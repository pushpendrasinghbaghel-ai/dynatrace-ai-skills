param(
    [string]$RepoRoot = "",
    [double]$MinPassRate = 1.0
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$casesPath = Join-Path $RepoRoot "harness\cases\agent-wrapper-cases.json"
$reportsRoot = Join-Path $RepoRoot "harness\reports"
New-Item -ItemType Directory -Path $reportsRoot -Force | Out-Null

$cases = Get-Content -Path $casesPath -Raw | ConvertFrom-Json
$results = @()

foreach ($case in $cases) {
    $filePath = Join-Path $RepoRoot $case.path
    $exists = Test-Path $filePath
    $missingPatterns = @()

    if ($exists) {
        $content = Get-Content -Path $filePath -Raw
        foreach ($pattern in $case.requiredPatterns) {
            if ($content -notmatch [regex]::Escape($pattern)) {
                $missingPatterns += $pattern
            }
        }
    } else {
        $missingPatterns += "file missing"
    }

    $results += [pscustomobject]@{
        path = $case.path
        exists = $exists
        missingPatterns = $missingPatterns
        passed = $exists -and ($missingPatterns.Count -eq 0)
    }
}

$summary = [pscustomobject]@{
    suite = "agent-wrapper"
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

$outFile = Join-Path $reportsRoot "agent-wrapper-report.json"
$report | ConvertTo-Json -Depth 6 | Set-Content -Path $outFile -Encoding UTF8

Write-Host "Agent wrapper tests complete: $($summary.passed)/$($summary.total) passed"
Write-Host "Pass rate: $($summary.passRate)"
Write-Host "Report: $outFile"

if ($summary.passRate -lt $MinPassRate) {
    exit 1
}
