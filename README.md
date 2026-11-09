# Bento

One subscription. Every kind of AI. Bento is an MCP server and agent skill that gives agents access to frontier models for text, images, video and voice, workspace files, memory, integrations, remote sandboxes, and paid data services — through one login.

**Website:** [heybento.ai](https://heybento.ai) · **MCP Server:** `https://mcp.bento.ing/` · **Docs:** [docs/MCP.md](docs/MCP.md)

## Quick Install

### Claude Desktop / Claude Code

```bash
claude mcp add --transport http bento https://mcp.bento.ing/
claude mcp login bento
```

### Cursor

**One-click:** [Install Bento MCP](cursor://anysphere.cursor.ide/mcp/install?name=bento&config=%7B%22url%22%3A%22https%3A%2F%2Fmcp.bento.ing%2F%22%7D)

Or add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "bento": { "url": "https://mcp.bento.ing/" }
  }
}
```

### VS Code (Copilot MCP)

Add to VS Code settings.json:

```json
{
  "mcp": {
    "servers": {
      "bento": {
        "url": "https://mcp.bento.ing/",
        "transport": "http"
      }
    }
  }
}
```

### Codex

```bash
codex mcp add bento --url https://mcp.bento.ing/
codex mcp login bento
```

### ChatGPT

In ChatGPT's connector settings, create a custom MCP connector named Bento at `https://mcp.bento.ing/`, choose OAuth, and complete consent.

### Agent Skill

Install the Bento skill for agents that support skills.sh:

```bash
npx skills add dzhng/bento-releases
```

The skill is in the [`skills/bento`](skills/bento) folder. See [`skills/bento/SKILL.md`](skills/bento/SKILL.md) for usage.

### CLI

```bash
npm i -g @bentoai/cli
bento login
```

## Documentation

- [MCP Server Documentation](docs/MCP.md) — Full tool reference and install options
- [Agent Skill](skills/bento/SKILL.md) — Install and operate the CLI on the user's computer
- [API Reference](https://docs.bento.ing/reference) — Full API documentation
- [Getting Started](https://heybento.ai) — Product information and pricing

---

## Bento for Mac

Signed builds of the Bento Mac app. This repository holds release files only; the source is private.

- **Download:** <https://updates.bento.ing/mac/download> (the latest install kit)
- **Updates:** Installed apps check <https://updates.bento.ing/mac/appcast.xml> and update themselves through Sparkle.

Each release lists the install kit (`Bento-macos-arm64.zip`), the signed update archive, the appcast, `SHA256SUMS` and a `release.json` receipt naming the source revision it was built from.

### Install the Mac app

The app needs Apple Silicon and macOS 26 or newer. Download the latest release:

```sh
curl -fLO https://github.com/dzhng/bento-releases/releases/latest/download/Bento-macos-arm64.zip
curl -fLO https://github.com/dzhng/bento-releases/releases/latest/download/SHA256SUMS
grep ' Bento-macos-arm64.zip$' SHA256SUMS | shasum -a 256 -c -
unzip Bento-macos-arm64.zip -d ~/Applications
open ~/Applications/Bento.app
```

The app keeps the CLI and skill updated automatically. Releases are signed but not notarized: if macOS blocks the app, approve it in System Settings → Privacy & Security → **Open Anyway**.
