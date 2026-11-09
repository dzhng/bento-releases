# Bento MCP Server

One subscription. Every kind of AI. Bento is an MCP server that gives agents access to
frontier models for text, images, video and voice, workspace files, memory, integrations,
remote sandboxes, and paid data services — through one login.

**Server URL:** `https://mcp.bento.ing/`

**Authentication:** OAuth 2.0 (recommended) or Bearer token from the Bento CLI.

## Quick Install

### Claude Desktop / Claude Code

**With OAuth (recommended):**

```bash
claude mcp add --transport http bento https://mcp.bento.ing/
claude mcp login bento
```

**With CLI bearer (if already signed in):**

```bash
claude mcp add --transport http bento https://mcp.bento.ing/ \
  --header "Authorization: Bearer $(bento token)"
```

### Cursor

**One-click install:** [cursor://anysphere.cursor.ide/mcp/install?name=bento&config=%7B%22url%22%3A%22https%3A%2F%2Fmcp.bento.ing%2F%22%7D](cursor://anysphere.cursor.ide/mcp/install?name=bento&config=%7B%22url%22%3A%22https%3A%2F%2Fmcp.bento.ing%2F%22%7D)

**With CLI bearer:** Run this command (merges config, never prints the key):

```bash
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

**Manual (with OAuth):** Add to `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "bento": { "url": "https://mcp.bento.ing/" }
  }
}
```

Then complete OAuth sign-in in Cursor's MCP settings.

### VS Code (Copilot MCP)

Add to your VS Code settings (settings.json):

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

**With CLI bearer:**

```bash
codex mcp add bento --url https://mcp.bento.ing/ --bearer-token-env-var BENTO_MCP_TOKEN
BENTO_MCP_TOKEN=$(bento token) codex
```

**With OAuth:**

```bash
codex mcp add bento --url https://mcp.bento.ing/
codex mcp login bento
```

### ChatGPT

In ChatGPT's app/connector settings, enable developer mode if required, create a
custom MCP connector named Bento at `https://mcp.bento.ing/`, choose OAuth, and
complete consent.

### Any MCP Client

Bento uses **Streamable HTTP** transport at `https://mcp.bento.ing/`. Add a bearer
header with `Authorization: Bearer $(bento token)` when the CLI is signed in, or
complete OAuth when it is not.

## Tools

Bento exposes 100+ tools organized by capability. Each tool requires workspace
authorization via OAuth or bearer token.

### Models & Media Generation

| Tool | Description |
|------|-------------|
| `model_list` | Discover available AI models with metadata |
| `model_chat` | Text generation via chat completions |
| `model_responses` | OpenAI Responses API |
| `model_messages` | Anthropic Messages API |
| `model_image` | Generate images from text prompts |
| `model_video` | Generate videos from text prompts |
| `model_video_start` | Start async video generation |
| `model_video_status` | Poll video generation status |
| `model_embedding` | Generate text embeddings |
| `media_generate` | Unified media generation (image/video by role) |

### Sessions & Agents

| Tool | Description |
|------|-------------|
| `session_create` | Start a new agent session |
| `session_message_create` | Send a message to a session |
| `session_get` | Get session details |
| `session_list` | List sessions |
| `session_history_list` | Get session message history |
| `agent_list` | List agents in a workspace |
| `agent_create` | Register a new agent |
| `agent_update` | Update agent configuration |

### Files & Drive

| Tool | Description |
|------|-------------|
| `file_list` | List files in a directory |
| `file_get` | Read file contents |
| `file_update` | Write file contents |
| `file_delete` | Delete a file |
| `file_search` | Search files by name or content |
| `file_upload_create` | Get upload grant for new file |
| `file_download_create` | Get download URL for file |

### Memory & Training

| Tool | Description |
|------|-------------|
| `memory_create` | Add to workspace memory |
| `memory_search` | Search workspace memory |
| `agent_memory_create` | Add to agent-specific memory |
| `agent_memory_search` | Search agent memory |
| `train_job_create` | Start training from sources |
| `train_record_list` | List training records |

### Apps & Publishing

| Tool | Description |
|------|-------------|
| `app_create` | Register a new app |
| `app_launch` | Deploy an app |
| `app_get` | Get app details |
| `publish_create` | Publish files publicly |
| `share_create` | Share with specific people |

### Integrations & Services

| Tool | Description |
|------|-------------|
| `integration_catalog_list` | List available integrations |
| `integration_connect` | Connect an integration |
| `integration_tool_execute` | Execute integration tool |
| `service_list` | List paid data services |
| `service_proxy_get` | Call service API (GET) |
| `service_proxy_post` | Call service API (POST) |

### Workspace Administration

| Tool | Description |
|------|-------------|
| `whoami` | Get current identity and workspaces |
| `workspace_create` | Create a new workspace |
| `member_list` | List workspace members |
| `billing_get` | Get billing information |
| `billing_usage_get` | Get usage statistics |

### Desktop & Recordings

| Tool | Description |
|------|-------------|
| `desktop_status_get` | Get VM desktop status |
| `desktop_viewer_grant_create` | Get desktop viewer access |
| `recording_operation_create` | Create recording operations |

## Resources

The server exposes MCP resources for file reads:

- **File reads:** `bento://file/{workspaceSlug}/{path}` — Read workspace files
- **Session images:** API-backed resources for session snapshots
- **Training sources:** Archived training source content

## Pricing

Bento subscriptions start at $20/month with included credits for models and services.
See [heybento.ai](https://heybento.ai) for current plans.

## Links

- **Product:** [heybento.ai](https://heybento.ai)
- **Documentation:** [docs.bento.ing](https://docs.bento.ing)
- **API Reference:** [docs.bento.ing/reference](https://docs.bento.ing/reference)
- **CLI:** `npm i -g @bentoai/cli`
- **Support:** [heybento.ai/support](https://heybento.ai/support)
