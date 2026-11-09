# Text to Image — CLI Reference

Generate or edit images from text prompts with the **`bento local model chat`** CLI. Default model is GPT Image 2.6 Flare — use it for everything unless the user requests otherwise or you hit a capability exception. No code or SDK install is needed: the CLI authenticates through the installed Bento login and prints the path of each file it writes.

```bash
bento local model chat --help
```

Throughout this reference, `<MODEL>` is the **gateway model id** for the role
named above each command. Resolve it from `models.json` in this directory — the
CLI takes gateway ids, not role ids:

```bash
jq -r '.models[] | select(.id == "image") | .gatewayModelId' models.json
```

## Relevant Flags

| Flag             | Purpose                                                                          |
| ---------------- | -------------------------------------------------------------------------------- |
| `--model`    | Exact gateway model ID (optional with `--type image`)                  |
| `--type image`   | Force image output (needed for multimodal LLMs like NB2; optional for GPT Image) |
| `--image <path>` | One input image for editing; repeated flags replace the source        |
| `--out`      | Output path (auto-named when omitted)                                            |
| `--size <WxH>`   | Image size, e.g. `1024x1024`                                                     |
| `--background`   | `transparent`, `opaque`, or `auto` — OpenAI image models only (`bento` 0.3.20+)   |
| `--format`       | `png`, `jpeg`, `webp`, or `gif` — OpenAI image models only                         |
| `--frames`, `--frame-ms` | GIF frame count and per-frame duration; need `--format gif`              |
| `--n <count>`    | Number of outputs                                                                |
| `--seed <int>`   | Generation seed (where the model supports it)                                    |

> **OpenAI image options only.** Beyond `--background`, `--format`, `--frames` and `--frame-ms`, the CLI exposes no per-model `providerOptions` (`quality`, etc.). Drive those qualities through the prompt text. If you genuinely need another `providerOptions` field, send a native request through the [ai-gateway skill](../../ai-gateway/SKILL.md).

## GPT Image 2.6 Flare (Default — Use for Everything)

OpenAI's fast everyday image model: a 1024px image takes about 10 seconds. Handles general-purpose imagery, text-heavy graphics (infographics, posters, headlines), product shots, branded content, edits of an existing image, and short animated GIFs.

```bash
# <MODEL>: gatewayModelId for role "image"
bento local model chat --model <MODEL> --size 1024x1024 --out output.png "<PROMPT>"
```

### GPT Image 2.6 Flare Sizes & Notes

- Supported `--size`: the fixed `1024x1024`, `1536x1024`, `1024x1536`, `auto`, or any custom `WIDTHxHEIGHT` with both edges multiples of 16 and an aspect ratio between 1:3 and 3:1 — e.g. `1024x1280` (4:5), `1536x864` (16:9), `1152x2048` (9:16). Custom sizes come back pixel-exact through the gateway.
- Does NOT support aspect-ratio flags — use `--size`.
- Does NOT support `--seed`.
- Transparent backgrounds: pass `--background transparent` (below). Asking for transparency in the prompt alone returns an opaque PNG.

### High Quality

The CLI has no `quality` flag. For hero images, product photography, or detail-critical visuals, request high quality in the prompt itself:

```bash
# <MODEL>: gatewayModelId for role "image"
bento local model chat --model <MODEL> --size 1024x1024 --out headphones.png \
  "High-detail studio product photograph of wireless headphones, soft shadows, crisp focus, premium catalog quality"
```

### Text-in-Image Tips

GPT Image 2.6 Flare renders text accurately — you don't need another model for headlines, infographics, or typography-heavy designs. For best results:

- Put the exact text in the prompt, ideally in `"quotation marks"`.
- Keep headlines short (5–8 words).
- Specify a font style explicitly: "bold sans-serif", "modern display font", "clean professional typography".
- Specify high contrast between text and background.

### Transparent Backgrounds

Pass `--background transparent` — it sets OpenAI's `background` option and returns a true RGBA PNG (verified: the alpha channel is populated). Prompt wording alone ("transparent background") does not; the model paints a backdrop instead. Needs `bento` 0.3.20 or newer; older CLIs reject the flag.

```bash
# <MODEL>: gatewayModelId for role "image"
bento local model chat --model <MODEL> --background transparent --size 1024x1024 --out logo.png \
  "A single red maple leaf, isolated subject, no scenery"
```

