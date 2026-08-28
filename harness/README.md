# Skill Test Harness

This harness validates whether skills in [skills/](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/skills) are usable, routable, and outcome-oriented.

## What it tests

1. **Static tests** (`run-static-tests.ps1`)
   - Required frontmatter keys exist (`name`, `description`, `argument-hint`)
   - Core skill structure is present (title, usage guidance, authoritative references, and grounding notes)
2. **Routing tests** (`run-routing-tests.ps1`)
   - A prompt should route to expected skill(s)
   - A prompt should avoid forbidden skill(s)
3. **Outcome tests** (`run-outcome-tests.ps1`)
   - Skill instructions contain expected capability markers for that skill's job
4. **POC depth tests** (`run-poc-depth-tests.ps1`)
   - Measures how much of a real customer POC flow is covered by the current skill set
   - Highlights missing capabilities and recommended next skills

## Folder layout

```text
harness/
  cases/
    routing-cases.json
    outcome-cases.json
    poc-depth-cases.json
    skill-capabilities.json
    capability-recommendations.json
  reports/
  runners/
    run-all.ps1
    run-static-tests.ps1
    run-routing-tests.ps1
    run-outcome-tests.ps1
    run-poc-depth-tests.ps1
```

## Run locally (PowerShell)

From repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\harness\runners\run-all.ps1
```

Or run individual suites:

```powershell
powershell -ExecutionPolicy Bypass -File .\harness\runners\run-static-tests.ps1
powershell -ExecutionPolicy Bypass -File .\harness\runners\run-routing-tests.ps1
powershell -ExecutionPolicy Bypass -File .\harness\runners\run-outcome-tests.ps1
powershell -ExecutionPolicy Bypass -File .\harness\runners\run-poc-depth-tests.ps1
```

Reports are written under [harness/reports/](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/harness/reports).

## Testing "how deep can this agent go?"

Use [run-poc-depth-tests.ps1](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/harness/runners/run-poc-depth-tests.ps1). It compares realistic POC scenarios against the capabilities currently covered by your skills.

Example:

```powershell
powershell -ExecutionPolicy Bypass -File .\harness\runners\run-poc-depth-tests.ps1
```

The report answers:

- Can the current skill set onboard a tenant and verify access?
- Can it plan against success criteria?
- Can it cover dashboards, notebooks, and settings lifecycle?
- Can it handle customer variants like custom log paths or OpenTelemetry-first environments?
- Which missing capabilities should be filled by upstream skills vs new complementary skills?
- Does the skill set cover the requested POC flow without relying on wrapper files?

## Grounding policy

Each `SKILL.md` should contain:

- `## Authoritative references` — official docs or canonical local references
- `## Grounding notes` — what is doc-backed versus what is workflow/field heuristic

The static suite now checks for both so grounding is visible and testable.

## Adding new skills to tests

1. Add new prompt cases in [routing-cases.json](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/harness/cases/routing-cases.json).
2. Add capability markers in [outcome-cases.json](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/harness/cases/outcome-cases.json).
3. Map each skill's delivery surface in [skill-capabilities.json](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/harness/cases/skill-capabilities.json).
4. Add or refine scenario coverage in [poc-depth-cases.json](C:/Users/pushpendra.singhbagh/Desktop/dynatrace-deck.worktrees/comprehensive-agentic-architecture/harness/cases/poc-depth-cases.json).
5. Run `run-all.ps1` and check suite summaries.
