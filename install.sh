#!/usr/bin/env bash
# Install the FSQ Spatial Desktop bootstrap skill for Claude Code and Codex,
# and register the app's MCP server with whichever clients are installed.
set -euo pipefail

RAW="https://raw.githubusercontent.com/lixun910/fsq-spatial-desktop-plugin/main"
SKILL_URL="$RAW/.agents/skills/fsq-spatial-desktop/SKILL.md"
MCP_URL="${FSQ_MCP_URL:-http://127.0.0.1:7750/mcp}"

for dir in "$HOME/.claude/skills/fsq-spatial-desktop" \
           "$HOME/.agents/skills/fsq-spatial-desktop"; do
  mkdir -p "$dir"
  curl -fsSL "$SKILL_URL" -o "$dir/SKILL.md"
  echo "installed skill -> $dir/SKILL.md"
done

if command -v claude >/dev/null 2>&1; then
  claude mcp add --transport http fsq-spatial-desktop "$MCP_URL" 2>/dev/null \
    || echo "claude mcp: 'fsq-spatial-desktop' may already be registered"
fi

if command -v codex >/dev/null 2>&1; then
  codex mcp add fsq-spatial-desktop "$MCP_URL" 2>/dev/null \
    || echo "codex mcp: 'fsq-spatial-desktop' may already be registered"
fi

echo "Done. Restart your client, then prompt e.g. \"get population distribution of LA using FSQ Spatial Desktop.\""
