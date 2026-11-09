# Jobs API Reference

Use the [shared request conventions](crustdata.md). All endpoints here are POST.
Indexed search answers hiring questions across companies; live search fetches
fresh listings for one company.

## Indexed search

```bash
bento service proxy post --service-id crustdata --path /job/search \
  --headers '{"x-api-version":"2025-11-01"}' --body-file - <<'JSON'
{
  "filters":{"op":"and","conditions":[
    {"field":"company.basic_info.company_id","type":"=","value":631394},
    {"field":"job_details.title","type":"(.)","value":"account executive"},
    {"field":"metadata.date_added","type":"=>","value":"2026-09-01"}
  ]},
  "fields":["crustdata_job_id","job_details.title","job_details.url","company.basic_info.name","location.raw","metadata.date_added"],
  "sorts":[{"field":"metadata.date_added","order":"desc"}],
  "limit":20
}
JSON
```

Response: `{job_listings, next_cursor, total_count, aggregations?}`. Each job
has `crustdata_job_id` (the dedupe key), `job_details` (title, category, url,
workplace type, `source`, `employment_type`), `company` (the hiring company's
firmographics at index time), `location` (the job's, not the HQ), `content`
(description), and `metadata.date_added` (the posting date on the source).

- Always send `fields`; the full record carries firmographics and the
  description. `limit` is 0 to 1,000, default 20. Paginate with `next_cursor`
  as `cursor`. `total_count` can be null for broad queries.
- Filter by company with the alias `company.basic_info.company_id`; the
  response returns the same integer as `company.basic_info.crustdata_company_id`.
  The alias is not sortable. Resolve a domain to the ID with the free
  `/company/identify` ([Company API](crustdata-company-api.md)).
- Operators: `=`, `!=`, `<`, `=<`, `>`, `=>`, `in`, `not_in`, `is_null` and
  `is_not_null` (send `"value": null`), `(.)` (all words, typo-tolerant), `[.]`
  (exact phrase; use it for brands and products), and `geo_distance` on
  `location`. Write `=>` and `=<`, never `>=` or `<=`.
- Bound recent-hiring questions with `metadata.date_added`.
- For counts only, send `"limit":0` with
  `"aggregations":[{"type":"group_by","field":"company.basic_info.company_id","agg":"count","size":50}]`
  or `{"type":"count"}`. A query with no results costs nothing.

Common filter fields: `job_details.title`, `job_details.category`,
`job_details.workplace_type`, `job_details.source`, `company.basic_info.name`,
`company.basic_info.primary_domain`, `company.headcount.total`,
`location.country`, `metadata.date_added`.

`/job/search/autocomplete` returns stored values for a filter field; it is free.
Send `{"field":"job_details.title","query":"account exec","limit":10}` (`limit`
1 to 100, no pagination) and use `suggestions[].value` in filters.

## Live search for one company

`/job/professional_network/search/live` fetches fresh listings straight from
one company's profile: one company per call, no filters, no pagination. It
costs 2 credits per listing returned and is limited to 10 requests per minute.
Its response wraps listings in `job_listings`; live listings omit
`job_details.source` and `employment_type`. Its request schema is not publicly
documented. Prefer indexed search unless the task needs listings posted since
the last index refresh.

Sources: [search](https://docs.crustdata.com/job-docs/search/introduction),
[search reference](https://docs.crustdata.com/job-docs/search/reference),
[autocomplete](https://docs.crustdata.com/job-docs/autocomplete/introduction),
[pricing](https://docs.crustdata.com/general/pricing.md).
