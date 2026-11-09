# Web API Reference

Use the [shared request conventions](crustdata.md). Both endpoints are POST and
limited to 10 requests per minute. Search finds URLs; fetch returns their HTML.

## Search the web

```bash
bento service proxy post --service-id crustdata --path /web/search/live \
  --headers '{"x-api-version":"2025-11-01"}' --body-file - <<'JSON'
{"query":"crustdata series a","sources":["news"],"location":"US"}
JSON
```

Costs 1 credit per query. `query` is required (up to 5,000 characters, accepts
`site:` and `filetype:`). Optional:

| Key | Notes |
| --- | --- |
| `sources` | `web`, `news`, `scholar-articles`, `scholar-articles-enriched`, `scholar-author`, `ai`, `social`. Omitting it searches all of them in mixed shapes; always send it. |
| `site` | One domain, such as `github.com`. Applies to `web` and `news` only. |
| `start_date`, `end_date` | Unix seconds; start must be before end. Ignored by `scholar-author`, `ai`, and `social`. |
| `location` | ISO 3166-1 alpha-2 country code. |
| `page` | Pages to aggregate, 1 to 15. Above 1 requires exactly one source. |
| `human_mode` | Browser-like retrieval when bot protection blocks the standard path. |

Response: `{success, query, timestamp, results, metadata}`. `web` and `news`
results are `{source, title, url, snippet, position}`; scholar results add
`authors`, `citations`, and `pdf_url`; `scholar-author` returns a profile
(`name`, `affiliation`, `citations`, `h_index`) with no `title` or `position`;
`ai` returns `content` and `references`. `timestamp` is in milliseconds.

## Fetch pages

```bash
bento service proxy post --service-id crustdata --path /web/enrich/live \
  --headers '{"x-api-version":"2025-11-01"}' --body-file - <<'JSON'
{"urls":["https://example.com","https://example.org"]}
JSON
```

Costs 1 credit per page. `urls` takes 1 to 10 absolute URLs with the scheme;
`human_mode` is optional. The response is a **bare array** of
`{success, url, timestamp, title, content}`, where `content` is the full
server-side HTML and `timestamp` is in seconds.

- A 200 can hold failures. A failed entry has `success: false` and every other
  field `null`, including `url`.
- Order is not guaranteed. Match entries to inputs by `url`; an input with no
  successful entry failed.
- JavaScript-rendered pages may come back nearly empty.

Sources: [web search](https://docs.crustdata.com/web-docs/search/introduction),
[search reference](https://docs.crustdata.com/web-docs/search/reference),
[web fetch](https://docs.crustdata.com/web-docs/fetch/introduction),
[pricing](https://docs.crustdata.com/general/pricing.md).
