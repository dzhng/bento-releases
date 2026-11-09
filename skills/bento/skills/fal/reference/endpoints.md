# fal endpoint reference

This is the hand-authored endpoint inventory for the fal skill. The service
catalog test checks the IDs below against
`packages/service-catalog/services/fal/endpoints.ts`; update both together when
the admitted inventory changes.

| Endpoint | Class | Role |
| --- | --- | --- |
| `tripo3d/h3.1/image-to-3d` | 3d | default |
| `meshy/v7.1/image-to-3d` | 3d | fallback |
| `fal-ai/meshy/rigging` | 3d | extra |
| `fal-ai/trellis` | 3d | extra |
| `meshy/n1/retexture` | 3d | extra |
| `tripo3d/tripo/remesh` | 3d | extra |
| `fal-ai/moondream2/object-detection` | perception | default |
| `fal-ai/sa2va/4b/image` | perception | fallback |
| `fal-ai/bria/background/remove` | cleanup | default |
| `fal-ai/bria/eraser` | cleanup | fallback |
| `veed/lipsync/v2` | avatar | default |
| `fal-ai/longcat-single-avatar/audio-to-video` | avatar | fallback |
| `mirelo-ai/sfx2.0/video-to-audio` | sound-from-video | fallback |
| `fal-ai/kling-video/video-to-audio` | sound-from-video | default |
