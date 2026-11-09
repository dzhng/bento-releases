# Watch and export recordings

A recording is evidence of what the person said and showed. Read its prompt,
transcript, frames and timed marks together before acting on the request. The
recording commands run against the workspace service, including when invoked
from the person's Mac. Start with `bento recording operation create --help` for
the installed transport's flags. Operation parameters follow the recording
protocol catalog; use returned identities rather than guessing paths or streams.

## Watching

Read `recording.prompt` with the recording ID from the handoff. It gives the
capture context and whether marks exist; `recording.get` supplies the source admissions.
Read `acquisition.get` with an admitted `acquisitionId`, then select the relevant
`assetId` and `streamId` from its bindings for source reads. Keep that acquisition
identity with the selection. Times are microseconds in the source clock.

```bash
bento recording operation create --operation recording.prompt \
  --params '{"recordingId":"<recording-id>"}' --json
bento recording operation create --operation recording.get \
  --params '{"recordingId":"<recording-id>"}' --json
bento recording operation create --operation acquisition.get \
  --params '{"acquisitionId":"<acquisition-id>"}' --json
```

`transcript.get` reads retained words; it does not start transcription. Continue
with `nextCursor` until complete, even if a page has no words. Keep the returned
generation and selection while paging. A recording handoff waits for transcript
readiness; if the read is still pending, observe its reported job or readiness
rather than inventing missing speech.

```bash
bento recording operation create --operation transcript.get \
  --params '{"assetId":"<asset-id>","streamId":"<audio-stream-id>","acquisitionId":"<acquisition-id>"}' --json
```

Use `timeline.events` on the admitted captured-video selection for timed marks,
and `cursor.render` for pictures with the person's captured strokes, pins and
cursor trail. Inspect frames around marks and the moments the transcript refers
to; words alone cannot show a visual defect. `frame.get` supplies clean pictures
without those overlays. `--wait` observes admitted work, and `--output` saves the
delivered frame locally for inspection; it is not an export destination.

```bash
bento recording operation create --operation timeline.events \
  --params '{"assetId":"<asset-id>","streamId":"<video-stream-id>","acquisitionId":"<acquisition-id>"}' --json
bento recording operation create --operation cursor.render \
  --params '{"assetId":"<asset-id>","streamId":"<video-stream-id>","acquisitionId":"<acquisition-id>","atUs":[1000000],"trailUs":500000}' \
  --wait --output review-frames --json
```

`frame.get` takes one source time, a number, where `cursor.render` takes a list:

```bash
bento recording operation create --operation frame.get \
  --params '{"assetId":"<asset-id>","streamId":"<video-stream-id>","acquisitionId":"<acquisition-id>","atUs":1000000}' \
  --wait --output frame.png --json
```

When the request concerns an edited project, use its `projectId` and pin the
returned `revisionId`. Project transcript and frame times follow the edited
project clock, so source timestamps cannot stand in for cut-project timing.

## Replacing speech

Use `voice.generate` when the person asks to regenerate speech in the source
speaker's voice. Retain a complete reference with `audio.extract`, using
`rendition: {"sampleRate":24000,"channels":1}`. Supply the exact reference
transcript and the person's desired wording; do not infer either. Optionally
copy one full returned reference origin to preserve that selection.

```bash
bento recording operation create --operation voice.generate \
  --params '{"modelId":"eleven_multilingual_v2","reference":{"assetId":"<reference-asset-id>","streamId":"<reference-stream-id>"},"referenceText":"<exact reference transcript>","text":"<requested replacement>"}' --wait --json
```

The service uses the workspace's catalog access and keeps the clone for reuse.
A later phrase reuses the same source clone; expiry or a missing vendor voice
recreates it transparently. The seed is best-effort, not exact repeatability.
`VOICE_QUOTA_EXCEEDED` means the shared speech account needs more capacity or
credits; preserve the failed job and use `job.retry` explicitly after that is
resolved. Do not loop or create a new reference to evade the refusal. A vendor
verification requirement is reported as a missing prerequisite.

Read the returned published asset and its provenance, then audition it in
context. Generation does not change a project. Use ordinary `edit.apply` with
the expected revision to place the generated asset and choose its fit. Keep
originals and do not automatically add noise reduction, ambience or retiming.

## Exporting

Exports render and publish through Bento. The available deliveries are
H.264 MP4 video, AAC M4A audio, WAV audio, and SRT or VTT caption sidecars.
Use `export.create` with a stable `requestId`, the intended project/revision,
and an explicit existing absolute `directory` plus filename `leaf`. Select audio
containers with `settings.container`; caption exports require the pinned revision
and explicit text `placementIds`. A transcript is evidence for authoring captions,
not an implicit selection of displayed caption placements.

Choose the Drive path from the person's request: for example, the project folder
they named. Any workspace Drive path is eligible except the root `recordings/`
tree and private `.bento` folders. There is no fixed export home. Create
the requested folder when needed before exporting. A CLI `--output` path does not choose where Bento publishes the export.

```bash
bento recording operation create --operation export.create \
  --params '{"requestId":"<stable-request-id>","kind":"video","projectId":"<project-id>","revisionId":"<revision-id>","directory":"<absolute-workspace-Drive-path>","leaf":"Review.mp4"}' --wait --json
bento recording operation create --operation export.status \
  --params '{"exportId":"<returned-export-id>"}' --json
```

Keep the request identity on an ambiguous retry: it retains the original revision
and destination. Read the returned export status and publication receipt before
claiming delivery. Tell the person the workspace Drive path where the file landed,
using the returned output rather than a presumed default.
