# FSQ Spatial Desktop — agent plugin & skill

Bootstrap for **FSQ Spatial Desktop**: installs and launches the app, connects its
local MCP server, and gives the agent the app's geospatial tools (DuckDB SQL +
Kepler.gl maps).

One tree ships three forms: a **Claude Code plugin** (via a marketplace), a
portable **Agent Plugin** (`plugin.json` + `mcp.json`, the cross-vendor format
Codex/ChatGPT read), and a plain **agent skill** for clients with no plugin
loader.

## Claude Code

```bash
claude plugin marketplace add lixun910/fsq-spatial-desktop-plugin
claude plugin install fsq-spatial-desktop@fsq-spatial-desktop-plugin
```

Restart Claude Code. The plugin bundles the skill and `.mcp.json`, which
registers the MCP server at `http://127.0.0.1:7750/mcp`.

## Codex

Codex reads skills from `$HOME/.agents/skills`, and a skill's `agents/openai.yaml`
can declare an MCP dependency for Codex to wire up. Install both files:

```bash
curl -fsSL --create-dirs -o ~/.agents/skills/fsq-spatial-desktop/SKILL.md https://raw.githubusercontent.com/lixun910/fsq-spatial-desktop-plugin/main/.agents/skills/fsq-spatial-desktop/SKILL.md
```

```bash
curl -fsSL --create-dirs -o ~/.agents/skills/fsq-spatial-desktop/agents/openai.yaml https://raw.githubusercontent.com/lixun910/fsq-spatial-desktop-plugin/main/.agents/skills/fsq-spatial-desktop/agents/openai.yaml
```

If Codex doesn't wire the server from the declared dependency, add it directly:

```bash
codex mcp add fsq-spatial-desktop --url http://127.0.0.1:7750/mcp
```

Then restart Codex.

## One command for both clients

```bash
curl -fsSL https://raw.githubusercontent.com/lixun910/fsq-spatial-desktop-plugin/main/install.sh | bash
```

## Then

Restart the client and prompt, e.g. *"get population distribution of LA using
FSQ Spatial Desktop."* The skill downloads the installer for your platform,
installs and launches the app, finds its MCP server, and drives it.

## Layout

```
.claude-plugin/marketplace.json                Claude Code marketplace
plugins/fsq-spatial-desktop/
  .claude-plugin/plugin.json                   Claude Code plugin manifest
  .mcp.json                                    Claude: auto-registers the MCP server
  plugin.json                                  Agent Plugins 1.0.0 manifest
  mcp.json                                     Agent Plugins: MCP declaration
  skills/fsq-spatial-desktop/SKILL.md          the skill
.agents/skills/fsq-spatial-desktop/
  SKILL.md                                     the skill (Codex copy)
  agents/openai.yaml                           Codex: MCP dependency + UI metadata
install.sh                                     installs the skill + MCP for both
```

## Notes

- **Port:** the app prefers `7750` and falls back through `7751–7759` if that port
  is taken. The manifest pins `7750`. If your app bound a different port, register
  the URL from `~/.fsq-spatial/mcp.json` (or pin it with `FSQ_MCP_PORT=7750`).
- **Updating:** bump `version` in both
  `plugins/fsq-spatial-desktop/.claude-plugin/plugin.json` and
  `plugins/fsq-spatial-desktop/plugin.json`, then users run
  `claude plugin update fsq-spatial-desktop`.
- **Signing:** the macOS build is Developer ID signed and notarized, so it installs
  without a Gatekeeper override.
