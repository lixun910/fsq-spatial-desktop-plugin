# FSQ Spatial Desktop — agent plugin & skill

Bootstrap for **FSQ Spatial Desktop**: installs and launches the app, connects its
local MCP server, and gives the agent the app's geospatial tools (DuckDB SQL +
Kepler.gl maps).

Works with **Claude Code** (as a plugin — installs the skill *and* registers the
MCP server) and **Codex** (as a plain agent skill plus an `mcp add`).

## Claude Code

```bash
claude plugin marketplace add lixun910/fsq-spatial-desktop-plugin
claude plugin install fsq-spatial-desktop@fsq-spatial-desktop-plugin
```

Restart Claude Code. The plugin bundles the skill and an `.mcp.json` that points
at `http://127.0.0.1:7750/mcp`.

## Codex (and other agent-skills clients)

Codex has no plugin system, so nothing fetches-and-registers for you — this is
plain file placement plus one `mcp add`. Two commands:

```bash
curl -fsSL --create-dirs -o ~/.agents/skills/fsq-spatial-desktop/SKILL.md https://raw.githubusercontent.com/lixun910/fsq-spatial-desktop-plugin/main/.agents/skills/fsq-spatial-desktop/SKILL.md
```

```bash
codex mcp add fsq-spatial-desktop http://127.0.0.1:7750/mcp
```

Then restart Codex. (The `mcp add` is optional — once the skill is placed, the
agent runs it itself as Step 5 — but either way you must restart for it to load.)

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
.claude-plugin/marketplace.json         # Claude Code marketplace
plugins/fsq-spatial-desktop/
  .claude-plugin/plugin.json            # plugin manifest
  .mcp.json                             # auto-registers the MCP server
  skills/fsq-spatial-desktop/SKILL.md   # the skill (Claude plugin copy)
.agents/skills/fsq-spatial-desktop/SKILL.md   # the skill (Codex copy)
install.sh                              # installs the skill + registers MCP for both
```

## Notes

- **Port:** the app prefers `7750` and falls back through `7751–7759` if that port
  is taken. Only `7750` is pre-registered. If your app bound a different port,
  register the URL from `~/.fsq-spatial/mcp.json` (or pin it with
  `FSQ_MCP_PORT=7750`).
- **Updating:** bump `version` in
  `plugins/fsq-spatial-desktop/.claude-plugin/plugin.json`, then users run
  `claude plugin update fsq-spatial-desktop`.
- **Signing:** the macOS build is Developer ID signed and notarized, so it installs
  without a Gatekeeper override.
