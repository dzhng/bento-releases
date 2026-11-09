---
name: branded-content
description: >-
  Generate branded social media content for a person. Extracts brand identity from
  a website (colors, fonts, logo, voice) via Firecrawl, enriches a person's profile
  via Crustdata (LinkedIn URL or email), then generates
  a branded social media post (text + 1:1 image). Use when asked to create branded
  content, social media posts with company branding, or personalized marketing visuals.
---

# Branded Content Generation

Create personalized, on-brand social media content for a person by combining website branding extraction with person enrichment.

## Upstream APIs

Every service call goes through `bento service proxy`, which supplies the
Firecrawl and Crustdata credentials and bills the workspace; never send a
vendor key. A non-2xx response exits non-zero with the status and vendor error
body on stderr.

## Workflow Overview

```
Input: website URL + (LinkedIn URL or email)
  ↓
Step 1: Extract branding from website (Firecrawl)
Step 2: Enrich person profile (Crustdata)
Step 3: Generate branded post text + 1:1 image + short video
  ↓
Output: Social media post (text + image + video)
```

## Step 1: Extract Branding

Use Firecrawl to pull brand identity from the person's company website.

### 1a. Visual identity (colors, fonts, logo)

```bash
mkdir -p .firecrawl
bento service proxy post --service-id firecrawl --path /v2/scrape --body-file - > .firecrawl/brand-visual.json <<'JSON'
{"url": "<WEBSITE_URL>", "formats": ["branding"]}
JSON
```

Key fields under the response's `data`:

- `branding.colors` — primary, accent, background, text colors
- `branding.fonts` — font families
- `branding.images.logo` — logo URL
- `branding.images.ogImage` — OG image
- `branding.personality` — tone, energy, target audience

### 1b. Brand voice and messaging

Scrape the page as markdown, then extract voice/messaging from `data.markdown`:

```bash
bento service proxy post --service-id firecrawl --path /v2/scrape --body-file - > .firecrawl/brand-voice.json <<'JSON'
{"url": "<WEBSITE_URL>", "formats": ["markdown"], "onlyMainContent": true}
JSON
```

Then summarize into:

- tagline
- brandVoice
- valueProposition
- keyMessagingThemes
- brandPersonalityTraits

### Run both in parallel:

Run the two scrapes above as background jobs (`&`) and `wait` for both, or
request both formats in one call:

```bash
bento service proxy post --service-id firecrawl --path /v2/scrape --body-file - > .firecrawl/brand.json <<'JSON'
{"url": "<WEBSITE_URL>", "formats": ["branding", "markdown"], "onlyMainContent": true}
JSON
```

## Step 2: Enrich Person

Two paths depending on input:

### Path A: LinkedIn URL provided

```bash
bento service proxy post --service-id crustdata --path /person/enrich \
  --headers '{"x-api-version":"2025-11-01"}' --body-file - > person.json <<'JSON'
{"professional_network_profile_urls":["<LINKEDIN_URL>"],"fields":["basic_profile","social_handles","experience","education","skills"]}
JSON
```

Returns an array of input matches. Check `match_status` and `matches`, then read the selected `matches[].person_data`: `basic_profile` for identity, title, summary and `profile_picture_permalink`; `experience.employment_details` for current/past roles; `education.schools` and `skills.professional_network_skills` for background. See [the enrichment reference](reference/crustdata-person.md).

### Path B: Email provided (no LinkedIn URL)

Identify the person from the email first, then run Path A on the profile URL it returns:

```bash
bento service proxy post --service-id crustdata --path /person/identify \
  --headers '{"x-api-version":"2025-11-01"}' --body-file - > identify.json <<'JSON'
{"emails":["<EMAIL>"]}
JSON
```