### Animated GIFs

GPT Image 2.6 Flare returns a short animated GIF from one prompt: every frame is drawn as one coherent sequence. Pass `--format gif`; `--frames` (2 or more) and `--frame-ms` set the length and speed. Without them OpenAI draws 9 frames at 200 ms, at 512x512.

```bash
# <MODEL>: gatewayModelId for role "image"
bento local model chat --model <MODEL> --format gif --frames 8 --frame-ms 150 --size 512x512 \
  --out plane.gif "A paper plane looping once across a blue sky, flat illustration style"
```

- **Frames share one sheet.** OpenAI draws every frame on a single sheet whose longest edge must be 3840px or less. Eight frames fit at `512x512`; eight at `1024x1024` are rejected with "No supported sheet fits N GIF frames". Lower `--size` or `--frames`.
- **Describe the motion, not the frames.** Name the action and how it loops ("looping once", "bobbing gently") and set the pace with `--frame-ms`.
- **Generations only.** OpenAI documents GIF output for new images, not for edits of a source image.
- **GIF support.** Use the current `bento local model chat --format gif` command shown above. The CLI owns the supported generation options.

## Single-Image Editing

Pass the source with `--image` and say what to change. GPT Image 2.6 Flare changes what the prompt names and keeps the rest of the image, including text and layout. Name what must stay ("keep everything else identical") when the edit is small.

```bash
# <MODEL>: gatewayModelId for role "image"
bento local model chat --model <MODEL> --type image \
  --image input.png --out output.png "Change the background to a beach sunset; keep the subject identical"
```

For a different look, Nano Banana 2 (`image:google`) edits the same way. It is a multimodal LLM that the catalog treats as a text model, so `--type image` is required to get an image back.

## Multi-Image Composition (Nano Banana 2)

The current CLI accepts one source image. For multiple image inputs, send a
native request with several image parts to a language model that accepts them,
following the [ai-gateway skill](../../ai-gateway/SKILL.md). Repeating `--image`
replaces the previous source rather than composing the inputs.

## Nano Banana 2 (Direct Text-to-Image — Only When User Requests)

NB2 (`image:google`) is also available for plain text-to-image — use it only when the user explicitly asks for it, or when GPT Image 2.6 Flare's output is unsatisfactory and you want to offer a different look. It does not accept a `--size` flag; control aspect ratio and resolution through the prompt text.

```bash
# <MODEL>: gatewayModelId for role "image:google"
bento local model chat --model <MODEL> --type image --out output.png \
  "<PROMPT>. Vertical 9:16 format, 1080x1920."
```

Supported aspect ratios (14 total): `1:1`, `2:3`, `3:2`, `3:4`, `4:3`, `4:5`, `5:4`, `9:16`, `16:9`, `21:9`, `1:4`, `4:1`, `1:8`, `8:1`. For multiple variations, ask for them in the prompt (e.g. "Generate 4 variations …") or pass `--n`.

## Delivering Results

The CLI prints each output path. Upload via the Bento Files API and send as a message part, or provide the file path to the user.

## Model Discovery

Discovery includes upstream media outside Bento’s local catalog. Omitting the
model with `--type image` uses the existing image default. Exact IDs override
that choice; a language model emitting images still needs the explicit output
type. Native image generation uses the $2 hold and actual-cost settlement.


```bash
bento model list
```

## Error Handling

| Error / Symptom                        | Cause                             | Fix                                                                     |
| -------------------------------------- | --------------------------------- | ----------------------------------------------------------------------- |
| `Unknown model` / not-found            | Invalid model ID                  | Check the model ID against the model-discovery list                     |
| Upstream unsupported-model error      | Wrong model ID or operation       | Inspect discovery metadata and use an exact gateway ID; roles resolve through `models.json` |
| `401 Unauthorized`                     | Bento login is missing or expired | Run `bento whoami` and repair the login before retrying                     |
| Got text instead of an image (no file) | NB2 inferred as a text model      | Add `--type image` to force image output                                |
| Transparent background ignored         | Transparency asked for in the prompt only | Pass `--background transparent` (`bento` 0.3.20+)                  |
| Empty or low-quality image             | Prompt too vague                  | Be more specific about subject, style, lighting, and composition        |
