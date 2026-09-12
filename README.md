# FSQ Spatial Desktop — agent skill

Bootstrap skill for **FSQ Spatial Desktop**: it downloads and launches the app
and gives the agent the app's geospatial tools (DuckDB SQL + Kepler.gl maps).

The skill is published in the formats clients load: a **Claude Code plugin**
(via a marketplace), a portable **Agent Plugin** (the cross-vendor format
Codex/ChatGPT read), and a plain **agent skill** for clients with no plugin
loader.

## Claude Code

```bash
claude plugin marketplace add lixun910/fsq-spatial-desktop-plugin
claude plugin install fsq-spatial-desktop@fsq-spatial-desktop-plugin
```

Restart Claude Code to load the skill.

## Codex

Codex installs skills with its built-in `$skill-installer` — point it at this
repo's skill directory, in a Codex session:

```
$skill-installer install https://github.com/lixun910/fsq-spatial-desktop-plugin/tree/main/.agents/skills/fsq-spatial-desktop
```

Restart Codex afterwards. (The installer aborts if the skill is already
installed; remove the existing skill directory first to reinstall.)

If `$skill-installer` isn't available, copy the skill files by hand:

```bash
curl -fsSL --create-dirs -o ~/.agents/skills/fsq-spatial-desktop/SKILL.md https://raw.githubusercontent.com/lixun910/fsq-spatial-desktop-plugin/main/.agents/skills/fsq-spatial-desktop/SKILL.md
```

```bash
curl -fsSL --create-dirs -o ~/.agents/skills/fsq-spatial-desktop/agents/openai.yaml https://raw.githubusercontent.com/lixun910/fsq-spatial-desktop-plugin/main/.agents/skills/fsq-spatial-desktop/agents/openai.yaml
```

## One command for both clients

```bash
curl -fsSL https://raw.githubusercontent.com/lixun910/fsq-spatial-desktop-plugin/main/install.sh | bash
```

## Then

Restart the client and prompt, e.g. *"get population distribution of LA using
FSQ Spatial Desktop."* The skill downloads the installer for your platform,
installs and launches the app, and drives its tools.

## Layout

```
.claude-plugin/marketplace.json                                  Claude Code marketplace
plugins/fsq-spatial-desktop/.claude-plugin/plugin.json           Claude Code plugin manifest
plugins/fsq-spatial-desktop/skills/fsq-spatial-desktop/SKILL.md  the skill
.agents/skills/fsq-spatial-desktop/SKILL.md                      the skill (Codex copy)
install.sh                                                       installs the skill for both clients
```

## Notes

- **Updating:** bump `version` in both
  `plugins/fsq-spatial-desktop/.claude-plugin/plugin.json` and
  `plugins/fsq-spatial-desktop/plugin.json`, then users run
  `claude plugin update fsq-spatial-desktop`.
- **Signing:** the macOS build is Developer ID signed and notarized, so it installs
  without a Gatekeeper override.
