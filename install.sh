#!/usr/bin/env bash
# Set up a machine: global agent instructions + every skill I use (this repo + externals).
# Add new externals here so other machines can replay them.
set -euo pipefail
cd "$(dirname "$0")"

# one global instructions file, symlinked for every agent; existing real files kept as .bak
link() { mkdir -p "$(dirname "$2")"; [ -e "$2" ] && [ ! -L "$2" ] && mv "$2" "$2.bak"; ln -sfn "$1" "$2"; }
link "$PWD/global/AGENTS.md" ~/.agents/AGENTS.md
link "$PWD/global/CLAUDE.md" ~/.claude/CLAUDE.md
link ~/.agents/AGENTS.md ~/.codex/AGENTS.md

# executor v2 MCP (linear/pylon/sentry/lightdash/rainbow/... apps behind one server); needs `executor` service running.
# install: curl -fsSL https://executor.sh/docs/install.sh | sh. Clients auth with the local API key from the keychain.
plist=~/Library/LaunchAgents/sh.executor.v2.plist
if [ "$(uname)" = Darwin ] && [ -x ~/.local/bin/executor ] && [ ! -e "$plist" ]; then
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>sh.executor.v2</string>
  <key>ProgramArguments</key>
  <array><string>$HOME/.local/bin/executor</string><string>service</string><string>start</string></array>
  <key>EnvironmentVariables</key>
  <dict><key>PATH</key><string>/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin</string></dict>
  <key>RunAtLoad</key><true/>
  <key>AbandonProcessGroup</key><true/>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/executor-v2.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/executor-v2.err.log</string>
</dict>
</plist>
EOF
  launchctl bootstrap "gui/$(id -u)" "$plist" 2>/dev/null || true
fi
key=$(security find-generic-password -s com.usefulsoftware.executor.v2 -w 2>/dev/null | jq -r .apiKey 2>/dev/null || true)
if command -v executor >/dev/null && [ -n "$key" ]; then
  claude mcp add --transport http -s user executor http://127.0.0.1:4312/mcp -H "Authorization: Bearer $key" 2>/dev/null || true
  grep -q '^\[mcp_servers\.executor\]' ~/.codex/config.toml 2>/dev/null ||
    printf '\n[mcp_servers.executor]\nurl = "http://127.0.0.1:4312/mcp"\nhttp_headers = { Authorization = "Bearer %s" }\n' "$key" >> ~/.codex/config.toml
fi

add() { npx skills add "$@" -g --agent '*' -y; }

# this repo
add notgiorgi/skills --skill '*'

add mattpocock/skills \
  --skill ask-matt \
  --skill chief-of-staff \
  --skill code-review \
  --skill codebase-design \
  --skill diagnosing-bugs \
  --skill domain-modeling \
  --skill grill-me \
  --skill grill-with-docs \
  --skill grilling \
  --skill handoff \
  --skill implement \
  --skill implement-spec \
  --skill improve-codebase-architecture \
  --skill prototype \
  --skill research \
  --skill resolving-merge-conflicts \
  --skill retro \
  --skill setup-matt-pocock-skills \
  --skill tdd \
  --skill teach \
  --skill to-questionnaire \
  --skill to-spec \
  --skill to-tickets \
  --skill triage \
  --skill wait-what \
  --skill wayfinder \
  --skill wizard \
  --skill writing-for-agents

add github/gh-stack \
  --skill gh-stack

add ogulcancelik/herdr \
  --skill herdr

add pbakaus/impeccable \
  --skill impeccable

add humanlayer/skills \
  --skill show-me \
  --skill visual-pr

add typesafe-ai/skills \
  --skill typesafe-ai

add t3dotgg/tstack \
  --skill council \
  --skill sol-loop

# proof-of-work reads blast-radius and benchmark-checklist; maintain-verification-skill keeps its feature map current
add cursor/plugins \
  --skill benchmark-checklist \
  --skill blast-radius \
  --skill bro \
  --skill ketchup \
  --skill maintain-verification-skill \
  --skill unslop

add vercel-labs/agent-skills \
  --skill vercel-react-best-practices