Read `matches[0].person_data.social_handles.professional_network_identifier.profile_url`. A `confidence_score` below 1 is a name-at-domain guess; confirm it with the user before writing content about that person. See [the identify reference](../go-to-market/reference/crustdata-contact-api.md#identify-a-person-from-an-email).

## Step 3: Generate Branded Content

With branding + person data in hand, generate a social media post.

### Posting Strategy (1 text + 1 image + 1 video)

Produce a 3-part bundle each time:

1. **Text post** — short, punchy, metric-led or contrarian hook with a clear “old way vs new way” contrast.
2. **Image** — square (1:1) stat-led graphic aligned to the text post.
3. **Video** — short demo or walkthrough that visually proves the claim from the text post (via the model gateway).

**Style cues (model after recent exemplars):**

- Start with a hard, specific claim or metric, then expand into a concise breakdown. Avoid fluffy intros. Keep sentences short and scannable.
- Use “old way vs new way” framing and compress into 6–10 lines.
- End with a crisp takeaway or light CTA (e.g., “Video below,” “Here’s the workflow,” “Full breakdown in the clip”).

### 3a. Write post text

Using the extracted brand voice, person's role/expertise, and company context, draft a social media post that:

- Matches the brand's tone (from `branding.personality.tone`)
- Speaks to the target audience (from `branding.personality.targetAudience`)
- Incorporates the person's expertise and current role
- Includes relevant hashtags
- Is appropriate length for the target platform (LinkedIn ~150-300 words, Twitter ~280 chars)
- Feels authentic to the person — not generic corporate speak

### 3b. Generate 1:1 branded image

Generate a 1:1 image with the **`bento local model chat`** CLI (GPT Image 2.6 Flare, the default) — no code or SDK needed. The image should incorporate:

- Brand colors (primary: `branding.colors.primary`, accent: `branding.colors.accent`)
- Brand personality/energy
- Content related to the post topic
- Professional, shareable aesthetic

```bash
# <MODEL>: gatewayModelId for role "image"
bento local model chat --model <MODEL> --size 1024x1024 \
  --out "<OUTPUT_DIR>/branded-post.png" \
  "<DETAILED_PROMPT_WITH_BRAND_COLORS_AND_THEME>"
```

GPT Image 2.6 Flare handles text-heavy branded images (stat cards, quote graphics, infographics) — put the exact headline in `"quotation marks"` in the prompt. The CLI has no `quality` flag, so ask for "crisp, high-detail typography" in the prompt for sharp rendering. Use Nano Banana 2 (role `image:google`, `bento local model chat --model <MODEL> --type image …`) only if the user explicitly requests it or isn't happy with GPT Image 2.6 Flare's output. See the [media-creation skill](../media-creation/SKILL.md) for the full CLI reference.

### Prompt engineering for branded images

Build the image prompt to include:

- The post's core message or theme as visual concept
- Brand colors by hex code: "color palette featuring #HEXCODE and #HEXCODE"
- Style keywords matching brand personality (e.g., "modern minimalist" for tech, "warm approachable" for consumer)
- "Professional social media graphic, square format, clean typography"
- Avoid putting the person's face in the image unless specifically requested

### 3c. Generate short video

Generate the video with the **`bento local model chat`** CLI. The default is the `video` role; escalate to `video:seedance` when it is not good enough. Video takes a few minutes — allow a generous timeout.

```bash
# <MODEL>: gatewayModelId for role "video"
bento local model chat --model <MODEL> --type video \
  --out "<OUTPUT_DIR>/branded-post.mp4" \
  "<DETAILED_PROMPT_MATCHING_TEXT_POST>"
```

**Alternative video models.** Look each role up in
`../media-creation/reference/models.json` and pass its `gatewayModelId` to `--model`:

| Role             | Best For                                   |
| ---------------- | ------------------------------------------ |
| `video:seedance` | Higher fidelity than the default           |
| `video:google`   | High-quality text-to-video                 |
| `video:kling`    | Realistic motion, multi-shot, audio, 1080p |
| `video:pro`      | Cinematic, strong instruction following    |

When you tell the user which model you used, take its `name` from
`models.json` — do not name the provider from memory.

**Video prompt guidance:**

- Mirror the text hook in the first 2–3 seconds.
- Show a 2–3 step process (e.g., input → AI/automation → output).
- Keep typography minimal; prioritize readable on mobile.

## Output

Deliver to the user:

1. **Post text** — ready to copy/paste
2. **Branded image** — saved to a local file and shared with the user
3. **Branded video** — saved to a local file and shared with the user
4. **Brand summary** — brief note on colors/voice extracted (for reference)

## Reference

- [Firecrawl branding format docs](reference/firecrawl-branding.md) — detailed response schema
- [Crustdata person API](reference/crustdata-person.md) — enrichment endpoint details
- [Crustdata identify by email](../go-to-market/reference/crustdata-contact-api.md#identify-a-person-from-an-email) — email to profile URL
- [Prompt engineering & platform specs](../media-creation/reference/prompt-engineering.md) — prompt structure, brand color integration, text-in-images tips, and platform dimensions for all image and video formats
