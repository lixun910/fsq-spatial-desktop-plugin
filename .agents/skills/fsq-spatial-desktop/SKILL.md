---
name: fsq-spatial-desktop
description: Set up and connect to FSQ Spatial Desktop so this agent can drive its geospatial tools (DuckDB + Kepler.gl maps) over MCP. Use when the user asks to visualize, map, or query spatial/business data "with FSQ Spatial Desktop" / "using the spatial desktop app", or when the fsq-spatial-desktop MCP tools are not yet available in this session.
---

# FSQ Spatial Desktop bootstrap

FSQ Spatial Desktop is a desktop app (Electron + DuckDB + Kepler.gl) that hosts a
local MCP server. Once connected, this agent can create projects, run SQL, build
H3/geospatial analyses, and render maps in the app by calling its tools.

This skill installs, launches, and registers that app. It is **idempotent** — run
the first step and skip ahead if the tools are already available.

## Step 0 — Are we already connected?

If this session already exposes the `fsq-spatial-desktop` MCP tools
(`executeApi`, `project/list`, `project/create`, `askUserQuestion`), the setup is
done: **skip to "Step 6 — Drive it"** and answer the original request.

You can check from the CLI too:

```bash
claude mcp list
```

If a `fsq-spatial-desktop` entry is present and connected, skip to Step 6. (If it
is present but disconnected, the app is probably not running — continue at Step 4.)

## Step 1 — Download the installer

Two sources — prefer the **pinned build**, fall back to the **latest release**
only when the pinned artifact isn't served for this platform:

- **Pinned build** — `https://spatial-desktop.foursquare.com/app-data/skill/`
  serves a fixed filename for the build this skill was published with (no
  manifest). As published it holds the macOS Apple Silicon DMG only.
- **Latest release** — `https://spatial-desktop.foursquare.com/releases/<os>-<arch>/`
  carries a `latest*.yml` manifest naming the current version and artifact.

Platform map for the release channel:

| Platform              | Directory   | Manifest           | Artifact                            |
| --------------------- | ----------- | ------------------ | ----------------------------------- |
| macOS (Apple Silicon) | `mac-arm64` | `latest-mac.yml`   | `FSQ-Spatial-<ver>-arm64.dmg`       |
| macOS (Intel)         | `mac-x64`   | `latest-mac.yml`   | `FSQ-Spatial-<ver>-x64.dmg`         |
| Windows (x64)         | `win-x64`   | `latest.yml`       | `FSQ-Spatial-<ver>-x64-setup.exe`   |
| Linux (x64)           | `linux-x64` | `latest-linux.yml` | `FSQ-Spatial-<ver>-x86_64.AppImage` |

macOS (adjust `arm64` → `x64` on Intel; check with `uname -m`). The pinned
download is a fixed version — if it 404s, the fallback picks up the latest
release:

```bash
FSQ_VER=0.6.0
FSQ_DIST=https://spatial-desktop.foursquare.com/app-data/skill
FILE="FSQ-Spatial-${FSQ_VER}-arm64.dmg"
if curl -fL "$FSQ_DIST/$FILE" -o "/tmp/$FILE"; then
  echo "Downloaded pinned build $FILE from $FSQ_DIST"
else
  BASE=https://spatial-desktop.foursquare.com/releases/mac-arm64
  FILE=$(curl -fsSL "$BASE/latest-mac.yml" | sed -n 's/^  *- url: *//p' | grep '\.dmg$' | head -1)
  curl -fL "$BASE/$FILE" -o "/tmp/$FILE"
  echo "Downloaded latest release $FILE from $BASE"
fi
```

Windows (PowerShell):

```powershell
$base = 'https://spatial-desktop.foursquare.com/releases/win-x64'
$yml  = (Invoke-WebRequest "$base/latest.yml" -UseBasicParsing).Content
$file = ($yml -split "`n" | Where-Object { $_ -match 'setup\.exe$' } |
         Select-Object -First 1) -replace '^\s*-?\s*url:\s*',''
