---
name: bento
description: Install and operate the Bento CLI on the user's computer for workspace files, sessions, agents, recordings, models and media, paid service APIs, integrations, sandboxes, publishing, Mac sync, Google Drive backups, and login.
---

# Bento

Use the released `bento` command for Bento work on the user's computer. It
carries the login, the selected workspace, authentication, retries and response
links; do not reconstruct those requests by hand or copy credentials into them.
Run a recipe below or in the references as written. When none covers the task,
read `bento <command> --help`: it owns the current flags, defaults, output, and
exit codes.

Follow [setup](references/setup.md) when installation, login, or workspace
selection is needed. When the CLI or MCP is already signed in, setup uses that
login for the other channel.

- [CLI recipes](references/cli.md): agents, sessions, Drive search, request
  recovery and Mac sync.
- [Services](references/services.md): discovering and calling any paid vendor
  API through `bento service proxy`, without vendor keys.
- [Backups](references/backups.md): Google Drive backup.
- [Recordings](references/recordings.md): watching and exporting recordings.

To start a separate, titled session for an agent, run this, then reply with
the returned `url`. It returns on acceptance; add `--wait` for the turn result.

```bash
bento session create --cwd agents/<slug> --title "<short title>" --prompt "<the work>"
```

Commands use the workspace selected at setup; `--workspace <slug>` selects
another for one command. Inspect the returned result and URL, and reuse
`--client-request-id` when retrying an ambiguous write. Verify delivered files
or fresh remote state before reporting completion.

The CLI is the shell interface for Bento's own API and for third-party APIs
through `bento service proxy`. Code you are writing — an app server, or a
script that orchestrates many calls — uses HTTP as the
[app API skill](skills/app-api/SKILL.md) describes.

## Bento capabilities

Read the matching reference when a task enters one of these capabilities. Each
one works through the same login.

- [ai-gateway](skills/ai-gateway/SKILL.md): Call AI models through Bento's model gateway with the logged-in bento CLI — discover models, generate text, send native OpenAI-, Anthropic- or AI SDK-shaped requests, embeddings and long video jobs — and understand how those calls are billed. Use for a direct model call without starting an agent session.
- [app-api](skills/app-api/SKILL.md): Call Bento, its model gateway and paid services over HTTP from code you are writing — an app server, a script, an SDK client. Covers which key the code uses, gateway SDK setup, and turning any `bento service proxy` example into a request. For a one-off task, use the `bento` CLI instead.
- [branded-content](skills/branded-content/SKILL.md): Generate branded social media content for a person. Extracts brand identity from a website (colors, fonts, logo, voice) via Firecrawl, enriches a person's profile via Crustdata (LinkedIn URL or email), then generates a branded social media post (text + 1:1 image). Use when asked to create branded content, social media posts with company branding, or personalized marketing visuals.
- [build-apps](skills/build-apps/SKILL.md): Create, publish and manage Bento apps from this computer — publish a static site, hand a full app build to a workspace agent, change visibility, domains and runtime, restart, and host externally with exported credentials. Use when making, deploying or publishing an app, site or service, or changing an existing app. For code inside the app, see app-api.
- [composio-credentials](skills/composio-credentials/SKILL.md): Call a workspace's connected integrations (Gmail, Slack, CRMs and other OAuth accounts) through Bento with the bento CLI — find or connect an account, then execute one of its provider tools. Use when a task needs data from, or an action in, a connected third-party account, including from app server code.
- [elevenlabs](skills/elevenlabs/SKILL.md): Generate and transcribe audio through ElevenLabs' HTTP API — text-to-speech voiceover, multi-speaker dialogue, sound effects, background music, and transcription. Use when the user asks for a voiceover, narration, an AI voice, podcast or audiobook audio, a sound effect, background music, or a transcript of an audio or video file.
- [fal](skills/fal/SKILL.md): Use Bento's fal service proxy for 3D generation, perception, image cleanup, avatars and lip-sync, or sound from video. Use when a task needs one of those five media classes, including uploading source media, polling an asynchronous job, or downloading a fal result.
- [firecrawl](skills/firecrawl/SKILL.md): Unattended web scraping, search, crawling, bulk extraction, and a fallback when a site blocks your browser, via Firecrawl's HTTP API. Returns clean LLM-optimized markdown. Use for collecting data without a human-visible browser; use a human-visible browser whenever a person should see or interact with the page, including login.
- [go-to-market](skills/go-to-market/SKILL.md): Research accounts, enrich leads, research a person into a professional dossier with work history and verified contact details, pick the contacts worth reaching at an account, look up firmographics, query Crustdata APIs, profile/research/analyze competitors, write sales emails, perform SEO keyword research, Amazon/Google Shopping product research, App Store optimization, AI search visibility analysis, and website technology lookups using DataForSEO.
- [manage-agents](skills/manage-agents/SKILL.md): Create, configure and inspect agents in a Bento workspace from this computer — register an agent folder, write its instructions and config into the Drive, give it an icon, and change or remove it. Use when setting up an agent persona or repeatable agent process, or changing an existing one.
- [media-creation](skills/media-creation/SKILL.md): Generate new images, animated GIFs and videos from a description through `bento local model chat`. Use when the user asks to make, draw, design, animate or generate a picture, illustration, logo, animated GIF or video. Read this reference's models file to map a stable Bento role to the gateway model id the CLI takes.
- [memory](skills/memory/SKILL.md): Recall and add to the Bento workspace's shared memory — what its agents have learned about the user, their people, their decisions and their work — for the whole workspace or one agent, and train it on sources. Use when a task touches past work, people or decisions, or when asked to remember, save, look up, learn or train on something.
- [publish](skills/publish/SKILL.md): Publish a file or folder in Bento as a public, read-only source viewer. Use when asked to publish, share publicly, or expose a document, file, or folder for people to read — as opposed to building an app or site that runs or renders.
- [sandbox](skills/sandbox/SKILL.md): Operate temporary funded remote Linux sandboxes through Bento. These are separately funded machines. Use for sandbox execution, reading, writing and editing files or running commands in one or more sandboxes, copying files or repositories to and from a sandbox, uploads/downloads, SSH/SCP, hosted ports, snapshots, resume/fork or finite remote compute. The current provider may change; discover it before use.
- [socialapi](skills/socialapi/SKILL.md): Read X/Twitter data through the SocialData HTTP API — search tweets, pull user profiles and timelines, read threads and replies, and list followers, likers, and retweeters. Use when the user asks what is being said or trending on X/Twitter, wants to monitor an account or competitor, research an audience or a handle, find hooks and posts that performed well, or pull the replies to a tweet.
