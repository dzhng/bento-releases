---
name: ai-gateway
description: Call AI models through Bento's model gateway with the logged-in bento CLI — discover models, generate text, send native OpenAI-, Anthropic- or AI SDK-shaped requests, embeddings and long video jobs — and understand how those calls are billed. Use for a direct model call without starting an agent session.
---

# AI Gateway

Bento's model gateway serves every model through the `bento` CLI. The CLI owns
the login, the workspace (the selected default; `--workspace <slug>` overrides
it) and the gateway credential; never copy a key into a request or a file.
Model discovery lists the full upstream catalog, including uncatalogued
image/video models and unfamiliar model types. The gateway checks workspace
spend before generation; upstream validates the chosen model and operation.

Image and video generation from a description is the
[media-creation skill](../media-creation/SKILL.md). Use the [fal skill](../fal/SKILL.md)
for 3D, perception, media cleanup, avatars/lip-sync, and sound from video.

## Discover models

```bash
bento model list --kind language --limit 50 --json
bento model get --model-id "$MODEL_ID" --json
```

The OpenAI-compatible model list preserves upstream entries and metadata.
Follow `nextCursor` with `--cursor` until it is null; `--kind` filters the
upstream type before paging. A listed type (speech, transcription and so on)
does not add a CLI operation for it. To find language models that produce
images, read the full list and inspect output-modality metadata rather than
filtering only for native image models.

Choose a model from the current response; do not embed a provider/model slug in
authored code or prose. [The models file](../media-creation/reference/models.json)
maps stable Bento roles to the gateway ids those commands take, when a
role-based choice is more appropriate. Preserve a requested id; never silently
replace a rejected model with a default.

## Generate text

`bento local model chat` is the direct call. Read its `--help` first; installed
help owns the flags.

```bash
bento local model chat "Explain this paragraph briefly"
bento local model chat --model "$MODEL_ID" --system "Answer in one line" "Explain this paragraph"
```

Omit `--model` to use the workspace's effective model choice. If that choice is
a compound router, direct generation uses its general route; it does not call a
classifier or advisor. An explicit compound choice follows that same route. An
explicit gateway model id is sent unchanged.

## Send a native request

Each protocol has its own command, and `--body-file` takes the provider's own
body (`-` reads stdin). Output is the native JSON, or files under `--out` for
media.

| Command                                 | Protocol                                             |
| --------------------------------------- | ---------------------------------------------------- |
| `bento model chat`                      | OpenAI chat completions; `--protocol` selects AI SDK |
| `bento model responses`                 | OpenAI responses                                     |
| `bento model messages`                  | Anthropic messages                                   |
| `bento model embedding`                 | Embeddings                                           |
| `bento model image` / `bento model video` | Native image and video models                     |

```bash
bento model chat --body-file - --headers '{"x-duet-tier":"services"}' <<JSON
{"model":"$MODEL_ID","messages":[{"role":"user","content":"Hello!"}]}
JSON

bento model messages --body-file - <<JSON
{"model":"$MODEL_ID","max_tokens":1024,"messages":[{"role":"user","content":"Hello!"}]}
JSON
```

The selected model must support the protocol being used. Re-query the model
list when a request is rejected; a billing or authentication error is not
evidence that only smaller models are available.

A long video job starts and is polled separately. Keep the opaque `operation`
the start returns unchanged and send it back to status until `status` is
`completed`, `error` or `cancelled`; `pending` is still running. A completed
status writes the videos under `--out`:

```bash
bento model video start --body-file video.json > start.json
jq '{operation}' start.json > status.json
bento model video status --body-file status.json --out clip.mp4
```

## Billing

Direct chat and embedding calls bill at provider cost. `x-duet-tier: services`
selects that explicitly; omitting the header also defaults to provider cost.
Invalid tier values are rejected. Compound-backed direct calls bill at upstream
cost too; selecting a compound does not claim an agent tier tariff. Model
availability is separate from the workspace's credit balance and spending
eligibility.

Native image/video calls take an upfront $2 hold and settle at actual upstream
cost. The hold is an estimate, not a final-cost ceiling; a cheap model can
still require the full hold. Image-producing language models use the language
operation; known product media hints keep reservation behavior, while
uncatalogued language calls bill after the response. Missing generation ids or
unavailable provider cost can prevent reconciliation; report that state rather
than treating a file as proof of a settled charge.

## Verify and recover

Consume a text command to its exit result: a failed stream is an error, not an
empty completion. For media, inspect each printed file's existence, type and
size. A completed artifact and settled billing are separate facts; use
`bento billing usage get` when accounting is part of the task.

For a bounded paid run, pass `--max-retries 0` to `bento local model chat`; it
disables SDK retries for text, native media and language-image generation. If
installed help does not advertise it, upgrade the CLI and recheck; if the
current release still lacks it, report the missing control before generating.
Without the flag the SDK's retry defaults apply. After an ambiguous failure,
inspect output and usage before retrying; an error or a disconnected stream
does not prove the upstream generation never ran.
