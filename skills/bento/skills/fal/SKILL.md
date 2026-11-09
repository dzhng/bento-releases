---
name: fal
description: Use Bento's fal service proxy for 3D generation, perception, image cleanup, avatars and lip-sync, or sound from video. Use when a task needs one of those five media classes, including uploading source media, polling an asynchronous job, or downloading a fal result.
---

# fal

Use Bento's `service proxy` commands for fal's five media classes: 3D,
perception, media cleanup, avatars/lip-sync, and sound from video. Image and
video generation stay with the model gateway; use the
[media-creation reference](../media-creation/SKILL.md) for those roles. The
admitted endpoint inventory is in
[reference/endpoints.md](reference/endpoints.md).

## Defaults and routes

- **3D:** `tripo3d/h3.1/image-to-3d`; use `meshy/v7.1/image-to-3d` for fidelity,
  rigging, or animation.
- **Perception:** `fal-ai/moondream2/object-detection`; use
  `fal-ai/sa2va/4b/image` for segmentation.
- **Cleanup:** `fal-ai/bria/background/remove`; use `fal-ai/bria/eraser` for
  erasing.
- **Avatar/lip-sync:** `veed/lipsync/v2`; use
  `fal-ai/longcat-single-avatar/audio-to-video` as fallback.
- **Sound from video:** `fal-ai/kling-video/video-to-audio`; use
  `mirelo-ai/sfx2.0/video-to-audio` as fallback.

There is no separate spend-confirmation step. Submit the model request and
handle its result through the proxy. Queue responses may include vendor URLs;
never follow them directly. Build the status, result, and cancel proxy paths
from the endpoint's first two path segments and the request id. For example,
`tripo3d/h3.1/image-to-3d` polls under `tripo3d/h3.1/requests/<id>`.

## Submit, poll, and fetch

Write the model body to a JSON file, then submit through Bento. The CLI owns
login, workspace selection, authentication, response headers, and errors:

```bash
cat > request.json <<'JSON'
{"image_url":"https://example.com/object.png"}
JSON
bento service proxy post --service-id fal \
  --path /tripo3d/h3.1/image-to-3d --body-file request.json --out submit.json
REQUEST_ID=$(jq -r '.request_id' submit.json)
bento service proxy get --service-id fal \
  --path "/tripo3d/h3.1/requests/$REQUEST_ID/status" --out status.json
bento service proxy get --service-id fal \
  --path "/tripo3d/h3.1/requests/$REQUEST_ID" --out result.json
```

Poll until the status is terminal, then fetch the result once. Cancel a job you
no longer need at the same request path plus `/cancel`:

```bash
bento service proxy put --service-id fal \
  --path "/tripo3d/h3.1/requests/$REQUEST_ID/cancel"
```

Output files are objects with `url` and `file_name` (Trellis's GLB is under
`model_mesh`, for example) on fal's public CDN. Download every output the task
needs into the working folder under its own name. To show a 3D result, deliver
the model file itself (`.glb` or `.gltf`), not a rendered still. A generated
model is often large and dense (Tripo's are about 40 MB with over 400,000
triangles): keep the original and also make a simplified, compressed copy,
which previews and loads fast on a web page (a Tripo cup went to 40,000
triangles and 1.8 MB with no visible change):

```bash
bunx @gltf-transform/cli optimize model.glb model-web.glb \
  --compress meshopt --simplify-error 0.0003
```

Download each output rather than leaving a remote URL as the deliverable:

```bash
jq -r '.. | objects | select(has("url") and has("file_name")) | "\(.url) \(.file_name)"' result.json |
  while read -r output_url file_name; do curl -fL "$output_url" -o "$file_name"; done
```

A preview drawn without a GPU takes models up to about 25 MB and fails on a
mesh too dense to draw in time; embed the simplified copy there.

## Uploads

For a large input, initiate `fal-cdn-v3` through the proxy and save its JSON:

```bash
cat > upload-request.json <<'JSON'
{"file_name":"object.png","content_type":"image/png"}
JSON
bento service proxy post --service-id fal \
  --path /storage/upload/initiate \
  --query '{"storage_type":"fal-cdn-v3"}' \
  --body-file upload-request.json --out upload.json
UPLOAD_URL=$(jq -r '.upload_url' upload.json)
curl -fL -X PUT "$UPLOAD_URL" \
  -H "Content-Type: image/png" --upload-file ./object.png
```

Use the signed `upload_url` directly: do not add Bento or fal authorization to
that PUT. Pass the returned `file_url` as the input URL in the model submit body
(for example `{"image_url": "<file_url>"}`). Use the multipart initiate route
only when the input requires it. Download fal CDN outputs directly; those signed
vendor URLs also do not receive a Bento header.

## Billing and capacity

The submit response's `x-duet-charge-usd` header is `0`; read it from the
`headers` that `--out` prints. The real charge is copied from fal's billing
record, including zero-cost failures, within about 10 minutes.

A workspace can have 10 live jobs, and a finished job frees its slot when its
charge lands. At the limit, a submit fails with `409`
`{"code":"pool_resource_limit"}` and a `Retry-After` header in seconds: cancel a
job you no longer need, or wait that long and submit once more. Do not resubmit
in a loop or invent a spend confirmation flow.
