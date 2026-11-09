# Watch API Reference

Use the [shared request conventions](crustdata.md). A watch re-runs on a
schedule and delivers only what is new: a **discovery watch** re-runs a search
and delivers records that newly match it; an **entity watch** tracks a fixed
list of people or companies and delivers the ones that changed.

## Lifetime, ownership, and cost

- A watch runs until you delete it. Bento deletes every watch of a workspace
  that can no longer pay for it: one that is deleted, out of credits, or past
  its monthly cap. Delete a watch as soon as you stop reading its runs.
- Only the workspace that created a watch can read, test, update, delete, or
  list runs of it. There is no route that lists watches; keep the `id` the
  create call returns.
- A workspace holds at most **10 live watches**, discovery and entity together.
  An eleventh create is refused with 409 `pool_resource_limit`; delete a watch
  you no longer need before creating another.
- Create, read, test, and preview calls cost nothing. Recurring runs bill per
  record delivered, and Bento charges the creating workspace once Crustdata
  records the run's credits, within minutes of the run. Treat every run as real
  spend even though the create response says `0`.
- A run delivers at most **25 records** through Bento: `config.max_results_per_run`
  defaults to 25, and a create or update asking for more is refused with 400
  `request_refused`. Creating a watch, or moving a person entity watch to a
  dearer `refresh_frequency_days`, needs the balance for one full run at the
  watch's rate (for example 25 × 150 credits for a realtime watch); otherwise
  it is refused with 402 `insufficient_credits`. Lower `max_results_per_run` to
  fit. An update that sets `max_results_per_run` is priced at the dearest rate,
  150 credits a record, because it does not restate the watch's rate; to
  enlarge a cheap watch's runs on a small balance, recreate it instead.

| Watch | Credits per delivered record |
| --- | --- |
| Discovery, `person` or `job` | 0.5 |
| Discovery, `company` or `social_post` | 2 |
| Discovery with `config.is_realtime: true` | 150 |
| Entity, `company` | 5 per changed company |
| Entity, `person` | 5 per changed person at the default `refresh_frequency_days: 30`; 10 at 14, 20 at 7, 50 at 3, 150 at 1 |

The first run is always a free baseline. A run that finds nothing new or no
change costs nothing. `fields` never changes the price.

## Discovery watches

`POST /watch/{dataset}/search` for `person`, `company`, `job`, or `social_post`.
`filters` uses the same fields and operators as that dataset's search endpoint
(see the [company](crustdata-company-api.md), [people](crustdata-people-api.md),
[jobs](crustdata-jobs-api.md), and [posts](crustdata-linkedin-api.md)
references). A company watch may also filter on job and person fields, joined
through the hiring company or current employer.

```bash
bento service proxy post --service-id crustdata --path /watch/company/search \
  --headers '{"x-api-version":"2025-11-01"}' --body-file - > watch.json <<'JSON'
{
  "filters":{"op":"and","conditions":[
    {"field":"locations.country","type":"in","value":["USA"]},
    {"field":"headcount.total","type":"=>","value":200}
  ]},
  "fields":["basic_info","headcount"],
  "config":{"trigger":{"type":"interval","every_hours":6},"max_results_per_run":10},
  "notifications":[]
}
JSON
WATCH_ID=$(jq -r '.id' watch.json)
```

| Key | Notes |
| --- | --- |
| `filters` | Required, except on a realtime watch. A filter matching more than 500,000 records is a 400; narrow it. |
| `config.trigger` | Required: `{"type":"interval","every_hours":N}`. |
| `config.max_results_per_run` | 1 to 25 through Bento, default 25. |
| `config.payload_delivery_type` | `inline` (default) or `link`: the run's records as one NDJSON file behind a pre-signed URL valid 5 days. |
| `config.is_realtime` | Searches live on each run, takes `realtime_filters` instead of `filters`, forces `every_hours` ≥ 24, and costs 150 per record. Use it only when a daily refresh is worth 150 credits a record against the indexed watch's 0.5 to 2. |
| `fields`, `sorts` | Projection and in-run order. |
| `overflow_policy` | `redeliver` (default) holds matches beyond the cap for a later run; `drop` discards them. |
| `notifications` | Required array; may be `[]`. |

The baseline delivers a sample of up to 5 current matches and marks every
current match as seen, so later runs deliver only records that newly match.

Manage it at `/watch/{dataset}/search/{watch_id}` with `bento service proxy
get`, `patch`, or `delete` and the same `x-api-version` header: `GET` returns the watch with
`credits_consumed` and `notifications_count`; `PATCH` changes only `status`
(`active`, `paused`, `cancelled`), `config`, and `notifications`; `DELETE`
returns 204 and is terminal. A `config` PATCH must repeat the current `trigger`
or it is a 400. `filters`, `sorts`, `fields`, and `on` are fixed: create a new
watch to change what is matched.

`POST /watch/{dataset}/search/{watch_id}/test` builds a sample from real current
matches without recording a run or spending credits. Optional body:
`notification_endpoint` (a public URL), `count` (1 to 25), `deliver: false` to
get the envelope back without sending it. A 400 saying the filter matches 0
records means the watch would never deliver either.

## Entity watches

`POST /watch/{dataset}` for `person` or `company`.

