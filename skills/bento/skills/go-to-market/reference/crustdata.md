# Crustdata API

## Requests through Bento

Call Crustdata through the logged-in `bento` CLI:

```bash
bento service proxy post --service-id crustdata --path /company/identify \
  --headers '{"x-api-version":"2025-11-01"}' --body-file - > identify.json <<'JSON'
{"domains":["hubspot.com"],"exact_match":true}
JSON
```

`--path` is the endpoint path below; send `x-api-version: 2025-11-01` with
`--headers` on every call. The CLI owns login, the workspace (the configured
default; `--workspace <slug>` overrides), and the Crustdata credential; never
look for or request a vendor key. `--body-file -` reads the JSON body from
stdin (use an unquoted `<<JSON` heredoc, or build the body with `jq -n`, to
interpolate shell variables) and `--body-file request.json` reads it from a
file. Without `--out`, the JSON response prints to stdout; redirect it. With
`--out <file>` the response body goes to the file and stdout prints
`{path,status,headers}`, which is how to read `X-Credits-Used`. A non-2xx
response exits non-zero and reports the status, headers, and vendor error body
on stderr.

All search, identify, and enrichment examples below use POST with a JSON body.
Identifier lists and `fields` are JSON arrays. Search conditions use `field`;
sort entries use `field` and `order`. Enrichment returns a top-level array of
input matches, not a flat profile. Check every entry's `matches` before reading
`matches[].company_data` or `matches[].person_data`.

## Choose the endpoint

| Endpoint | Purpose | Vendor credits |
| --- | --- | --- |
| `/company/identify` | Resolve ambiguous company identifiers | Free |
| `/company/enrich` | Company sections selected by `fields` | 2 base; technographics +2 |
| `/company/search` | Indexed company search | 0.03/result + premium groups |
| `/company/professional_network/search/live` | Fresh company search | 2/company |
| `/person/enrich` | Person profile and employment history | 1 base; add-ons up to 9 |
| `/person/search` | Indexed person search | 0.03/result + premium groups |
| `/person/professional_network/enrich/live` | Fresh profile retrieval | 7/profile |
| `/person/professional_network/search/live` | Fresh people search | 2/profile |
| `/person/contact/enrich` | Emails and phones for confirmed profiles | Per field per match: business email 1, personal email 2, phones 2 |
| `/person/identify` | Profile URL from an email | 1/match |
| `/company/search/autocomplete`, `/person/search/autocomplete`, `/job/search/autocomplete` | Discover valid filter values | Free |
| `/job/search` | Indexed job listing search and counts | 0.03/result |
| `/job/professional_network/search/live` | Fresh listings for one company | 2/result |
| `/social_post/search` | Indexed post search | 0.5/post |
| `/social_post/professional_network/enrich/live` | Fresh posts for an author or post URL | 1/post; reactors/comments extra |
| `/social_post/professional_network/search/live` | Fresh keyword post search | 1/post; reactors/comments extra |
| `/web/search/live` | Web, news, academic, and social search | 1/query |
| `/web/enrich/live` | Page HTML for up to 10 URLs | 1/page |
| `/watch/{dataset}/search`, `/watch/{dataset}` | Recurring discovery or change monitoring | Per delivered record, billed per run; baseline free |

## Billing

Every synchronous call charges the credits Crustdata reports in its
`X-Credits-Used` response header (searches bill per result, enrichment per
record and requested field), plus Bento's margin. Free endpoints such as
autocomplete and company identify cost nothing.

Watches bill when they run. The create and read calls cost nothing and report
`0`, but once Crustdata records a run's credits, within minutes of the run,
Bento charges the workspace that created the watch. Treat a watch's cost as real
spend and bound it with `max_results_per_run`.
Rates and add-ons are in [current pricing](https://docs.crustdata.com/general/pricing.md).

## Workflows

- **Company:** identify only when identity is ambiguous; otherwise enrich a known
  domain directly. Request all needed sections in one call — omitted `fields`
  returns only basic company information.
- **People:** search with current-employer filters, verify the returned employer,
  then enrich selected profile URLs together (up to 25). Explicitly request
  `experience`, `education`, and `skills` if the task needs them.
- **Pagination:** pass `next_cursor` back as `cursor` with the same query, stop
  when it is null or the task's result budget is met. Do not repeatedly start
  the same search from page one. Prefer small limits while tuning filters.
- **Large approved sets:** Bento does not offer Crustdata's `/batch/...` jobs.
  Page through the synchronous search, and enrich in groups of up to 25.
- **Monitoring:** a [watch](crustdata-watch-api.md) re-runs a search or tracks
  a list for changes. It runs until deleted, a workspace holds at most 10 at
  once, and only the creating workspace can reach it; keep its `id`.
- **Errors:** respect `Retry-After` on 429, bound retries, and stop on permission
  or credit errors rather than repeating the same request. Field access varies
  by account; narrow a denied field only if the task can proceed without it.

## References

- [Company identify, enrich, search, and employee reviews](crustdata-company-api.md)
- [People enrich, search, live search, and developer profiles](crustdata-people-api.md)
- [Contact enrichment and identify by email](crustdata-contact-api.md)
- [LinkedIn posts](crustdata-linkedin-api.md)
- [Jobs search and live listings](crustdata-jobs-api.md)
- [Web search and page fetch](crustdata-web-api.md)
- [Watches](crustdata-watch-api.md)
- [Provider documentation index](https://docs.crustdata.com/llms.txt) — use the
  Markdown links for current schemas, filter fields, and account-specific limits.
