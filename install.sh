#!/usr/bin/env bash
# Install the FSQ Spatial Desktop bootstrap skill for Claude Code and Codex,
# and register the app's MCP server.
set -euo pipefail

RAW="https://raw.githubusercontent.com/lixun910/fsq-spatial-desktop-plugin/main"
SKILL_DIR="skills/fsq-spatial-desktop"
MCP_URL="${FSQ_MCP_URL:-http://127.0.0.1:7750/mcp}"

# Claude Code reads ~/.claude/skills; Codex reads $HOME/.agents/skills.
for base in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
  dir="$base/fsq-spatial-desktop"
  mkdir -p "$dir"
  curl -fsSL "$RAW/.agents/$SKILL_DIR/SKILL.md" -o "$dir/SKILL.md"
  echo "installed skill -> $dir/SKILL.md"
done

# Codex-only: agents/openai.yaml declares the MCP dependency, so Codex can
# install and wire the server itself.
CODEX_DIR="$HOME/.agents/skills/fsq-spatial-desktop"
mkdir -p "$CODEX_DIR/agents"
curl -fsSL "$RAW/.agents/$SKILL_DIR/agents/openai.yaml" -o "$CODEX_DIR/agents/openai.yaml"

# Fallback for clients that do not auto-wire: register the server directly.
if command -v codex >/dev/null 2>&1; then
  codex mcp add fsq-spatial-desktop --url "$MCP_URL" 2>/dev/null \
    || echo "codex mcp: 'fsq-spatial-desktop' may already be registered"
fi

if command -v claude >/dev/null 2>&1; then
  claude mcp add --transport http fsq-spatial-desktop "$MCP_URL" 2>/dev/null \
    || echo "claude mcp: 'fsq-spatial-desktop' may already be registered"
fi

echo "Done. Restart your client, then prompt e.g. \"get population distribution of LA using FSQ Spatial Desktop.\""
