---
name: app-api
description: Call Bento, its model gateway and paid services over HTTP from code you are writing — an app server, a script, an SDK client. Covers which key the code uses, gateway SDK setup, and turning any `bento service proxy` example into a request. For a one-off task, use the `bento` CLI instead.
---

# App API

The `bento` CLI is how you call Bento. Reach for HTTP only inside code you are
writing: an app's server, or a script that orchestrates more than a few
commands — which is an app in all but name. Every capability skill teaches its
calls as CLI commands; this skill is how those calls look from code.

## Which key the code uses

The code reads its key and origins from its environment, never from a file it
ships or a value you paste into source. Who runs the code decides what it reads:

| Who runs it | Key | API origin | Gateway origin |
| --- | --- | --- | --- |
| Bento, as a registered app | `BENTO_APP_API_KEY` | `BENTO_API_URL` | `BENTO_GATEWAY_BASE_URL` |
| Another host, with an exported credential | `BENTO_APP_API_KEY` | `BENTO_API_URL` | `BENTO_GATEWAY_BASE_URL` |
| You, as a script | `BENTO_API_KEY` | `BENTO_API_URL` | `BENTO_GATEWAY_BASE_URL` |

An app key carries exactly the capabilities in the app's `apiScopes` and is bound
to one workspace; it bills and attributes work to the app. Bento injects it into
an app it runs. For another host, export one with
`bento app credential create --app-slug <slug> --body-file -` (body
`{"expiration":"never"}`, or `{"expiration":{"seconds":2592000}}`) and store the
returned `key`, `apiUrl` and `gatewayBaseUrl` under the three names above in
that host's server-side secrets — never in browser code, source control or chat.

A script you run acts as you. Start it with your login and the origins the CLI
itself calls:

```bash
export BENTO_API_KEY="${BENTO_API_KEY:-$(bento token)}"
eval "$(bento local config get --json | jq -r '@sh "export BENTO_API_URL=\(.apiUrl) BENTO_GATEWAY_BASE_URL=\(.gatewayUrl)"')"
bun run script.ts
```

Send the key as `Authorization: Bearer <key>` on every request. An app key is
bound to its workspace. Your login can span several, so a script names one in
`x-duet-workspace: <slug>` on service and gateway calls, the way the CLI does.

## Bento's own API

Each `bento <command>` is one REST route; `bento <command> --help` prints its
method, path, body fields and response. Workspace routes carry the workspace in
the path. Resolve an app key's workspace once with `GET $BENTO_API_URL/v1/whoami`
rather than assuming a slug.

## Paid services

Every service call a skill teaches is one request: the method is the proxy
subcommand, and `--service-id` and `--path` make the URL
`$BENTO_API_URL/v1/services/<service-id><path>`. Its `--body-file` is the request
body, `--query` the query string and `--headers` extra headers. The response is
the vendor's own status and body. The firecrawl skill's
`bento service proxy post --service-id firecrawl --path /v2/scrape` is:

```bash
curl -fsS -X POST "$BENTO_API_URL/v1/services/firecrawl/v2/scrape" \
  -H "Authorization: Bearer $BENTO_APP_API_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://example.com","formats":["markdown"]}'
```

An app needs `services` in `apiScopes` to call a service or the gateway; without
it the answer is `insufficient_scope`.

## Models

Each model command sends its body unchanged to a gateway route:

| Command | Gateway route |
| --- | --- |
| `bento model list` | `GET /v1/models` |
| `bento model chat` | `POST /v1/chat/completions` |
| `bento model responses` | `POST /v1/responses` |
| `bento model messages` | `POST /v1/messages` |
| `bento model embedding` | `POST /v1/embeddings` |
| `bento model image` | `POST /v4/ai/image-model` |

SDK clients point at the same gateway. Each takes the key as its API key and
`x-duet-tier: services` as a default header, which bills the call at provider
cost:

```typescript
import { createGateway } from 'ai'
import Anthropic from '@anthropic-ai/sdk'
import OpenAI from 'openai'

const key = process.env.BENTO_APP_API_KEY
const gatewayUrl = process.env.BENTO_GATEWAY_BASE_URL
const headers = { 'x-duet-tier': 'services' }

const gateway = createGateway({ baseURL: `${gatewayUrl}/v4/ai`, apiKey: key, headers })
const openai = new OpenAI({ baseURL: `${gatewayUrl}/v1`, apiKey: key, defaultHeaders: headers })
const anthropic = new Anthropic({ baseURL: gatewayUrl, apiKey: key, defaultHeaders: headers })
```

Choose the model from the current `GET /v1/models` response; never hardcode a
provider slug. Model choice, protocols, long video jobs and billing are the
[AI gateway skill](../ai-gateway/SKILL.md).
