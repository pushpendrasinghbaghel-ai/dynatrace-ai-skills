param(
    [string]$RepoRoot = "",
    [double]$MinCoverage = 0.0
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$casesPath = Join-Path $RepoRoot "harness\cases\poc-depth-cases.json"
$skillCapabilitiesPath = Join-Path $RepoRoot "harness\cases\skill-capabilities.json"
$recommendationsPath = Join-Path $RepoRoot "harness\cases\capability-recommendations.json"
$reportsRoot = Join-Path $RepoRoot "harness\reports"
New-Item -ItemType Directory -Path $reportsRoot -Force | Out-Null

$cases = Get-Content -Path $casesPath -Raw | ConvertFrom-Json
$skillCapabilities = Get-Content -Path $skillCapabilitiesPath -Raw | ConvertFrom-Json
$recommendations = Get-Content -Path $recommendationsPath -Raw | ConvertFrom-Json

$capabilityOwners = @{}
foreach ($entry in $skillCapabilities) {
    foreach ($capability in $entry.capabilities) {
        if (-not $capabilityOwners.ContainsKey($capability)) {
            $capabilityOwners[$capability] = @()
        }
        $capabilityOwners[$capability] += $entry.skill
    }
}

$recommendationIndex = @{}
foreach ($entry in $recommendations) {
    $recommendationIndex[$entry.capability] = $entry
}

$results = @()

foreach ($case in $cases) {
    $coveredCapabilities = @()
    $missingCapabilities = @()
    $coverageDetails = @()

    foreach ($capability in $case.requiredCapabilities) {
        $owningSkills = @()
        if ($capabilityOwners.ContainsKey($capability)) {
            $owningSkills = @($capabilityOwners[$capability] | Sort-Object -Unique)
            $coveredCapabilities += $capability
        } else {
            $recommendedSkills = @()
            $recommendationSource = ""
            if ($recommendationIndex.ContainsKey($capability)) {
                $recommendedSkills = @($recommendationIndex[$capability].recommendedSkills)
                $recommendationSource = $recommendationIndex[$capability].source
            }

            $missingCapabilities += $capability
        }

        $recommendedSkills = @()
        $recommendationSource = ""
        if ($recommendationIndex.ContainsKey($capability)) {
            $recommendedSkills = @($recommendationIndex[$capability].recommendedSkills)
            $recommendationSource = $recommendationIndex[$capability].source
        }

        $coverageDetails += [pscustomobject]@{
            capability = $capability
            covered = ($owningSkills.Count -gt 0)
            owningSkills = $owningSkills
            recommendedSkills = $recommendedSkills
            recommendationSource = $recommendationSource
        }
    }

    $requiredCount = @($case.requiredCapabilities).Count
    $coveredCount = $coveredCapabilities.Count
    $coverage = if ($requiredCount -gt 0) { [math]::Round($coveredCount / $requiredCount, 4) } else { 1.0 }

    $results += [pscustomobject]@{
        id = $case.id
        title = $case.title
        description = $case.description
        requiredCapabilities = @($case.requiredCapabilities)
        coveredCapabilities = @($coveredCapabilities)
        missingCapabilities = @($missingCapabilities)
        coverage = $coverage
        passesThreshold = ($coverage -ge $MinCoverage)
        coverageDetails = $coverageDetails
    }
}

$summary = [pscustomobject]@{
    suite = "poc-depth"
    total = $results.Count
    averageCoverage = 0
    generatedAt = (Get-Date).ToString("o")
    minCoverageThreshold = $MinCoverage
    belowThreshold = 0
}

if ($results.Count -gt 0) {
    $summary.averageCoverage = [math]::Round((($results | Measure-Object -Property coverage -Average).Average), 4)
}
$summary.belowThreshold = @($results | Where-Object { -not $_.passesThreshold }).Count

$report = [pscustomobject]@{
    summary = $summary
    results = $results
}

$outFile = Join-Path $reportsRoot "poc-depth-report.json"
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $outFile -Encoding UTF8

Write-Host "POC depth tests complete: $($summary.total) scenarios analyzed"
Write-Host "Average coverage: $($summary.averageCoverage)"
Write-Host "Report: $outFile"

if ($summary.belowThreshold -gt 0) {
    exit 1
}
