---
name: dt-tenant-setup
description: "Onboard a new Dynatrace tenant for both dtctl and MCP in one pass. Use when: adding a new Dynatrace tenant/environment, setting up dtctl context for a customer/tenant, connecting a new tenant to the Dynatrace MCP server, adding an entry to mcp json or .mcp.json, validating tenant token scopes for MCP access, 'add entry for tenant X', 'set up dtctl for <name>', 'connect MCP to <tenant>', or any request to onboard/register a Dynatrace environment by tenant ID and nickname."
argument-hint: "Tenant nickname and tenant ID, e.g. 'HID xqv46417' — API token optional if the user already has one"
metadata:
  category: tenant-control-plane
  code-specific: "true"
---

# Dynatrace Tenant Setup (dtctl + MCP)

End-to-end onboarding for a new Dynatrace tenant: creates a working `dtctl` context and, optionally, registers the tenant as an MCP server in `.mcp.json`. This exists so the interview/gotchas below don't have to be rediscovered on every new tenant.

## Authoritative references

- [Dynatrace MCP server docs](https://docs.dynatrace.com/docs/shortlink/dynatrace-mcp-server) — MCP authentication model, connection pattern, and required scopes.
- [dtctl repository](https://github.com/dynatrace-oss/dtctl) — CLI behavior and command surface used by this workflow.

## Grounding notes

The auth and MCP guidance below is grounded in the official Dynatrace MCP documentation and the `dtctl` CLI's actual command behavior. The sequencing and troubleshooting notes are SE workflow guidance layered on top of those sources.

## Inputs needed

- **Nickname** — short context name (e.g. `HID`). Ask if not given.
- **Tenant ID** — the subdomain in `https://<TENANT_ID>.apps.dynatrace.com` (e.g. `xqv46417`). Ask if not given.
- **API token** — optional. If the user already has one, use it. Otherwise offer the OAuth browser flow (dtctl) and, separately, a scoped token for MCP (see Phase 2).

Never use placeholder values for any of these — always get the real ones from the user before running commands.

## Phase 1 — dtctl context

1. Confirm the CLI is present: `dtctl version`. If missing, install per platform (review the
   installer script before running it — don't blindly pipe a remote script into a shell):
   - macOS/Linux: `brew install dynatrace-oss/tap/dtctl` (preferred, no remote script execution),
     or download the versioned release from the
     [dtctl releases page](https://github.com/dynatrace-oss/dtctl/releases) and verify its
     checksum before running the bundled install script.
   - Windows: download the versioned release from the
     [dtctl releases page](https://github.com/dynatrace-oss/dtctl/releases) and run the
     installer directly rather than piping a remote script into `iex`.

2. Create the context:
   ```
   dtctl config set-context <nickname> --environment https://<TENANT_ID>.apps.dynatrace.com
   ```

3. Authenticate — two paths depending on whether a token was supplied:

   **A. Token supplied (preferred — no browser interruption):**
   `dtctl auth login` has **no `--token` flag** — it is OAuth-browser-only. API-token auth is a separate two-step dance:
   ```
   dtctl config set-credentials <nickname> --token <TOKEN>
   dtctl config set-context <nickname> --environment https://<TENANT_ID>.apps.dynatrace.com --token-ref <nickname>
   ```
   The second command is not optional — without `--token-ref` pointing at the stored credential name, the context has no way to find the token and queries fail with `token "" not found`.

   **B. No token supplied — OAuth flow:**
   ```
   dtctl auth login --context <nickname> --environment https://<TENANT_ID>.apps.dynatrace.com
   ```
   This opens a browser for SSO and configures the context as part of login.

4. Make it current and smoke-test it:
   ```
   dtctl config use-context <nickname>
   dtctl query "fetch dt.entity.host | limit 1"
   ```
   A `token "" not found` error means step 3A's `--token-ref` was missed or misspelled — re-run `set-context` with `--token-ref`. There is no `dtctl get environment-info` resource — use the query above (or any `dtctl query "fetch dt.entity.*"`) as the connectivity check instead.

## Phase 2 — MCP registration (optional)

Ask the user whether they also want this tenant available as an MCP server (`mcp__<nickname>__*` tools). If no, stop here.

If yes:

1. Do **not** send the user to the classic API-token page. MCP auth follows its own setup — point them at the official guide and open it in the browser so they don't leave the flow:
   - Windows: `Start-Process "https://docs.dynatrace.com/docs/shortlink/dynatrace-mcp-server#prepare-authentication"`
   - macOS: `open "https://docs.dynatrace.com/docs/shortlink/dynatrace-mcp-server#prepare-authentication"`
   - Linux: `xdg-open "https://docs.dynatrace.com/docs/shortlink/dynatrace-mcp-server#prepare-authentication"`

   Tell the user: "Follow 'Prepare authentication' in the linked doc. Dynatrace recommends a **Platform token** over an OAuth client, since OAuth-client tokens are short-lived. At minimum the token/client needs `mcp-gateway:servers:invoke` and `mcp-gateway:servers:read`. If they go the OAuth-client route instead (for automatic refresh), it additionally needs `ai:operator:execute`, the `davis-copilot:*` and `storage:*` scope groups, `document:documents:read`, and `davis:analyzers:read` / `davis:analyzers:execute`. Paste the resulting token here when ready." Wait for it — do not proceed with a guessed or reused token unless the user explicitly says to reuse one, and do not assume Phase 1's dtctl token (classic/API-token scoped) is valid for MCP — they are different credential types with different scopes.

   **Security note:** the token is a live credential. Treat it as consumed the instant it's used
   in step 2 — never write it to a log file, scratch file, commit message, or any location other
   than `.mcp.json`'s `Authorization` header for this one entry.

2. Read the existing `.mcp.json` at the project root (same directory as this environment's `CLAUDE.md`) and add a new entry keyed by `<nickname>`, preserving every existing entry untouched:
   ```json
   "<nickname>": {
     "type": "http",
     "url": "https://<TENANT_ID>.apps.dynatrace.com/platform-reserved/mcp-gateway/v0.1/servers/dynatrace-mcp/mcp",
     "headers": {
       "Authorization": "Bearer <TOKEN>"
     }
   }
   ```
   Use Edit (not a full rewrite) so unrelated entries can't be dropped by accident.

3. Once written, treat the token as consumed: don't echo it back in chat, don't paste it into any other file or log for the rest of the session.

4. Tell the user the new server won't appear until the session reconnects — entries added to `.mcp.json` mid-session are not picked up live. The `mcp__<nickname>__*` tools become available (visible via ToolSearch) only after restarting/reloading Claude Code or starting a fresh session. Don't claim the MCP server is "ready to use" until that reconnect has actually happened — verify by searching for `mcp__<nickname>__` tools before relying on them.

## Verification checklist

- [ ] `dtctl config current-context` shows `<nickname>`
- [ ] `dtctl query "fetch dt.entity.host | limit 1"` returns data (not an auth error)
- [ ] (if MCP requested) `.mcp.json` has the new block and all prior entries intact
- [ ] (if MCP requested, after reconnect) a tool search for `mcp__<nickname>__` returns results
