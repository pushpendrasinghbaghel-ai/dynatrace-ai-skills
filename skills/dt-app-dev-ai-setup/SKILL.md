---
name: dt-app-dev-ai-setup
description: "Set up AI-assisted Dynatrace app development using the dt-app-mcp MCP server and CLAUDE.md/AGENTS.md/copilot-instructions.md instructions file. Works with both Claude Code and GitHub Copilot (VS Code). Use when: setting up AI for Dynatrace app development, configuring dt-app-mcp, adding CLAUDE.md/AGENTS.md/copilot-instructions.md to a Dynatrace app repo, 'vibe coding' a Dynatrace app, connecting Claude Code, GitHub Copilot, or VS Code to Dynatrace app dev tools, or troubleshooting why the AI assistant isn't using Strato components/DQL knowledge base correctly."
argument-hint: "AI tool being used (Claude Code, GitHub Copilot/VS Code, VS Code + Dynatrace Apps extension, or other), and whether the app is new or existing"
---

# AI for Dynatrace App Development Setup

Connects an AI coding assistant to Dynatrace app-development context (Strato Design System components, DQL knowledge base, SDK docs, experience standards) via the `dt-app-mcp` MCP server, plus a project instructions file. The official [AI for app development](https://developer.dynatrace.com/quickstart/app-development-with-ai/) quickstart is the baseline authority for this workflow; the production lessons below extend it without replacing its setup and verification steps.

This is distinct from the general-purpose [dynatrace-mcp](https://github.com/dynatrace-oss/dynatrace-mcp) server, which queries a live tenant's telemetry (metrics/logs/traces/problems). `dt-app-mcp` is for *building* Dynatrace apps, not investigating environments. Both can be configured together if the user wants both capabilities.

## Official reference docs — read these so new apps look and feel native

Point the AI assistant (or yourself) at these before building UI, so the app matches the look/structure of real Dynatrace apps instead of inventing its own conventions:

- [AI for app development](https://developer.dynatrace.com/quickstart/app-development-with-ai/) — authoritative setup for `dt-app-mcp`, project instruction files, supported AI-tool configuration, MCP verification prompts, available tools, AI-assisted implementation, code review, and `npx dt-app dev` preview. Re-check this page when setup behavior or supported tools may have changed.
- [About AppEngine](https://developer.dynatrace.com/plan/about-appengine/) — apps are a React + TypeScript SPA with a serverless TypeScript backend (app functions); logic runs close to Grail data.
- [About Strato Design System](https://developer.dynatrace.com/design/about-strato-design-system/) — the UI kit: `@dynatrace/strato-components[-preview]`, `@dynatrace/strato-design-tokens`, `@dynatrace/strato-icons`, `@dynatrace/strato-geo`. Run `npx dt-app update` every ~2 weeks to keep these current — Strato ships breaking changes between releases.
- [Strato Foundations](https://developer.dynatrace.com/design/foundations/) — layout, navigation, interaction states, content guidelines.
- [Strato Design Tokens](https://developer.dynatrace.com/design/design-tokens/) — canonical colors/typography/spacing/elevation values. Use tokens, never hardcoded hex/rgba (see production-app lesson below).
- [Strato Components](https://developer.dynatrace.com/design/components/) — the actual component catalog (buttons, tables, overlays, forms) with usage guidelines; prefer these over raw HTML.
- [Strato Patterns](https://developer.dynatrace.com/design/patterns/) — composed UX conventions every well-formed Dynatrace app follows: [app structure](https://developer.dynatrace.com/design/patterns/app-structure/), [app naming guidelines](https://developer.dynatrace.com/design/patterns/app-naming-guidelines/), [AI presence](https://developer.dynatrace.com/design/patterns/ai-presence/) (how to visually indicate AI-generated content), [filtering](https://developer.dynatrace.com/design/patterns/filtering/), [status and health](https://developer.dynatrace.com/design/patterns/status-and-health/), [loading and saving](https://developer.dynatrace.com/design/patterns/loading-saving/), [forms and validation](https://developer.dynatrace.com/design/patterns/forms-validation/), [error messages](https://developer.dynatrace.com/design/patterns/error-messages/), [common actions](https://developer.dynatrace.com/design/patterns/common-actions/).
- [Data visualizations](https://developer.dynatrace.com/design/data-visualizations/) and [Icons](https://developer.dynatrace.com/design/icons/) — chart library and icon set to use instead of custom SVGs/charting libs.
- [Dynatrace SDK for TypeScript](https://developer.dynatrace.com/develop/sdks/) — official SDK catalog for querying Grail, documents, settings, automation, Dynatrace Intelligence, navigation, user preferences, app functions, and other platform services. Before importing any `@dynatrace-sdk/*` package, use `list_sdks` and `get_sdk` from `dt-app-mcp` (or this catalog when MCP is unavailable) to confirm the current package, client/hook, request shape, response type, required scopes, and runtime support; never guess an SDK package or API signature from memory.
- [Dynatrace Platform Services](https://developer.dynatrace.com/develop/platform-services/) — official catalog of platform capabilities available to apps, including Grail/query, documents, settings, app state, automation, environment/configuration, and related services. Check this catalog before designing persistence, configuration, query, automation, or integration architecture: confirm the service is supported in the intended frontend/app-function/workflow runtime, use the documented SDK or API rather than inventing storage/network patterns, and add only the exact scopes the selected operation requires.
- [User preferences SDK](https://developer.dynatrace.com/develop/sdks/user-preferences/) — `@dynatrace-sdk/user-preferences` is the authoritative source for the signed-in user's language, regional format, theme, and timezone through `getLanguage()`, `getRegionalFormat()`, `getTheme()`, and `getTimezone()`. Use these values for all locale-sensitive display and time conversion instead of browser, operating-system, or hardcoded defaults.
- [Dynatrace Developer Guides](https://developer.dynatrace.com/develop/guides/) — task-oriented implementation playbooks. Before designing a platform integration, check whether an official guide already defines the supported pattern; prefer it over an improvised architecture. High-value guides for production apps include [app functions](https://developer.dynatrace.com/develop/guides/app-functions/), [data/storage choices](https://developer.dynatrace.com/develop/guides/data/), [navigation and deep linking](https://developer.dynatrace.com/develop/guides/navigation/), [security](https://developer.dynatrace.com/develop/guides/security/), [privacy by design](https://developer.dynatrace.com/develop/guides/privacy/), [code optimization](https://developer.dynatrace.com/develop/guides/code-optimization/), [code reuse](https://developer.dynatrace.com/develop/guides/reuse-code/), [dark/light themes](https://developer.dynatrace.com/develop/guides/support-dark-light-themes/), [workflows](https://developer.dynatrace.com/develop/guides/workflows/), [deployment](https://developer.dynatrace.com/develop/guides/deploy-your-app/), [automated dependency updates](https://developer.dynatrace.com/develop/guides/automate-dependency-updates/), and [accessing platform APIs externally](https://developer.dynatrace.com/develop/guides/access-platform-apis-from-outside/).

The `get_experience_standard` and `get_strato_component`/`get_strato_usecases` MCP tools (Step 2 below) surface this same content inline during development — use the docs above when you need the fuller narrative or when the MCP tools aren't available.

## Prerequisites

- Complete the [Before you begin](https://developer.dynatrace.com/quickstart/first-app-in-5-minutes/#before-you-begin) steps from the official getting-started guide (required by the AI-development quickstart).
- Node.js/npx available (`dt-app-mcp` runs via `npx`).
- An app project created via the Dynatrace App Toolkit (`npx dt-app create <name>`) — or an existing app repo.
- An AI dev tool that supports MCP: Claude Code, GitHub Copilot in VS Code 1.102+ (native MCP support), VS Code + Dynatrace Apps extension, or another MCP-capable tool.

Ask the user which AI tool they're using and whether the app is new or existing before proceeding.

## Step 1 — Add the instructions file

- **New apps**: App Toolkit v1.10+ already places `CLAUDE.md` at the project root — verify it exists; nothing to do.
- **Existing apps**: Create `CLAUDE.md` in the project root and copy the contents from the [AGENTS.md template](https://github.com/Dynatrace/dt-app-templates/blob/main/templates/default/AGENTS.md). If the user's tool expects `AGENTS.md` instead (e.g. OpenAI Codex), name the file `AGENTS.md` instead of `CLAUDE.md`.
- **GitHub Copilot (VS Code)**: Copilot reads `.github/copilot-instructions.md` (workspace) and/or `AGENTS.md` automatically — it does not read `CLAUDE.md`. Either duplicate the same content into `.github/copilot-instructions.md`, or keep a single `AGENTS.md` and have `CLAUDE.md` be a one-line pointer (`See AGENTS.md`) so both tools share one source of truth without drift.

## Step 2 — Configure the AI tool

### Claude Code
```
claude mcp add dt-app-mcp -- npx -y dt-app-mcp
```
On Windows (PowerShell), use the `cmd /c` wrapper form directly — this is the reliable one-liner, no manual `.claude.json` editing needed in most cases:
```
claude mcp add dt-app-mcp -- cmd /c npx -y dt-app-mcp
```
If that still fails, fall back to editing `.claude.json` manually:
```json
{
  "mcpServers": {
    "dt-app-mcp": {
      "command": "cmd",
      "args": ["/c", "npx", "-y", "dt-app-mcp"]
    }
  }
}
```
Verify with `claude mcp list` — confirm `dt-app-mcp` shows status `connected` (alternatively, `/mcp` inside an active session). This only needs to be run once per machine — it registers in the global Claude Code config and starts automatically with every session; no token or auth needed.

### VS Code (with Dynatrace Apps extension)
Install the [Dynatrace Apps extension](https://marketplace.visualstudio.com/items?itemName=dynatrace.dynatrace-apps) — it registers the MCP server automatically via `npx`, no manual config needed. This works for both Copilot Chat and other VS Code AI extensions, since the extension registers the server at the VS Code level, not per-tool.

### GitHub Copilot (VS Code, without the Dynatrace Apps extension)
Copilot uses VS Code's native MCP support. Add (or create) `.vscode/mcp.json` in the workspace:
```json
{
  "servers": {
    "dt-app-mcp": {
      "command": "npx",
      "args": ["-y", "dt-app-mcp"]
    }
  }
}
```
On Windows, if `npx` isn't resolved directly, use the `cmd /c` wrapper form: `"command": "cmd", "args": ["/c", "npx", "-y", "dt-app-mcp"]`. Reload the window (or run **MCP: List Servers** from the Command Palette) and confirm `dt-app-mcp` shows as running. For a user-level (not workspace-scoped) install, add the same entry via **MCP: Open User Configuration** instead of the workspace file.

### Other AI tools
Add an MCP server entry with `command: "npx"`, `args: ["-y", "dt-app-mcp"]` to the tool's MCP config file, then restart the tool. Config file location/format varies by tool — check that tool's docs.

## Step 3 — Verify it works

Ask the AI assistant either of:
- "Which Strato component can I use to display a numeric return value of a DQL query?"
- "How can I query all logs with ERROR status?"

The assistant should visibly invoke MCP tools (not just answer from general knowledge) before responding. If it doesn't call tools, re-check Step 2's config and restart the tool.

## Available tools exposed by dt-app-mcp

- `list_strato_components` — list Strato components by name/keyword
- `get_strato_component` — detailed component docs, props, examples
- `get_strato_usecases` — full code for Strato component use cases
- `get_experience_standard` — app experience standards by keyword
- `get_dql_knowledgebase` — semantic search over the DQL knowledge base
- `list_sdks` — available Dynatrace SDK doc packages
- `get_sdk` — complete docs for a specific SDK package

Under the hood these give the AI **live** (not guessed/hallucinated) access to: component schemas (every `@dynatrace/strato-components` prop/variant/slot), DQL autocomplete (real entity types, field names, aggregation functions), app manifest rules (required scopes/permissions, `app.config.json` structure), and the official [Dynatrace SDK for TypeScript](https://developer.dynatrace.com/develop/sdks/) packages and hooks with their exact signatures. This is why first-pass generated code tends to compile — the model isn't guessing an API surface, it looked it up.

## Vibe coding an app

Once `dt-app-mcp` is active and `CLAUDE.md`/`AGENTS.md`/`.github/copilot-instructions.md` is in place:

1. Scaffold if needed: `npx dt-app create <name>`.
2. **Write the opening prompt like a spec, not a one-liner** — name the entity type, the exact signals/data to fetch, the layout, and the interactions (sortable/filterable/etc.). E.g.: "Create a Dynatrace app called Observability Scorecard. Fetch all Services from the tenant and display a table: one row per service, one column per signal type — Metrics, Traces, Logs, Cloud Events, and SLOs. Each cell shows whether that signal is present or absent for that service in the last 24 hours. Use DQL to determine signal presence. The table must be sortable by service name and filterable to show only coverage gaps." The prompt is the design doc — vague first prompts produce vague first drafts.
3. Use a capable model (Claude Sonnet or Opus in Claude Code; Claude Sonnet or GPT-5 in Copilot Chat) — the MCP tools + instructions file give it enough context to produce a working Strato/DQL implementation without hand-holding.
4. Preview with `npx dt-app dev`.
5. **Always review AI-produced code** before accepting — common cleanup: extract inline DQL strings into constants, drop unnecessary `useMemo`, drop default values that match the library default (e.g. `defaultPageIndex={0}`).
6. **Always validate/execute every DQL query against a real tenant before it lands in app source** — use `verify_dql`/`execute_dql` (or `dtctl query`) to confirm syntax and real field names first. Never hardcode a query into a hook/component that hasn't actually been run; AI-generated field names are frequently wrong or use classic-era naming. Each table column/signal is typically its own DQL query — validate each one independently.

## Lessons from real production apps

Distilled from two shipped Dynatrace AppEngine apps ([genai-control-center](https://github.com/pushpendrasinghbaghel-ai/genai-control-center) — 23 pages/43 hooks, [db-explain-pro](https://github.com/pushpendrasinghbaghel-ai/db-explain-pro) — multi-DB AI observability). Apply these once an app grows beyond a couple of pages.

**Build/runtime**
- Default Node heap (1.7 GB) runs out on apps with 20+ pages and heavy TS type-checking. Set `NODE_OPTIONS="--max-old-space-size=8192"` (8 GB, recommended for dev) before `npm run build` or `npx tsc --noEmit`; `npm start` (dev server) usually doesn't need it. Add it to the shell profile so it's permanent, not just a one-off export.
- First `npm start` opens a browser for Dynatrace SSO — expected, not an error.
- Node 18+ minimum, 22+ recommended for both apps in practice.

**app.config.json scopes** — request only what's used, grouped by function. Common set seen across both apps:
```
storage:spans:read, storage:logs:read, storage:metrics:read, storage:events:read,
storage:bizevents:read, storage:buckets:read, storage:entities:read,
storage:filter-segments:read/write, automation:workflows:read/run/write,
davis-copilot:nl2dql:execute, davis-copilot:dql2nl:execute, davis-copilot:conversations:execute,
davis:analyzers:read, davis:analyzers:execute,
document:documents:read/write/delete
```
Add `document:*` only if the app persists user config/rate-cards/filters via the Document Store; add `automation:workflows:*` only if it creates/runs Workflows.

**Project structure that scales** (used identically in both apps):
```
ui/
├── main.tsx
├── app/
│   ├── App.tsx           # routes
│   ├── pages/             # one file per route
│   ├── components/        # shared UI
│   ├── hooks/              # useDql wrappers, one hook per data concern
│   ├── queries/ (or embed in hooks) # centralized DQL strings, not inline in components
│   ├── types/
│   ├── context/            # global filter/timeframe state via React Context
│   ├── utils/
│   │   ├── formatting.ts        # MUST use for locale-aware number/date formatting — don't hand-roll
│   │   └── design-tokens.ts (or styles.ts) # centralized color/status constants, never hardcode hex/rgba
│   └── workflows/ or agent/    # workflow templates / AI orchestration, if applicable
```
Centralizing DQL strings (not inline in component JSX) and formatting/colors in dedicated files was a recurring refactor in both apps — do it from the start.

**Strato Design System compliance — treat as mandatory, not a style preference** (verified directly against the production `AGENTS.md` for genai-control-center, which enforces these with zero exceptions):

*No raw HTML* — every structural/interactive element has a Strato replacement, use it:
| Raw HTML | Strato replacement |
|---|---|
| `<div>` | `<Flex>` from `strato-components/layouts` |
| `<span>` | `<Text>` from `strato-components/typography` |
| `<button>` | `<Button>` from `strato-components/buttons` |
| `<input>` | `<TextInput>`/`<NumberInput>` from `strato-components/forms` (exception: hidden `<input type="file">` for uploads) |
| `<select>` | `<Select>` from `strato-components-preview/forms` |
| `<table>` | `<DataTable>` from `strato-components-preview/tables` |
| `<a>` | `<Link>` or `<AppLink>` from `strato-components/typography` |

*Colors* — never hex/`rgb()`/`rgba()` in component styles. Use CSS variables (`var(--dt-colors-text-primary-default)`) or centralized design-token constants (a project-level `design-tokens.ts` with `StatusColors`/`ChartColors`/`EntityColors`/`GradeColors` groupings is the pattern both production apps converged on). The only accepted exception: hex as a `var(--x, #fallback)` fallback, and brand-identity SVG logos (e.g. provider icons) that must render actual brand colors.

*User preferences and locale/formatting* — treat the signed-in user's Dynatrace preferences as application state, not decoration. Read `getLanguage()`, `getRegionalFormat()`, and `getTimezone()` from `@dynatrace-sdk/user-preferences` once through a shared context/hook and use them consistently for translated copy, numbers, currency, percentages, dates, and query/display time boundaries. Never call `.toLocaleString()`, `.toLocaleDateString()`, `.toLocaleTimeString()`, or `new Intl.NumberFormat()` directly in components; centralize them in `utils/formatting.ts` (`formatNumber`, `formatDateTime`, `formatDate`, `formatTime`, `formatCurrencyLocalized`, `formatPercent`) and pass the Dynatrace regional format/timezone explicitly. `getTimezone()` may return ISO 8601 or tz-database format, so handle both documented forms and test DST boundaries. `getTheme()` is available for non-component logic only; do not manually set theme on `<AppRoot>` or duplicate Strato's automatic theme handling.

*Component API gotchas that silently break at runtime, not compile time*:
- `Tabs` use `defaultIndex={0}` (not `defaultValue`); tab items use `title="..."` (not `value`/`label`).
- `DonutChart`/`PieChart` data must be `{ slices: [...] }`, not a raw array.
- `TimeseriesChart` datapoints need `{ start: Date, value: number }` — not `{ timestamp: number }`.
- `DataTable` cell renderers must return JSX (`<Text>...</Text>`), not raw strings.
- `Flex` `gap` only accepts Strato spacing tokens: `0 | 2 | 4 | 6 | 8 | 12 | 16 | 20 | 24 | 32 | 40 | 48 | 56 | 64` — not arbitrary pixel values.
- `Button` `variant` is one of `"default" | "emphasized" | "accent"` — there is no `"minimal"` variant.
- Any list of >20 rows needs real pagination (`DataTable` built-in pagination, e.g. 25/page) — don't hard-cap with `.slice(0, N)`.

*Responsive layout* — never fixed grids like `gridTemplateColumns: 'repeat(2, 1fr)'`; use `repeat(auto-fit, minmax(280px, 1fr))` or `<Flex flexWrap="wrap">` with `flex: '1 1 280px'`. Never `calc(100vh - Xpx)` for height — let Strato `<Page>`/`<Flex>` handle it. Never hardcode pixel widths on containers — use `flex`/`minWidth`/`maxWidth`.

*Imports* — always import from category subdirectories (`strato-components/layouts`, `/typography`, `/tables`, etc.), never the package root — this affects both correctness and bundle size. Check `.d.ts` files directly under `node_modules/@dynatrace/strato-components[-preview]/<category>/<component>/` for the real API — there's no separate `types/` folder. Watch for duplicate imports of the same symbol from both `../utils` and `../utils/formatting` if the project's `utils/index.ts` already re-exports everything as a barrel.

*Theming* — never set theme manually on `<AppRoot>`; it handles dark/light automatically. This is exactly why hardcoded colors are the #1 recurring bug: they don't participate in that automatic switch.

**Filtering, search, sort, and pagination — the standard Dynatrace pattern** (from genai-control-center's `FilterBar`/`FilterContext`, used identically across all ~23 pages):
- Use Strato's own `FilterField` + `TimeframeSelector` (both from `@dynatrace/strato-components[-preview]/filters`) instead of building custom text inputs/dropdowns for filtering — `FilterField` gives free-text filter syntax (`service="x" provider="y"`), auto-suggestions, and a `validatorMap` for per-key operators/allowed values (`keyPredicates: { service: { operators: ['equals','not-equals'], valuePredicate: [...knownServiceNames] } }`). Populate `valuePredicate` from real distinct-value queries (`useDistinctServices`/`useDistinctProviders`/etc.), not hardcoded lists.
- Build one shared `FilterBar` component wrapping `FilterField` + `TimeframeSelector` + a refresh `Button`, and reuse it on every page — don't reimplement filtering per page. Parse the `FilterField` syntax tree (`onFilter`/`onChange` callbacks give `{ value, syntaxTree, isValid }`) into typed filter values with a small tree-walking function, not string-splitting.
- Lift filter state to a `FilterContext` (React Context + `useState`, exposing `filters`/`setFilters`/`updateFilter`/`resetFilters`) so timeframe/service/provider/model selections persist as the user navigates between pages — a per-page-only filter state feels broken to users who expect Dynatrace's global filter behavior.
- Convert display-facing filter values (entity *names*) to entity *IDs* before using them in DQL — build a `Map<entityName, entityId>` from the same distinct-values query used to populate the filter dropdown, and look up the ID right before passing filters into a DQL-query hook. Never filter DQL directly on a user-visible display name if an entity ID is available.
- Sorting/pagination: use `DataTable`'s own `sortable`/`resizable` props and `<DataTable.Pagination defaultPageSize={N} />` — don't hand-roll click-to-sort header logic or slice arrays manually. Combine with `useMemo` for any *derived* filtered list (e.g. severity tab filters on top of the already-fetched dataset) so re-renders don't re-filter every keystroke.

**Cross-app and cross-entity linking — deep-link into other Dynatrace apps, don't just describe data**: use `getIntentLink` from `@dynatrace-sdk/navigation` to build a URL into another Dynatrace app (Services, Distributed Tracing, Smartscape/Technologies) scoped to a specific entity/trace/timeframe, then `window.open(url, '_blank', 'noopener,noreferrer')`:
```ts
import { getIntentLink } from '@dynatrace-sdk/navigation';
// Jump to a specific service in the Services app
const url = getIntentLink({ 'dt.entity.service': entityId }, 'dynatrace.services', 'view-service');
// Jump to a specific trace in Distributed Tracing, with a time window
const url2 = getIntentLink({ trace_id: traceId, 'dt.timeframe': { from, to } }, 'dynatrace.distributedtracing', 'view-trace');
window.open(url, '_blank', 'noopener,noreferrer');
```
Centralize this in a shared util (e.g. `utils/traceLink.tsx`'s `openTraceInDistributedTraces`/`<TraceLink traceId .../>`) rather than repeating the intent-link boilerplate on every page — build a reasonable default time window around the linked entity (e.g. ±1h around a known timestamp, wider like 72h if no timestamp is available) so the target app doesn't land on an empty view. For entities without a documented intent-link target, a direct Smartscape/Services URL pattern (`/ui/apps/dynatrace.classic.technologies/ui/entity/<entityId>`) also works as a fallback, opened the same way. Always use `target="_blank"` + `rel="noopener noreferrer"` for these external-app links — never navigate away from the app in the same tab.

**MCP data validation — mandatory for every DQL-touching change, not optional QA**: every feature that writes or modifies a DQL query must be validated against a live tenant via MCP (`execute_dql`/`verify_dql`) before it's considered complete — no exceptions except pure styling changes, an already-validated identical query in the same session, or MCP tools genuinely unavailable (and that gap must be documented, not silently skipped). For each result, confirm: records are non-empty, every field the code destructures actually exists, field types match what's unpacked (numbers arrive as numbers, not stringified), `by:` grouping produced the expected dimensions. Common failure modes worth checking for specifically:
| Symptom | Cause | Fix |
|---|---|---|
| Silent syntax failure | Missing comma before `by:` in `summarize` | `summarize count(), by: { field }` not `summarize count() by: { field }` |
| Field is always null | Assumed field doesn't exist (e.g. structured field expected in a raw webhook payload) | Run `fetch bizevents \| filter ... \| limit 1` first, inspect real record shape |
| Wrong type at runtime | Numeric field returns as a string | Wrap with `Number(...)` in the hook, don't assume type from the query |
| "No data" in UI despite valid query | Time window too narrow (e.g. last 5 min with sparse data) | Start wide (last 24h), narrow after confirming data exists |
| `trace.id == "..."` returns 0 results | Direct equality doesn't match on `trace.id` in this field type | Use `matchesPhrase(toString(trace.id), "...")` for trace-level correlation instead |

**Feasibility-first feature planning** (from genai-control-center's data-feasibility-assessment discipline, run before committing engineering time to any feature): for each proposed page/widget, MCP-validate whether the underlying span/metric/bizevent attribute actually exists in the tenant *before* designing the UI around it — not after. Classify each candidate feature 🟢 (data confirmed, build it), 🟡 (partial/some limitations, note them explicitly in the UI), or 🔴 (attribute doesn't exist anywhere — don't build it, or clearly label it a mock/future feature). This prevents the common failure mode of shipping a polished UI for a metric that silently has zero real data behind it. Explicitly document what's *not* feasible and why (e.g. "no embedding vectors in span attributes — chunk-quality scoring not buildable without new instrumentation") so the gap is a documented decision, not a discovered bug later.

**Grail query cost awareness** — not all data sources cost the same to query: pre-aggregated OTel metrics (e.g. `timeseries avg(some.metric)`) are effectively free/near-zero query cost since they're already aggregated, while broad `fetch logs | filter contains(...)` scans over a wide time window can consume several GB per query. When both a metric and an equivalent span-derived aggregation exist, prefer the metric. Keep log `contains()` filters as targeted as possible (specific fields/time windows) rather than broad full-text scans, especially in production tenants with real query budgets.

**Security utilities worth building early** (from db-explain-pro, which has dedicated unit tests for these):
- A DQL sanitizer util if any user input or AI-generated text feeds into a DQL string, to prevent injection.
- An HTML sanitizer util if AI-generated markdown/HTML is rendered in the UI, to prevent XSS.
- Both were unit-tested (15 and 14 tests respectively) — worth doing the same for any app that renders AI output.

**Scope and credential hygiene at scale** (from genai-control-center's phased-rollout scope reference doc):
- Document scopes per-phase/per-feature (a scope → reason → file-that-needs-it table) so scope creep is visible and reviewable, not just a flat list that grows silently.
- Add a new scope only when the feature that needs it actually ships — never speculatively.
- If a standalone script/MCP server needs its own API token (separate from the app's platform-token scopes), document its scope list separately and **rotate that token on a schedule** (90 days is a reasonable default) since it isn't covered by the app's own credential lifecycle.
- Any workflow/automation with real-world side effects (auto-remediation, circuit breakers, failover) should default to `requiresConfirmation: true` and include an explicit rollback condition — don't ship irreversible automation without a human-in-the-loop gate by default.

**Data honesty** — if a metric requires optional data (e.g. BizEvent cost ingestion not present in all tenants) or is estimated rather than measured, show an explicit "NO DATA" / "ESTIMATED" badge rather than silently faking a number. Both apps adopted this after early versions blurred real vs. synthetic data.

## Production readiness checklist — before calling an app "done"

Everything above gets an app to a solid, Strato-compliant first draft. That is **not** the same as production-grade / customer-ready. Before releasing an app built with this skill, verify:

- [ ] **Tests exist, not just "worth building"** — unit tests for any DQL/HTML sanitizer, and at minimum smoke tests for each page's data hook. Don't ship security utilities without tests proving they block the attack they're meant to block.
- [ ] **Every async data fetch handles failure and empty states** — a failed DQL query, a timeout, or zero rows must render a clear message (Strato `MessageContainer`/empty-state pattern), never a blank page or unhandled exception.
- [ ] **Security review of any AI-generated or user-influenced content path** — prompts, DQL built from user input, and rendered markdown/HTML are injection/XSS surfaces; review or automate-test them explicitly, don't just note the risk.
- [ ] **Scopes are minimal and reviewed** — re-check `app.config.json` scopes against what's actually used right before release; drop anything added during exploration that didn't ship.
- [ ] **Query cost is sane at expected data volume** — expensive `fetch spans`/`fetch logs` queries without tight `filter`/time-window scoping will blow Grail budget in a real tenant; test against realistic data volume, not just a demo tenant.
- [ ] **Accessibility spot-check** — keyboard navigation and screen-reader labels on custom compositions (Strato components are compliant by default, but custom layouts around them can break it).
- [ ] **Deploy path is deliberate** — a named target environment, and a rollback plan (`npm run deploy` again with the previous commit) — not "whoever runs `npm run deploy` last wins."

This checklist is a floor, not a substitute for a full security/QA pass — for customer-facing releases, run a proper multi-perspective review (security, accessibility, reliability) before shipping.

## Related

- [Dynatrace Apps for VS Code and Cursor](https://developer.dynatrace.com/quickstart/dynatrace-apps-vscode-extension/)
- For querying live tenant telemetry instead of building apps, use the `dtctl` skill or the `dynatrace-mcp` server (see `dt-tenant-setup` skill for onboarding that separately).
