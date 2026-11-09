---
name: go-to-market
description: Research accounts, enrich leads, research a person into a professional dossier with work history and verified contact details, pick the contacts worth reaching at an account, look up firmographics, query Crustdata APIs, profile/research/analyze competitors, write sales emails, perform SEO keyword research, Amazon/Google Shopping product research, App Store optimization, AI search visibility analysis, and website technology lookups using DataForSEO.
---

# Go-to-Market

Workflows for account research, lead enrichment, contact discovery, competitive intelligence, sales email writing, SEO keyword research, ecommerce product research, app store optimization, AI search visibility, and website technology analysis.

## Service proxy boundary

Every executable call in these workflows goes through the logged-in CLI's
service proxy: a `bento service proxy` call (`post`, or `get` for read-only
routes) with `--service-id dataforseo` or `--service-id crustdata` and
`--path <endpoint>`. It supplies the vendor credential and bills the workspace.
Discover routes with `bento service list` and `bento service get`, then use the
returned path exactly. Never look for a vendor credential or call a vendor host
directly.

## Workflows

| Workflow                | When to Use                                                                                              | Reference                                                                        |
| ----------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| Account Research        | Research a target company — delivers visual report with infographics                                     | [sub-skills/account-research.md](sub-skills/account-research.md)                 |
| Lead Enrichment         | Synthesize research into sales strategies                                                                | [sub-skills/lead-enrichment.md](sub-skills/lead-enrichment.md)                   |
| Contact Search          | Profile one person into a one-page dossier, or pick and rank the contacts worth reaching at an account   | [sub-skills/contact-search.md](sub-skills/contact-search.md)                     |
| Firmographics           | Gather structured company data (industry, size, funding)                                                 | [sub-skills/firmographics.md](sub-skills/firmographics.md)                       |
| Competitor Profile      | Quick competitor company/product profile                                                                 | [sub-skills/competitor-profile.md](sub-skills/competitor-profile.md)             |
| Competitor Research     | In-depth competitor research — delivers visual report with infographics                                  | [sub-skills/competitor-research.md](sub-skills/competitor-research.md)           |
| Competitor Analysis     | SWOT analysis and feature comparison with infographic                                                    | [sub-skills/competitor-analysis.md](sub-skills/competitor-analysis.md)           |
| Email Writing           | Compose sales and follow-up emails                                                                       | [sub-skills/email-writing.md](sub-skills/email-writing.md)                       |
| SEO Keyword Research    | Find high-opportunity keywords, analyze difficulty, competitor gaps                                      | [sub-skills/seo-keyword-research.md](sub-skills/seo-keyword-research.md)         |
| Amazon Keyword Research | Amazon product keyword research, search volume, competitor ASINs                                         | [sub-skills/amazon-keyword-research.md](sub-skills/amazon-keyword-research.md)   |
| Google Shopping         | Product pricing, competitor landscape, and seller analysis                                               | [sub-skills/google-shopping-research.md](sub-skills/google-shopping-research.md) |
| App Store Research      | ASO keyword research for Apple App Store and Google Play                                                 | [sub-skills/app-store-research.md](sub-skills/app-store-research.md)             |
| AI Search Visibility    | Google AI Overview/AI Mode citation tracking, AI search volume, LLM mentions, competitor AI benchmarking | [sub-skills/ai-search-visibility.md](sub-skills/ai-search-visibility.md)         |
| Website Technologies    | Identify tech stack of any website (CMS, analytics, hosting, etc.)                                       | [sub-skills/website-technologies.md](sub-skills/website-technologies.md)         |

## Data Sources

| Source                       | What It Provides                                                                                                                            | Reference                                                                              |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Crustdata API                | Endpoint choice, credit costs, and billing for company, people, contact, jobs, posts, web, and watch data                                   | [reference/crustdata.md](reference/crustdata.md)                                       |
| Crustdata Company API        | Company identification, enrichment, search, and employee reviews                                                                            | [reference/crustdata-company-api.md](reference/crustdata-company-api.md)               |
| Crustdata People API         | People enrichment, search, live search, and developer profiles                                                                              | [reference/crustdata-people-api.md](reference/crustdata-people-api.md)                 |
| Crustdata Contact API        | Work and personal emails, phone numbers, and identifying a person from an email                                                             | [reference/crustdata-contact-api.md](reference/crustdata-contact-api.md)               |
| Crustdata LinkedIn API       | LinkedIn post retrieval and keyword search                                                                                                  | [reference/crustdata-linkedin-api.md](reference/crustdata-linkedin-api.md)             |
| Crustdata Jobs API           | Job listing search, hiring counts, and fresh listings for one company                                                                       | [reference/crustdata-jobs-api.md](reference/crustdata-jobs-api.md)                     |
| Crustdata Web API            | Web, news, and academic search, and fetching page HTML                                                                                      | [reference/crustdata-web-api.md](reference/crustdata-web-api.md)                       |
| Crustdata Watch API          | Recurring discovery and change monitoring for one day                                                                                       | [reference/crustdata-watch-api.md](reference/crustdata-watch-api.md)                   |
| DataForSEO API               | SEO keyword research, search volume, keyword difficulty, SERP analysis                                                                      | [reference/dataforseo.md](reference/dataforseo.md)                                     |
| DataForSEO Amazon API        | Amazon keyword research, product competitors, search volume                                                                                 | [reference/dataforseo-amazon.md](reference/dataforseo-amazon.md)                       |
| DataForSEO Google Shopping   | Google Shopping product search, sellers, product specs                                                                                      | [reference/dataforseo-google-shopping.md](reference/dataforseo-google-shopping.md)     |
| DataForSEO App Store API     | Apple App Store & Google Play keyword research, app competitors, reviews                                                                    | [reference/dataforseo-app-store.md](reference/dataforseo-app-store.md)                 |
| DataForSEO AI Optimization   | AI search volume, Google AI Mode, AI Overview tracking, LLM Mentions (search, aggregated metrics, top domains, top pages, cross-comparison) | [reference/dataforseo-ai-optimization.md](reference/dataforseo-ai-optimization.md)     |
