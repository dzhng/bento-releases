---
name: publish
description: Publish a file or folder in Bento as a public, read-only source viewer. Use when asked to publish, share publicly, or expose a document, file, or folder for people to read — as opposed to building an app or site that runs or renders.
---

# Publish

Publish a drive file or folder as a public, anonymous, read-only **viewer**
through the Bento CLI. A publish **shows source**: it opens the path in Bento's
own file and folder viewer so visitors read exactly what is there. It never
hosts, runs, or renders a site — that is what a Bento app is for. A
published `index.html` is shown as its HTML source, not served as a web page.

Read command help for current flags and request fields.

## Source, Not Hosting

If the visitor should read the files themselves — one document, or a folder to
browse — publish it. If the visitor should get a running or rendered result — a
site with navigation, a single-page app, a service — that is an app: stop and
build an app instead. Publishing never executes the content.

## Inspect Before Mutate

List existing publishes before choosing a slug or changing one; a path may
already be published, and a slug must be unique.

```bash
bento publish list --json
```

## Publish a File or Folder

Choose any drive-relative path — a single file or a whole folder — and register
it. Send only the path and an optional slug; the server auto-detects `kind`
(`file` or `folder`) from the path:

```bash
bento publish create --path reports/q3.md --body-file - <<'JSON'
{"slug":"q3-report"}
JSON
```

The response row carries the assigned `slug` and detected `kind`. The public
viewer URL is:

```
https://edge.bento.ing/<workspaceSlug>/<publishSlug>/
```

## Verify the Viewer

Open the viewer URL and confirm both shapes show source:

- A published **file** opens in the source viewer showing its contents. A
  published `index.html` shows its HTML source; it is never served as a live
  page.
- A published **folder** opens as a file browser listing its entries; clicking
  an entry opens that file's source.

If a published `index.html` renders as a running web page instead of showing
source, the request was misrouted — the bare publish URL only ever shows source.

## URL Grammar

Every publish lives at `https://edge.bento.ing/<workspaceSlug>/<publishSlug>/*`. The bare
URL always returns the **viewer**. `?raw` and `?list` are reserved query
selectors on that same grammar — `?raw` fetches a single file's bytes and
`?list` returns a directory's JSON listing — used by the viewer itself; a bare
visit never returns raw bytes or a listing. Dotfiles (`.env`, `.git`, …) never
appear in a publish.

## Update or Delete

Read `bento publish --help` to update or remove an existing publish. Never
register a second publish of the same path as an update mechanism — inspect,
then update or delete in place.
