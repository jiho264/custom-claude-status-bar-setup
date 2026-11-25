# custom-claude-status-bar-setup

A custom status line for Claude Code.

Example output:

```
haiku-low | ctx: 12% (TTL 04:59) | git diff 1 files +281 -266 | 5h: 75% (↺2h10m) | 7d: 95% (↺3d04h) | $1.2
```

- `ctx`: context window usage.
- `TTL`: time left until the prompt cache expires.
- `git diff N files +A -D`: number of tracked files changed relative to **HEAD**, plus added/deleted line counts for the current working directory. Untracked files are excluded. With no changes it shows `0 files +0 -0`.
- `5h`, `7d`: usage-limit percentages and reset times. The percentage is green below 70%, orange at 70% and above, and red at 90% and above.

## Requirements

- Claude Code
- `python3`
- `git`
- bash

## Install

```bash
git clone git@github.com:jiho264/custom-claude-status-bar-setup.git
cd custom-claude-status-bar-setup
bash install.sh
```

What `install.sh` does:

1. Copies `statusline-command.sh` to `~/.claude/statusline-command.sh`.
2. Sets the `statusLine` entry in `~/.claude/settings.json`. Other settings are left untouched. The previous file is backed up as `settings.json.bak.<timestamp>`.

Restart Claude Code after installing to apply the change.

## Install with Claude Code

Paste this into Claude Code:

```text
Clone git@github.com:jiho264/custom-claude-status-bar-setup.git into ~/custom-claude-status-bar-setup, run its install.sh, then check that the statusLine entry in ~/.claude/settings.json is set correctly. Tell me when Claude Code needs a restart.
```

## Notes

- The git segment runs `git --no-optional-locks`, so refreshing every second does not take the index lock.
- Outside a git repository, the git segment shows `0 files +0 -0`.
- The script runs git in `workspace.current_dir` from the JSON on stdin, falling back to `cwd`.
