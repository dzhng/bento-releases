---
name: manage-agents
description: Create, configure and inspect agents in a Bento workspace from this computer — register an agent folder, write its instructions and config into the Drive, give it an icon, and change or remove it. Use when setting up an agent persona or repeatable agent process, or changing an existing one.
---

# Manage Agents

An agent is a folder in the workspace's Drive. Its files are its behavior:
`AGENTS.md` is its instructions, `agent.json` its optional config, and
`.agents/skills/<skill>/SKILL.md` its own skills. The [agents guide](https://docs.bento.ing/agents.md)
owns what each file may contain, including onboarding; read it before writing
them. Command help owns the flags and request fields.

## Inspect before you change anything

```bash
bento agent list --json
```

Use the returned rows to pick a free slug, find an existing agent's `slug` and
`anchorPath`, and see what is already set. Change an existing agent with
`bento agent update --agent-slug <slug>` and only the fields that change; a second
registration is not an update.

## Create one

**Ask the user what to call the agent before you create anything.** The name is
theirs: it is what they see on its page and beside every session it runs. It is
free-form, up to 32 characters, and independent of the slug, which is lowercase
kebab-case and appears in URLs. A rejected slug answers `400`, a taken one
`409`; pick another, nothing adjusts it for you.

Create the folder, write its instructions, then register it. Put it under
`agents/` unless the user names another place:

```bash
bento file action create --body-file - <<'JSON'
{"operation":"mkdir","path":"agents/research","recursive":true}
JSON
bento file update --path agents/research/AGENTS.md --in AGENTS.md
bento agent create --path agents/research --slug research --name Research
```

Write `AGENTS.md` as the agent's concise identity and operating instructions,
addressed to the agent. Write `agent.json`, `DESCRIPTION.md` or `ONBOARDING.md`
the same way, only when the guide says the agent needs them.

Every agent gets an icon. Generate a 1024x1024 PNG with the
[media-creation skill](../media-creation/SKILL.md): full-bleed, no rounded
corners, border or text, at most 1 MB. Put it in the folder and point the agent
at it:

```bash
bento file update --path agents/research/icon.png --in icon.png
bento agent update --agent-slug research --body-file - <<'JSON'
{"icon":"icon.png"}
JSON
```

After replacing the bytes at the same filename, send the same `icon` again so
the displayed image refreshes.

Finish by giving the user the agent's page,
`https://app.bento.ing/w/<workspace>/agents/<slug>`, named with its display name.

## Work with it

Start a session for the agent with
`bento session create --cwd agents/<slug> --prompt "<the work>"`, as the Bento
skill shows. To review or add to what it remembers, use the
[memory skill](../memory/SKILL.md). To go through its onboarding again, clear this
workspace's completion with `bento agent update --agent-slug <slug> --onboarded=false`.

Deleting an agent with `bento agent delete` also deletes its folder, including
nested agents and apps. Move anything worth keeping out of that folder first, and
confirm with the user before deleting.
