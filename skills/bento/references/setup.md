Bento gives agents access to remote workspace files and a catalog of text, image,
and video models through one login. Use it from your own computer with the CLI
and skill, or connect an MCP client.

Choose by what you can do, not by which product you are. If you can run shell
commands on the user's computer, install the CLI and skill. If you cannot, skip
to [Add MCP for your client](#add-mcp-for-your-client).

On a Mac that can run it, first ask the user whether they want the Bento menu
bar app. It records the screen, syncs workspace folders, and brings its own CLI
and skill, keeping them updated. If they say yes, follow
[Install the Mac app](#install-the-mac-app). If they say no, or the Mac can't
run it, install the CLI and skill below; the app can be added later.

## Install the Mac app

The app needs Apple Silicon (`uname -m` is `arm64`) and macOS 26 or newer
(`sw_vers -productVersion`); on any other machine, install the CLI instead.
Download, verify and extract the latest release:

```sh
(
  set -eu
  bento_download=$(mktemp -d)
  cd "$bento_download"
  bento_release=https://github.com/dzhng/bento-releases/releases/latest/download
  curl -fL "$bento_release/SHA256SUMS" -o SHA256SUMS
  curl -fL "$bento_release/release.json" -o release.json
  curl -fL "$bento_release/Bento-macos-arm64.zip" -o Bento-macos-arm64.zip
  grep ' Bento-macos-arm64.zip$' SHA256SUMS | shasum -a 256 -c -
  cat release.json
  ditto -x -k Bento-macos-arm64.zip unpacked
  printf 'Verified release extracted at: %s\n' "$bento_download/unpacked"
)
```

Stop on a checksum failure. Then install it, updating an existing copy in place
and keeping the old one as a backup:

```sh
(
  set -eu
  bento_unpacked="/absolute/path/printed/above/unpacked"
  bento_app="$HOME/Applications/Bento.app"
  if [ ! -e "$bento_app" ] && [ -d /Applications/Bento.app ]; then bento_app=/Applications/Bento.app; fi
  if [ -e "$bento_app" ] || [ -L "$bento_app" ]; then
    osascript -e 'quit app "Bento"' || true
    bento_backup=$(mktemp -d)
    mv "$bento_app" "$bento_backup/"
    printf 'Previous app kept at: %s\n' "$bento_backup/Bento.app"
  fi
  mkdir -p "$(dirname "$bento_app")"
  ditto "$bento_unpacked/Bento.app" "$bento_app"
  open "$bento_app"
)
```

On every launch, with Settings → **Set up my agents** on (the default), the app
installs `~/.local/bin/bento` and the bento skill and refreshes both, so they
match the app after each automatic update. Don't install the CLI or the skill
separately. Call the command by its full path, `~/.local/bin/bento`, until a
new shell has it on PATH.

Verify with `~/.local/bin/bento recording operation create --operation cli.status`
and `--operation skill.status`; expect `"state": "ready"` for both. The first
launch can take a few seconds. Releases are signed but not notarized: a `curl`
download opens normally, but if macOS blocks the app, have the user open it and
approve it in System Settings → Privacy & Security → **Open Anyway**. Never
remove quarantine attributes or turn off Gatekeeper.

Then ask the user whether Bento should open when they log in. Installing is not
consent. After an explicit yes, run:

```sh
~/.local/bin/bento recording operation create --operation login.setEnabled --params '{"enabled":true}'
```

Confirm with `--operation login.status`. If it reports `requiresApproval`, have
the user allow Bento in System Settings → General → Login Items. Screen,
microphone and camera permissions are asked for at the first recording.

## Install the CLI

Install [Node](https://nodejs.org/en/download) 22.20 or newer with npm, using the
machine's runtime manager if it has one. Check `node --version` and `npm --version`.

```sh
npm i -g @bentoai/cli
bento --version
bento --help
```

If `bento` is missing from PATH, inspect `npm prefix -g`; use a user-owned prefix
rather than `sudo`. Reuse a working install, or run `bento upgrade` when an upgrade
is needed. To run a local agent prompt, use `bento --prompt "your task"`.

## Install the skill

```sh
bento local skill install --agent <id>
```

Replace `<id>` with the installer id of the client you run in: `claude-code`,
`codex`, `cursor`, or `openclaw`. Use `universal` for any other agent. Repeat
`--agent <id>` for additional clients. The CLI installs its bundled skill
without repository access and refreshes it on upgrade. Read the installed bento
skill before using Bento for the task.

## Sign in when the task needs it

Reuse a working login. Sign in only when the task needs Bento workspace access
or model billing.

If one channel is already signed in, use that login for the other. Do not put
the user through a second interactive OAuth or email login when a signed-in
channel can approve or mint credentials. Run `bento whoami` to see whether the
CLI is signed in. MCP is signed in when its tools are already available in this
session.

1. **The CLI is signed in and the task needs MCP.** Configure MCP with the CLI
   bearer. Prefer the `bento token` commands in “Add MCP for your client” over
   a fresh OAuth flow.
2. **MCP is signed in and the CLI needs a login.** Run
   `bento login --no-browser --json` and approve it with MCP `device_approve`,
   or run `bento device approve --user-code <code>` from another signed-in CLI.
   Follow “Sign the CLI in from MCP”. Prefer this over email or browser login.
3. **Neither channel is signed in.** Use the first fallback that fits:
   - **Your client can add MCP servers and the user has a browser:** add Bento
     with the client instructions below, then complete its OAuth flow. To give
     the CLI the same identity, follow “Sign the CLI in from MCP”.
   - **You can read the user's email:** run `bento login --email <address>`,
     read Bento's emailed code, then run `bento login --code XXXX-XXXX`. If you
     cannot read the mailbox, ask the user to read the code back. For a new
     signup, add `--name <name> --workspace-name <name>` to the code command
     when needed.
   - **Otherwise:** run `bento login`, keep it running, and have the user
     approve the displayed code at its browser verification URL. Use
     `--no-browser` when automatic browser opening is unavailable.

If email sign-in reports several workspaces, ask which one and repeat the code
command with `--workspace <slug>`; the code survives that refusal. If a code
expires, start a fresh login. The CLI saves the login itself; do not write its
configuration by hand.

These instructions are published at https://heybento.ai/agents.md and use the
production API https://ctl.bento.ing and MCP server https://mcp.bento.ing/.
For an explicitly requested custom server, keep `--api-url <origin>` consistent
through login and later commands.

## Add MCP for your client

Use Streamable HTTP. OAuth issues the same kind of human key as CLI login;
current membership and role determine access. Configure only the user's client.

When the CLI is already signed in, add MCP with its bearer and skip OAuth. Use
the `bento token` command in the client section below. Start OAuth only when
the CLI is not signed in, or when the client has no header or bearer setting
(ChatGPT). Never run `bento token` on its own: those commands capture it
directly. Never print the key or put it in a transcript, log, or file other
than the client's own configuration.

### Claude Code

When the CLI is already signed in, prefer this over OAuth:

```sh
claude mcp add --transport http bento https://mcp.bento.ing/ \
  --header "Authorization: Bearer $(bento token)"
```

Otherwise add the server and complete OAuth:

```sh
claude mcp add --transport http bento https://mcp.bento.ing/
claude mcp login bento
```

### Codex

When the CLI is already signed in, prefer a bearer in the process environment
over OAuth. Launch Codex with that variable each time this configuration is
used. The value stays in the process environment; do not echo it or save it to
a shell profile.

```sh
codex mcp add bento --url https://mcp.bento.ing/ --bearer-token-env-var BENTO_MCP_TOKEN
BENTO_MCP_TOKEN=$(bento token) codex
```

Otherwise:

```sh
codex mcp add bento --url https://mcp.bento.ing/
codex mcp login bento
```

### Cursor

When the CLI is already signed in, prefer this command. It merges the MCP entry
and the CLI bearer into Cursor's own `~/.cursor/mcp.json`, preserves other
servers, and does not print the key:

```sh
node --input-type=module <<'NODE'
import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
const file = join(homedir(), '.cursor', 'mcp.json');
const config = existsSync(file) ? JSON.parse(readFileSync(file, 'utf8')) : {};
const key = execFileSync('bento', ['token'], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit'] }).trim();
config.mcpServers ??= {};
config.mcpServers.bento = {
  url: 'https://mcp.bento.ing/',
  headers: { Authorization: `Bearer ${key}` },
};
mkdirSync(join(homedir(), '.cursor'), { recursive: true });
writeFileSync(file, JSON.stringify(config, null, 2) + '\n', { mode: 0o600 });
NODE
```

Otherwise merge this entry into `mcpServers` in `~/.cursor/mcp.json`, preserving
other servers. Open Cursor's MCP settings and complete Bento's OAuth sign-in.

```json
{
  "mcpServers": {
    "bento": { "url": "https://mcp.bento.ing/" }
  }
}
```

### OpenClaw

When the CLI is already signed in, prefer this over OAuth:

```sh
openclaw mcp add bento --url https://mcp.bento.ing/ --transport streamable-http \
  --header "Authorization: Bearer $(bento token)"
```

Otherwise add the server with OAuth:

```sh
openclaw mcp add bento --url https://mcp.bento.ing/ --transport streamable-http --auth oauth
```

Complete sign-in from OpenClaw's MCP settings. For terminal OAuth, stop the
Gateway with `openclaw gateway stop`, run `openclaw mcp login bento`, then restart
it with `openclaw gateway start`.

### ChatGPT

ChatGPT has no bearer-header setup here. In ChatGPT's app/connector settings,
enable developer mode if required, create a custom MCP connector named Bento at
`https://mcp.bento.ing/`, choose OAuth, and complete consent.

### Any other MCP client

When the CLI is signed in and the client takes request headers, put
`Authorization: Bearer $(bento token)` directly into the client's configuration.
Otherwise add a Streamable HTTP server named `bento` at `https://mcp.bento.ing/`
and complete its OAuth sign-in.

### Sign the CLI in from MCP

Start this as a continuing process, keeping it alive while you approve:

```sh
bento login --no-browser --json
```

Read its `user_code` from the `pending_user` event. In the signed-in Bento MCP
session, call `device_approve` with `{"userCode":"<that user_code>"}`. Wait for
the CLI's `approved` event and exit. Another signed-in CLI can instead run
`bento device approve --user-code <code>`.

## Check access

```sh
bento whoami
```

For workspace operations, inspect the `workspaces` returned by `bento whoami --json` and select the
intended slug with `bento local config update --workspace <slug>` or an advertised per-command
`--workspace <slug>`. Ask when the task does not identify which workspace to use.
If an operation returns `409 onboarding_required`, send the human the returned
`onboardingUrl` resolved against https://app.bento.ing (or the matching app origin
for a custom server). Ask them to finish setup and verify a payment method in
Bento; never collect their card details. Follow the
[workspace onboarding workflow](https://docs.bento.ing/getting-started.md#finish-workspace-onboarding)
before retrying the operation.
