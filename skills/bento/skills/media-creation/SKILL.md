---
name: media-creation
description: Generate new images, animated GIFs and videos from a description through `bento local model chat`. Use when the user asks to make, draw, design, animate or generate a picture, illustration, logo, animated GIF or video. Read this reference's models file to map a stable Bento role to the gateway model id the CLI takes.
---

# Media Creation

Generate images and videos with the **`bento local model chat`** CLI. It uses the installed Bento CLI; you do **not** need to write any code or install the `ai` SDK. One command per generation: it infers the request type from the gateway catalog, writes the output file, and prints each path.

```bash
bento local model chat --help
```

`<MODEL>` is an exact **gateway model id**. Omit it with `--type image` or
`--type video` to use that output kind’s default role. Choose a specific role’s
ID from `reference/models.json`, or discover another upstream model through
`bento model list`; catalog membership is not required.

## Important Notes

- **Use the `bento local model chat` CLI for image and video generation.** It authenticates through the installed Bento login, writes image/video files, and prints each path.
- **Use [fal](../fal/SKILL.md) for 3D, perception, media cleanup, avatars/lip-sync, and sound from video.** Image and video generation stay on the model gateway.
- **Use a default or an explicit gateway ID.** `reference/models.json` is the generated authority for role ids, gateway mappings, and media kind. Pick the role you want, then pass that entry's `gatewayModelId` to `--model`. Explicit media role strings are not CLI model IDs; omission with an explicit output type resolves the default internally. The stable defaults are the `image` and `video` roles:

  ```bash
  # look the role up once, then reuse the value
  jq -r '.models[] | select(.id == "image") | .gatewayModelId' reference/models.json
  ```

- **Tell the user which role or raw model you used.** If alternatives matter, describe their capability (`image:google`, `video:seedance`, `video:pro`, and so on) and use the current display name from `reference/models.json`; do not guess the underlying provider.
- **Capability exceptions — only then pick another model:**
  - **Transparent backgrounds →** stay on the `image` role and pass `--background transparent` (`bento` 0.3.20+). Prompt wording alone returns an opaque PNG; the flag returns a true RGBA PNG.
  - **Single-image editing (modify an existing image with a text prompt) →** stay on the `image` role and pass `--type image --image <src>`. GPT Image 2.6 Flare edits in place: it changes what the prompt names and keeps the rest of the image. Offer Nano Banana 2 (`image:google`) only for a different look.
  - **Animated GIFs →** stay on the `image` role and pass `--format gif`, with `--frames` and `--frame-ms` for length and speed. More frames need a smaller `--size`; see [reference/text-to-image.md](reference/text-to-image.md#animated-gifs).
  - **Multi-image composition (combine 2+ source images) →** inspect installed help for input support. The current CLI accepts one source image; send a native request with several image parts through the [ai-gateway skill](../ai-gateway/SKILL.md) rather than repeat a flag that replaces the previous source.
- **CLI limitation — few `providerOptions`.** The CLI exposes only OpenAI's image options (`--background`, `--format`, `--frames`, `--frame-ms`) (no `quality: 'high'`, no `negativePrompt`). Drive those qualities through the prompt text instead (e.g. "high-detail studio product photography", "avoid watermarks and text overlays").
- **To discover roles**, read `reference/models.json`. For another upstream generator, inspect the full gateway model metadata; a `language` model producing images needs `--type image`. See [reference/text-to-image.md](reference/text-to-image.md#model-discovery).
- **Bound paid retries explicitly.** Use `--max-retries 0` for a one-attempt run when advertised by installed help. Native media requires a $2 hold and settles at actual upstream cost; the hold is not a cost ceiling. Inspect outputs and usage before repeating an ambiguous failure.
- **User memory overrides everything.** If the user has expressed a preference for a specific image model in memory, defer to that over this default.
- **Clarify the target platform when it affects output quality.** Different platforms require different aspect ratios, safe zones, and composition strategies. When the intended platform is ambiguous and would change how you generate the content, ask the user which platform(s) they're targeting before generating. Use your discretion — if the context makes the platform obvious (e.g., "make me a TikTok", "LinkedIn post image"), just proceed. If the request is generic (e.g., "make a promo video", "create a social media image"), ask. When in doubt and the user hasn't specified, default to square (1:1) for images and vertical (9:16) for video — these are the safest cross-platform choices.

## Use-Case Guides

| Guide            | Content Types                                                 | Reference                                                        |
| ---------------- | ------------------------------------------------------------- | ---------------------------------------------------------------- |
| Social Images    | Square, portrait, story images for Instagram/LinkedIn/Twitter | [sub-skills/social-image.md](sub-skills/social-image.md)         |
| Marketing Images | Landscape, infographic, product photos                        | [sub-skills/marketing-image.md](sub-skills/marketing-image.md)   |
| Short-Form Video | TikTok, Reels, YouTube Shorts                                 | [sub-skills/short-form-video.md](sub-skills/short-form-video.md) |
| Marketing Video  | Promo/ads, LinkedIn/Twitter feed video                        | [sub-skills/marketing-video.md](sub-skills/marketing-video.md)   |
| Image Animation  | Animate stills, product promo from photos                     | [sub-skills/image-animation.md](sub-skills/image-animation.md)   |

## CLI Reference

| Reference                                                          | What It Covers                                                                                 |
| ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| [reference/text-to-image.md](reference/text-to-image.md)           | `bento local model chat` flags for GPT Image 2.6 Flare, transparency, editing, animated GIFs, multi-image, discovery, errors |
| [reference/text-to-video.md](reference/text-to-video.md)           | `bento local model chat` text-to-video commands, role selection, errors                                    |
| [reference/image-to-video.md](reference/image-to-video.md)         | `bento local model chat` image-to-video commands, role selection, errors                                   |
| [reference/prompt-engineering.md](reference/prompt-engineering.md) | Prompt structure, camera language, image prompt tips, brand integration, platform specs        |
