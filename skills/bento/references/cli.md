# Bento CLI recipes

Bento resolves the workspace from the current login and the selected default
workspace; `--workspace <slug>` overrides it for one command. A session's owner
comes from `--cwd`, never from the shell's current folder. Read the relevant
command's help for the full contract.

- List agents and use their registered `slug` and `anchorPath`: `bento agent list`.
- Find remote Drive files: `bento file search --path / --search "q3 board"`. Inspect `meta.index` before treating an empty page as complete, and follow every `nextCursor` with the same query and filters. It matches names, folder paths and the text of PDF, Word (docx), PowerPoint (pptx), Excel (xlsx), Markdown, text, CSV and HTML files; read `bento file search --help` for exclusions and matching rules.
- Message an agent's default session and wait: `bento agent session default message create --agent-slug researcher --prompt "..."`.
- Read history after a durable sequence: `bento session history list --session-id "$SESSION_ID" --order asc --after-seq 10 --limit 50`.
- Answer a session's question and wait: `bento session answer --session-id "$SESSION_ID" --answer "Continue"`.
- Save the `clientRequestId` printed to stderr before submission; reuse it with identical input when recovering an ambiguous request.
- Retry with the printed id and identical input: `bento session message create --session-id "$SESSION_ID" --prompt "..." --client-request-id "$CLIENT_REQUEST_ID"`.
- Wait for a running input without submitting it again: `bento session result get --session-id "$SESSION_ID" --seq "$INPUT_SEQ" --wait-ms 720000`.

Waiting commands return an accepted result while work is running or asking:
observe only a `running` result again, and answer an `ask` as a new input. Other
terminals finish that input. Follow each history `nextCursor` with `--cursor`
until it is null.

Created but still running is success. Follow the printed `session result get`
command to observe the result. To name an agent in a reply, write
`<Agent name="Researcher" slug="researcher" />`; this links it without messaging it.

## Sync a Mac

[Install the Bento menu bar app](setup.md#install-the-mac-app) and turn on sync in Settings. While the app runs,
`bento local sync workspace update <ws>` also enrolls a workspace; add `--folder`
for a separate local folder. Inspect mirrors with `bento local sync get`, list
enrollment with `bento local sync workspace list`, and turn a workspace off with
`bento local sync workspace delete <ws>`. Quitting the app stops sync; reopening
reconciles offline edits and reports conflicts. The CLI alone does not run sync.
