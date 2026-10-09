#!/usr/bin/env bash
# Install the FSQ Spatial Desktop bootstrap skill for Claude Code and Codex,
# and register the app's MCP server.
#
# The server is registered as a COMMAND — the stdio launcher below — and not as
# the app's HTTP URL. A URL in the model's context is one it can drive by hand
# (hand-written JSON-RPC over curl) whenever the server's tools are missing from
# its session, which is what happens when a client was not restarted after
# registering, or started while the app was down. As a command, the client owns
# the transport and the model only ever sees tools.
set -euo pipefail

RAW="https://raw.githubusercontent.com/lixun910/fsq-spatial-desktop-plugin/main"
SKILL_DIR="skills/fsq-spatial-desktop"
LAUNCHER="$HOME/.fsq-spatial/bin/fsq-spatial-desktop-mcp"
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

# The launcher both clients run. It finds the app's port from
# ~/.fsq-spatial/mcp.json (7750, or the next free port up to 7759) and passes
# each frame through to it, so the app must be running when the client calls.
mkdir -p "$(dirname "$LAUNCHER")"
curl -fsSL "$RAW/plugins/fsq-spatial-desktop/bin/fsq-spatial-desktop-mcp" -o "$LAUNCHER"
chmod +x "$LAUNCHER"
echo "installed launcher -> $LAUNCHER"

# Fallback for clients that do not auto-wire: register the server directly.
if command -v codex >/dev/null 2>&1; then
  codex mcp add fsq-spatial-desktop -- "$LAUNCHER" 2>/dev/null \
    || echo "codex mcp: 'fsq-spatial-desktop' may already be registered"
fi

if command -v claude >/dev/null 2>&1; then
  # `-s user`: the default scope is `local`, which applies to one project
  # directory only.
  claude mcp add -s user fsq-spatial-desktop -- "$LAUNCHER" 2>/dev/null \
    || echo "claude mcp: 'fsq-spatial-desktop' may already be registered"
fi

# Windows has no /bin/sh, so the launcher cannot run there. Register the URL
# instead — it works, it just leaves the model able to reach the endpoint.
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*)
    echo "Windows: registering the HTTP endpoint instead (no /bin/sh for the launcher)."
    command -v codex >/dev/null 2>&1 && codex mcp add fsq-spatial-desktop --url "$MCP_URL" 2>/dev/null || true
    command -v claude >/dev/null 2>&1 && claude mcp add --transport http fsq-spatial-desktop "$MCP_URL" 2>/dev/null || true
    ;;
esac

echo "Done. Restart your client, then prompt e.g. \"get population distribution of LA using FSQ Spatial Desktop.\""
