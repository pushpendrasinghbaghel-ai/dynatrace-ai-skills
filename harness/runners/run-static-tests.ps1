param(
    [string]$RepoRoot = "",
    [double]$MinPassRate = 1.0
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$skillsRoot = Join-Path $RepoRoot "skills"
$reportsRoot = Join-Path $RepoRoot "harness\reports"
New-Item -ItemType Directory -Path $reportsRoot -Force | Out-Null

$skillFiles = Get-ChildItem -Path $skillsRoot -Filter "SKILL.md" -Recurse -File
if (-not $skillFiles) {
    throw "No SKILL.md files found under $skillsRoot"
}

$results = @()
$requiredFrontmatterKeys = @("name", "description", "argument-hint")

foreach ($skillFile in $skillFiles) {
    $content = Get-Content -Path $skillFile.FullName -Raw
    $skillName = Split-Path -Path $skillFile.DirectoryName -Leaf

    $frontmatterMatch = [regex]::Match($content, "^(?s)---\s*(.*?)\s*---")
    $hasFrontmatter = $frontmatterMatch.Success
    $frontmatterText = if ($hasFrontmatter) { $frontmatterMatch.Groups[1].Value } else { "" }

    $missingKeys = @()
    foreach ($key in $requiredFrontmatterKeys) {
        if (-not [regex]::IsMatch($frontmatterText, "(?m)^$([regex]::Escape($key))\s*:\s*.+$")) {
            $missingKeys += $key
        }
    }

    $hasTitle = [regex]::IsMatch($content, "(?m)^#\s+.+$")
    $hasUsageSection = [regex]::IsMatch($content.ToLowerInvariant(), "use when|when to use")
    $hasAuthoritativeReferences = [regex]::IsMatch($content, "(?m)^##\s+Authoritative references\s*$")
    $hasGroundingNotes = [regex]::IsMatch($content, "(?m)^##\s+Grounding notes\s*$")

    $passed = $hasFrontmatter -and ($missingKeys.Count -eq 0) -and $hasTitle -and $hasUsageSection -and $hasAuthoritativeReferences -and $hasGroundingNotes

    $results += [pscustomobject]@{
        skill = $skillName
        skillFile = $skillFile.FullName
        passed = $passed
        hasFrontmatter = $hasFrontmatter
        missingFrontmatterKeys = $missingKeys
        hasTitle = $hasTitle
        hasUsageGuidance = $hasUsageSection
        hasAuthoritativeReferences = $hasAuthoritativeReferences
        hasGroundingNotes = $hasGroundingNotes
    }
}

$summary = [pscustomobject]@{
    suite = "static"
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

$outFile = Join-Path $reportsRoot "static-report.json"
$report | ConvertTo-Json -Depth 6 | Set-Content -Path $outFile -Encoding UTF8

Write-Host "Static tests complete: $($summary.passed)/$($summary.total) passed"
Write-Host "Pass rate: $($summary.passRate)"
Write-Host "Report: $outFile"

if ($summary.passRate -lt $MinPassRate) {
    exit 1
}
