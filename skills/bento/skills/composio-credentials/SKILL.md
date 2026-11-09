---
name: composio-credentials
description: Call a workspace's connected integrations (Gmail, Slack, CRMs and other OAuth accounts) through Bento with the bento CLI — find or connect an account, then execute one of its provider tools. Use when a task needs data from, or an action in, a connected third-party account, including from app server code.
---

# Integrations

Bento keeps each integration's credentials at the provider and attaches them
server-side; never ask a person for a provider password or token. The CLI owns
the login and the workspace (the selected default; `--workspace <slug>`
overrides it).

## Find or connect an account

```bash
bento integration catalog list --q gmail --json
bento integration connection list --json
```

A catalog item is `connected` when its `connectedAccountCount` is positive. Each
active account is its own connection row; its lifecycle `id` (for example
`ca_work`) is the selection key, and labels may repeat. Follow `nextCursor`
until it is null.

To connect a new account, start the authorization with a same-origin product
path to return to, send the person the returned `authorizeUrl`, then list
connections again after they finish. An authorization URL alone does not prove
the account is active, and a cancelled authorization is a normal outcome with
no connection.

```bash
bento integration connect --redirect-to "/w/<workspaceSlug>" --body-file - <<'JSON'
{"integration":"gmail"}
JSON
```

## Execute a tool

Integration tools named `integrations__*` already carry each tool's schema;
call them directly when they are among your tools. Otherwise find the
provider's current tool slug and argument schema in its toolkit documentation
before calling it. Send the tool's arguments under `arguments`:

```bash
bento integration tool execute --tool-slug GMAIL_FETCH_EMAILS --connected-account-id ca_work \
  --body-file - <<'JSON'
{"arguments":{"query":"from:billing newer_than:7d"}}
JSON
```

This route takes its workspace from the body, not from `--workspace`. When the
login reaches several workspaces, add `"workspace":"<slug>"` beside
`arguments`, using a slug from `bento whoami`. A `workspace_ambiguous` error
means it was needed.

Omit `--connected-account-id` only when the toolkit has exactly one active
account. `integration_account_required` (409) asks you to choose one;
`integration_account_unavailable` (409) means the account is missing, inactive
or unsuitable, so list connections again. A failed explicit choice never falls
back to another account. `integration_provider_failed` (502) is an incomplete
provider inventory. Provider-declared no-auth tools take no account and reject
one as `invalid_request` (400).

The response is the provider's own. Verify the intended upstream result before
reporting success, and read provider state before repeating a write after an
uncertain response.

## From app server code

An app declares `integrations` in its `apiScopes` and calls the same execution
route with its own app credential; follow
[the integration workflow](https://docs.bento.ing/integrations.md#call-a-connected-integration-from-an-app).
Keep that credential on the server, never in browser code.
