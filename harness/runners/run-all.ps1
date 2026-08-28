param(
    [string]$RepoRoot = "",
    [double]$MinStaticPassRate = 1.0,
    [double]$MinAgentWrapperPassRate = 1.0,
    [double]$MinAgentSkillReadinessPassRate = 1.0,
    [double]$MinAgentSkillSyncPassRate = 1.0,
    [double]$MinRoutingPassRate = 0.8,
    [double]$MinOutcomePassRate = 1.0,
    [double]$MinPocDepthCoverage = 0.0
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

Write-Host "Running static tests..."
& (Join-Path $PSScriptRoot "run-static-tests.ps1") -RepoRoot $RepoRoot -MinPassRate $MinStaticPassRate
if (-not $?) {
    throw "Static test suite failed."
}

Write-Host "Running agent wrapper tests..."
& (Join-Path $PSScriptRoot "run-agent-wrapper-tests.ps1") -RepoRoot $RepoRoot -MinPassRate $MinAgentWrapperPassRate
if (-not $?) {
    throw "Agent wrapper suite failed."
}

Write-Host "Running agent skill readiness tests..."
& (Join-Path $PSScriptRoot "run-agent-skill-readiness-tests.ps1") -RepoRoot $RepoRoot -MinPassRate $MinAgentSkillReadinessPassRate
if (-not $?) {
    throw "Agent skill readiness suite failed."
}

Write-Host "Running agent skill sync tests..."
& (Join-Path $PSScriptRoot "run-agent-skill-sync-tests.ps1") -RepoRoot $RepoRoot -MinPassRate $MinAgentSkillSyncPassRate
if (-not $?) {
    throw "Agent skill sync suite failed."
}

Write-Host "Running routing tests..."
& (Join-Path $PSScriptRoot "run-routing-tests.ps1") -RepoRoot $RepoRoot -MinPassRate $MinRoutingPassRate
if (-not $?) {
    throw "Routing test suite failed."
}

Write-Host "Running outcome tests..."
& (Join-Path $PSScriptRoot "run-outcome-tests.ps1") -RepoRoot $RepoRoot -MinPassRate $MinOutcomePassRate
if (-not $?) {
    throw "Outcome test suite failed."
}

Write-Host "Running POC depth tests..."
& (Join-Path $PSScriptRoot "run-poc-depth-tests.ps1") -RepoRoot $RepoRoot -MinCoverage $MinPocDepthCoverage
if (-not $?) {
    throw "POC depth suite failed."
}

Write-Host "All gated harness suites passed. POC depth report generated."
