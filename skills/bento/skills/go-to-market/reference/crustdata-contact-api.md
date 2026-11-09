# Contact API Reference

Use the [shared request conventions](crustdata.md). Both endpoints are POST,
synchronous, and take at most 25 identifiers per call.

## Enrich contact channels

```bash
bento service proxy post --service-id crustdata --path /person/contact/enrich \
  --headers '{"x-api-version":"2025-11-01"}' --body-file - <<'JSON'
{
  "professional_network_profile_urls":["https://www.linkedin.com/in/dvdhsu/"],
  "fields":["contact.business_emails"],
  "verified":true
}
JSON
```

Send exactly one identifier type: `professional_network_profile_urls` or
`business_emails`. Mixing them is a 400. There is **no name-and-company
lookup**: confirm the person and get their profile URL first (see
[the People API](crustdata-people-api.md)), then enrich that URL.

`fields` accepts contact fields only; a profile field such as `basic_profile` is
a 400. Always send `fields` — omitting it requests every paid field.

| Field | Credits per matched person | When |
| --- | --- | --- |
| `contact.business_emails` | 1 (+0.5 with `verified`) | Default. The work email. |
| `contact.personal_emails` | 2 | Only when no business email came back and the user wants a personal address. |
| `contact.phone_numbers` | 2 | **Only on the user's explicit word.** Returns `phone_numbers` and the structured `phone_numbers_info`. |
| `contact.websites` | 0 | Personal sites, when useful. |

Billing is per requested field per matched person; unmatched and redacted
inputs are free. The `X-Credits-Used` response header reports the exact charge.

`verified: true` re-checks business emails at request time and returns only
`deliverable` and `catch_all` addresses. Use it whenever the address is headed
for outreach. If nothing survives, `business_emails` is empty and
`business_emails_message` says `"no verified emails found"`.

Response: a top-level array with one entry per input,
`{matched_on, match_type, match_status, matches}`. `match_status` is `matched`,
`not_found`, or `redacted`. Read `matches[0].person_data.contact`:

| Path under `contact` | Shape |
| --- | --- |
| `business_emails[]`, `personal_emails[]` | `{email, status}`; status is `deliverable`, `catch_all`, `invalid`, or `unknown` |
| `phone_numbers[]` | Strings such as `+15555550123` |
| `phone_numbers_info[]` | `{country_code, country, phone_number, type}`; type is `mobile`, `home`, `work`, or `other` |
| `websites[]` | URLs |

Carry `status` through to the deliverable. `deliverable` was verified;
`catch_all` means the domain accepts every address, so nothing could be
confirmed. Drop `invalid`. An address the provider did not return is
`unfound` — never a pattern assembled from `first.last@domain`. A `redacted`
person asked to be removed; do not retry or look for their contact details
another way.

The default rate limit is 15 requests per minute, shared with the live
endpoints. Batch up to 25 profiles per call rather than looping one at a time.

## Identify a person from an email

```bash
bento service proxy post --service-id crustdata --path /person/identify \
  --headers '{"x-api-version":"2025-11-01"}' --body-file - <<'JSON'
{"emails":["abhilash@crustdata.com"]}
JSON
```

Send exactly one of `emails`, `professional_network_profile_urls`, or
`research_profile_urls`. The key is `emails`, not `business_emails`. It costs
1 credit per matched identifier. Each match's `person_data` holds
`basic_profile` (name, `current_title`, location) and
`social_handles.professional_network_identifier.profile_url`; it does not hold
work history or contact data. Enrich the returned profile URL for those.

An address not already on file is matched by name at the company that owns the
domain, and its `confidence_score` falls below 1. Treat anything under 1 as a
candidate to verify, not a confirmed identity.

Personal addresses such as Gmail do not match: Crustdata resolves them only
through batch jobs, which Bento does not offer. Ask the user for a work email or
profile URL instead.

Sources: [contact enrich](https://docs.crustdata.com/person-docs/contact/enrich.md),
[contact enrich API](https://docs.crustdata.com/api-reference/person-apis/enrich-only-person-contact-data-from-cached-dataset.md),
[identify](https://docs.crustdata.com/api-reference/person-apis/identify-people-from-profile-urls-emails-or-google-scholar-profile-urls.md).
