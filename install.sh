#!/usr/bin/env bash
# Installs the custom Claude Code status line.
#  1. copies statusline-command.sh to ~/.claude/
#  2. sets "statusLine" in ~/.claude/settings.json (other keys are kept; a backup is made)
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
TARGET="$CLAUDE_DIR/statusline-command.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
command -v git >/dev/null || { echo "git is required (for the diff segment)" >&2; exit 1; }

mkdir -p "$CLAUDE_DIR"
cp "$SRC_DIR/statusline-command.sh" "$TARGET"
chmod +x "$TARGET"

if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
else
  echo '{}' > "$SETTINGS"
fi

python3 - "$SETTINGS" "bash $TARGET" <<'PY'
import json, sys
path, cmd = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
data["statusLine"] = {"type": "command", "command": cmd, "refreshInterval": 1}
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

echo "Installed: $TARGET"
echo "statusLine set in: $SETTINGS (backup kept next to it)"
echo "Restart Claude Code (or start a new session) to see the status line."