Invoke-WebRequest "$base/$($file.Trim())" -OutFile "$env:TEMP\FSQ-Spatial-setup.exe"
```

## Step 2 — Install

- **macOS:** mount the DMG, copy the app to `/Applications`, unmount. Release
  builds are signed and notarized, so it should open normally. If Gatekeeper
  blocks a prerelease build, clear the quarantine flag (note in your summary that
  this bypassed Gatekeeper):

```bash
hdiutil attach "/tmp/$FILE" -nobrowse -mountpoint /tmp/fsq-dmg
cp -R "/tmp/fsq-dmg/FSQ Spatial Desktop.app" /Applications/
hdiutil detach /tmp/fsq-dmg
# only if macOS then refuses to launch it:
# xattr -dr com.apple.quarantine "/Applications/FSQ Spatial Desktop.app"
```

- **Windows:** run the `-setup.exe`. It is a per-user NSIS installer; run it
  non-interactively with `& "$env:TEMP\FSQ-Spatial-setup.exe" /S` (or launch it
  and let the user click through).

- **Linux:** make the AppImage executable and place it somewhere on `PATH`:

```bash
chmod +x FSQ-Spatial-*-x86_64.AppImage
mkdir -p ~/.local/bin && mv FSQ-Spatial-*-x86_64.AppImage ~/.local/bin/fsq-spatial-desktop
```

## Step 3 — Launch the app

Starting the app also starts its MCP server (it binds a port in **7750–7759**) —
it does **not** need a project to be open first. Launch it and give it a few
seconds:

```bash
# macOS
open -a "FSQ Spatial Desktop"
# Linux
~/.local/bin/fsq-spatial-desktop &
# Windows
& "$env:LOCALAPPDATA\Programs\FSQ Spatial Desktop\FSQ Spatial Desktop.exe"
```

**First run shows a sign-in screen.** Tell the user to sign in in the app window
that appeared. Sign-in is the human gate — the MCP listener stays loopback-only
and unauthenticated, so this is how the account is established. Data operations
that need an account will fail until they do.

Then wait for the server to come up (poll the discovery file):

```bash
for i in $(seq 1 30); do
  [ -f ~/.fsq-spatial/mcp.json ] && break
  sleep 1
done
cat ~/.fsq-spatial/mcp.json 2>/dev/null || echo "discovery file not written yet"
```

## Step 4 — Find the MCP URL

The app writes `~/.fsq-spatial/mcp.json` on bind, containing `{url, port}`. Use
that URL. If the file is missing, probe the default range:

```bash
for p in $(seq 7750 7759); do
  code=$(curl -s -m 1 -o /dev/null -w '%{http_code}' -X POST \
    -H 'content-type: application/json' -H 'accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":1,"method":"ping"}' "http://127.0.0.1:$p/mcp")
  [ "$code" = "200" ] && { echo "http://127.0.0.1:$p/mcp"; break; }
done
```

Verify the server answers before registering (a `ping` should return `{}`):

```bash
curl -s -X POST -H 'content-type: application/json' \
  -H 'accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"ping"}' \
  "http://127.0.0.1:7750/mcp"
```

## Step 5 — Register with this client

Register the discovered URL (no `?project=` param — the agent creates a project
itself in Step 6):

```bash
claude mcp add --transport http fsq-spatial-desktop http://127.0.0.1:7750/mcp
```

```bash
codex mcp add fsq-spatial-desktop http://127.0.0.1:7750/mcp
```

Use the real URL from Step 4. Then **tell the user to restart the client** (Codex
requires a full restart; Claude Code needs a restart or an in-session `/mcp`
reconnect) so the new server is loaded. After that restart, re-run the original
request — there are no more manual steps.

## Step 6 — Drive it

Once the `fsq-spatial-desktop` tools are available:

1. `project/list` — see whether a project is already open.
2. If none, `project/create` with `{"name": "<short-task-name>"}`. This creates
   `~/Documents/FSQ Spatial/<name>.spatial`, opens it in the app, and returns the
   project's MCP URL (`?project=<key>`) plus a `worksheetId`-ready workspace. No
   native dialog is involved.
3. `executeApi` — the single typed surface for everything else (`data.query`,
   `map.create-layer`, `data.classify`, `worksheet`/`block-document.*`, …). Read
   the tool description for the full `apiName` list, and read the bundled skills
   as MCP resources (`resources/list` → `skill://built-in/...`) for the workflow
   of the specific analysis.
4. The map/tables update live in the app window as you work.

## Notes

- **Ports:** the server prefers 7750 and falls back through 7759 if a port is
  taken. Pin it with `FSQ_MCP_PORT` if you need a fixed URL. The discovery file
  always records the port actually bound.
- **Auth:** the MCP listener is loopback-only (127.0.0.1) with no token — the
  manual sign-in in Step 3 is the gate. Anyone with local access to the machine
  can drive the app while it is running and MCP is on; the user can turn MCP off
  from the app's **MCP** toggle in the AI Agent panel header.
- **Installing this skill:** an agent-skills client loads a skill from a
  `<skills-dir>/<name>/SKILL.md` directory, so fetch this file into that shape:

```bash
mkdir -p ~/.claude/skills/fsq-spatial-desktop
curl -fsSL https://spatial-desktop.foursquare.com/app-data/skill/SKILL.md \
  -o ~/.claude/skills/fsq-spatial-desktop/SKILL.md
# Codex / other agent-skills clients read the same file:
mkdir -p ~/.agents/skills/fsq-spatial-desktop
cp ~/.claude/skills/fsq-spatial-desktop/SKILL.md \
  ~/.agents/skills/fsq-spatial-desktop/SKILL.md
```

If you already have this repo checked out, copying `skills/fsq-spatial-desktop/`
to either of those directories works the same way.