```bash
bento service proxy post --service-id crustdata --path /watch/person \
  --headers '{"x-api-version":"2025-11-01"}' --body-file - > watch.json <<'JSON'
{
  "entities":{"professional_network_profile_urls":["https://www.linkedin.com/in/sherryrobinson"]},
  "track":{"field":"experience.employment_details.current","type":"added"},
  "fields":["basic_profile","experience"],
  "config":{"trigger":{"type":"interval","every_hours":6},"max_results_per_run":25},
  "notifications":[]
}
JSON
```

- `entities`: person watches take `professional_network_profile_urls` only.
  Company watches take `domains`, `names`, `professional_network_profile_urls`,
  or `crustdata_company_ids`, mixed freely; prefer domains or IDs, since a name
  can resolve to the wrong company. Up to 10,000 per watch.
- `track` decides **when** a record fires; `fields` decides **what** it carries
  (default: `basic_info` for companies, `basic_profile` and `social_handles` for
  people). The tracked field is not added to `fields` automatically.
- A `track` leaf is `{field, type, value?}` over the enrich response's paths.
  `changed` takes a scalar (`basic_profile.current_title`, `headcount.total`),
  `added` takes an array (`news`, `funding.milestones`,
  `experience.employment_details.current`), and `>`, `<`, `=`, `!=`, `=>`, `=<`
  fire when the comparison turns true. Mixing scalar and array operators is a
  400. Combine leaves with `{"op":"and"|"or","conditions":[...]}`.
- Add `"keys":["article_url"]` to an `added` leaf to fire once per identity
  rather than once per copy. `funding.investors` holds plain strings and
  rejects `keys`.
- Requesting or tracking a field the account is not entitled to fails the
  create with 403.

The baseline snapshots each subject, fires on nothing, and sends a free sample
of up to 5 subjects with `changes: []`. Later runs fire only on a transition and
never repeat one.

Before creating, `POST /watch/{dataset}/test` with a draft `track` and `fields`
returns a sample notification built from a demo profile. It saves nothing and
is free. Its full request schema is not publicly documented.

Manage it at `/watch/{dataset}/{watch_id}`: `GET`, `PATCH`, `DELETE` (204,
terminal). PATCH changes `status`, `entities`, `config`, and `notifications`;
new subjects are baselined silently. `track` and `fields` are fixed. A `config`
PATCH must repeat the current `trigger`. `POST .../{watch_id}/test` sends a
sample with placeholder values; optional body `notification_endpoint`,
`fields`, `count`.

## Runs

The run routes drop the `search/` segment, even for discovery watches: a watch
created at `/watch/job/search` reads its runs at `/watch/job/{watch_id}/runs`.

```bash
bento service proxy get --service-id crustdata --path "/watch/company/$WATCH_ID/runs" \
  --query '{"limit":"20"}' --headers '{"x-api-version":"2025-11-01"}' > runs.json
```

Delete a discovery watch once you stop reading its runs:
`bento service proxy delete --service-id crustdata --path "/watch/company/search/$WATCH_ID" --headers '{"x-api-version":"2025-11-01"}'`.

`GET /watch/{dataset}/{watch_id}/runs` returns `{runs, next_cursor,
total_count}`, newest first. Each run has `status`, `credits_deducted`,
`notification_http_status`, and counters: `records_searched` (what the run
started from), `records_after_filter` (new or changed), `new_records_count`
(delivered), plus `records_stale` on discovery runs and `records_matched` on
entity runs. A gap between `records_searched` and `records_matched` is the part
of an entity list that resolved to nothing. Add `only_credited=true` to see
only billed runs.

`GET /watch/{dataset}/{watch_id}/runs/{run_id}/summary` returns one run with
its delivered records under `notifications[].payload.notifications[]`, each
with `changes` and `record`. Records come back only for a run whose `status` is
`SUCCESS`. On a `link` watch, the summary carries `payload_delivery` with a
fresh link instead.

## Notification channels

`notifications` is an array of channels, and every run fans out to all of them:

| Channel | Shape |
| --- | --- |
| Webhook | `{"type":"webhook","url":"https://...","headers":{...}}` |
| Slack | `{"type":"slack","webhook_url":"https://hooks.slack.com/services/..."}`; any other URL fails delivery |
| Google Chat | `{"type":"google_chat","url":"https://chat.googleapis.com/v1/spaces/..."}` |
| Email | `{"type":"email","to":["you@company.com"]}` |
| Pull-only | `[]`: nothing is pushed; read each run from the run routes |

Prefer pull-only unless the user wants a push. A webhook needs a public HTTPS
receiver; pair a receiver with a small body limit with
`payload_delivery_type: "link"`. Deliveries are signed with
`x-crustdata-signature`, keyed by the vendor credential Bento holds, so a
receiver you run cannot verify them.

A discovery notification carries records under `results.added`; an entity
notification's `results` is a flat list of `{changes, record}`. A `changed`
entry has `from` and `to`; an `added` entry has `new_elements`. Read
`metadata.payload_delivery.type` rather than testing for `results`.

## Errors

Watch management is limited to 10 requests per minute per watch path; on 429,
wait `X-RateLimit-Reset` seconds. A watch is `suspended` rather than partially
delivered when the balance is too low. A cancelled or deleted watch cannot be
modified or reactivated.

Sources: [watch API](https://docs.crustdata.com/api-reference/watch-apis/create-a-discovery-watch),
[company discovery](https://docs.crustdata.com/watcher-docs/company/discovery),
[person entity](https://docs.crustdata.com/watcher-docs/person/entity),
[pricing](https://docs.crustdata.com/general/pricing.md).
