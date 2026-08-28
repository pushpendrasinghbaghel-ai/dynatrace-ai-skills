param(
    [string]$RepoRoot = "",
    [int]$TopK = 1,
    [double]$MinPassRate = 0.8
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$skillsRoot = Join-Path $RepoRoot "skills"
$casesPath = Join-Path $RepoRoot "harness\cases\routing-cases.json"
$reportsRoot = Join-Path $RepoRoot "harness\reports"
New-Item -ItemType Directory -Path $reportsRoot -Force | Out-Null

$cases = Get-Content -Path $casesPath -Raw | ConvertFrom-Json
$skillFiles = Get-ChildItem -Path $skillsRoot -Filter "SKILL.md" -Recurse -File

if (-not $skillFiles) {
    throw "No SKILL.md files found under $skillsRoot"
}

$stopWords = @(
    "the", "and", "for", "with", "that", "this", "from", "into", "then", "when", "need",
    "want", "your", "new", "set", "setup", "using", "across", "make", "have", "has", "are"
)

function Get-Tokens([string]$text) {
    $clean = $text.ToLowerInvariant() -replace "[^a-z0-9\-\s]", " "
    $parts = $clean -split "\s+" | Where-Object { $_ -and $_.Length -ge 3 }
    $filtered = $parts | Where-Object { $stopWords -notcontains $_ }
    return @($filtered | Select-Object -Unique)
}

$skillCorpus = @()
foreach ($skillFile in $skillFiles) {
    $content = Get-Content -Path $skillFile.FullName -Raw
    $frontmatterMatch = [regex]::Match($content, "^(?s)---\s*(.*?)\s*---")
    $frontmatterText = if ($frontmatterMatch.Success) { $frontmatterMatch.Groups[1].Value } else { "" }
    $descriptionMatch = [regex]::Match($frontmatterText, "(?m)^description\s*:\s*(.+)$")
    $description = if ($descriptionMatch.Success) { $descriptionMatch.Groups[1].Value } else { "" }
    $name = Split-Path -Path $skillFile.DirectoryName -Leaf
    $nameTokens = Get-Tokens -text ($name -replace "-", " ")
    $descriptionTokens = Get-Tokens -text $description
    $contentTokens = Get-Tokens -text $content

    $skillCorpus += [pscustomobject]@{
        name = $name
        nameTokens = $nameTokens
        descriptionTokens = $descriptionTokens
        contentTokens = $contentTokens
    }
}

$results = @()

foreach ($case in $cases) {
    $promptTokens = Get-Tokens -text $case.prompt
    $scores = @()

    foreach ($skill in $skillCorpus) {
        $nameMatches = @($promptTokens | Where-Object { $skill.nameTokens -contains $_ }).Count
        $descriptionMatches = @($promptTokens | Where-Object { $skill.descriptionTokens -contains $_ }).Count
        $contentMatches = @($promptTokens | Where-Object { $skill.contentTokens -contains $_ }).Count
        $matchCount = ($nameMatches * 5) + ($descriptionMatches * 3) + $contentMatches
        $scores += [pscustomobject]@{
            skill = $skill.name
            score = $matchCount
            nameMatches = $nameMatches
            descriptionMatches = $descriptionMatches
            contentMatches = $contentMatches
        }
    }

    $predictedSkills = @(
        $scores |
            Sort-Object -Property score -Descending |
            Where-Object { $_.score -gt 0 } |
            Select-Object -First $TopK -ExpandProperty skill
    )

    $expectedSkills = @($case.expectedSkills)
    $forbiddenSkills = @($case.forbiddenSkills)
    $missingExpected = @($expectedSkills | Where-Object { $predictedSkills -notcontains $_ })
    $hitForbidden = @($forbiddenSkills | Where-Object { $predictedSkills -contains $_ })
    $passed = ($missingExpected.Count -eq 0) -and ($hitForbidden.Count -eq 0)

    $results += [pscustomobject]@{
        id = $case.id
        prompt = $case.prompt
        expectedSkills = $expectedSkills
        forbiddenSkills = $forbiddenSkills
        predictedSkills = $predictedSkills
        scores = @($scores | Sort-Object -Property score -Descending | Select-Object -First ([Math]::Min($TopK + 2, $scores.Count)))
        missingExpected = $missingExpected
        hitForbidden = $hitForbidden
        passed = $passed
    }
}

$summary = [pscustomobject]@{
    suite = "routing"
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

$outFile = Join-Path $reportsRoot "routing-report.json"
$report | ConvertTo-Json -Depth 7 | Set-Content -Path $outFile -Encoding UTF8

Write-Host "Routing tests complete: $($summary.passed)/$($summary.total) passed"
Write-Host "Pass rate: $($summary.passRate)"
Write-Host "Report: $outFile"

if ($summary.passRate -lt $MinPassRate) {
    exit 1
}
