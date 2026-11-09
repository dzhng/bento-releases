---
name: memory
description: Recall and add to the Bento workspace's shared memory — what its agents have learned about the user, their people, their decisions and their work — for the whole workspace or one agent, and train it on sources. Use when a task touches past work, people or decisions, or when asked to remember, save, look up, learn or train on something.
---

# Memory

A Bento workspace remembers. Every session its agents run is observed, condensed
and recalled across sessions, so the workspace holds what the user has told any
of them and what they have learned doing the work. This skill reads and adds to
that shared memory from here. It is the workspace's memory, not this computer's.

Memory is kept at two levels. The workspace's own memory is shared by everyone in
it. Each agent also has its own, which only that agent's sessions recall. Find an
agent's `slug` with `bento agent list`.

## Recall before you answer

When a task turns on something the workspace may already know — a person, a
customer, a past decision, a preference, how something was done last time —
search before answering or asking the user again:

```bash
bento memory search --q "pricing decision for enterprise plans" --limit 10 --json
bento agent memory search --agent-slug sales --q "pricing decision for enterprise plans" --json
```

Search the workspace first, and the agent whose work the task is about when there
is one. Results are ranked by relevance; say what you found and where, and treat
an empty result as "not remembered", not as evidence of the opposite.

## Save when asked

Write to memory only when the user asks you to remember something. Record what
they said in their own words, not your paraphrase:

```bash
bento memory create --content "Prefers metric units in reports" --source user --json
bento agent memory create --agent-slug sales --content "Enterprise discounts cap at 20%" --source user --json
```

Use the workspace for what everyone should know and an agent for what changes
how that one agent works. When it is not clear which, ask. The command answers
with the stored record; report success only once it has.

## Train on sources, when asked

Training reads sources, writes a record of what they say, and installs it in
memory. Start a job only when the user asks to train on something, not because
material came up.

```bash
bento train job create --body-file - <<'JSON'
{"urls":["https://example.com/handbook"]}
JSON
```

`bento agent train job create --agent-slug <slug>` trains one agent instead. Files
already in the Drive train through `driveFiles` paths. To train on a file on this
computer, put it in the Drive first with
`bento file update --path uploads/<name> --in <local file>`.

The job answers with a `jobId`. Poll `bento train job get --job-id <jobId>` (or
`bento agent train job get --agent-slug <slug> --job-id <jobId>`) until it
reaches a terminal state, then tell the user what was learned and where it
lives. `bento train --help` lists the record commands for reviewing or
correcting what training installed.
