#!/bin/bash
export STATUSLINE_INPUT="$(cat)"

python3 <<'PY'
import json, os, datetime, subprocess

d = json.loads(os.environ['STATUSLINE_INPUT'])

pct = int(d.get('context_window', {}).get('used_percentage', 0))
cost = d.get('cost', {}).get('total_cost_usd', 0)
rl = d.get('rate_limits', {}) or {}
r5_obj = rl.get('five_hour') or {}
r7_obj = rl.get('seven_day') or {}
r5 = int(r5_obj.get('used_percentage', 0))
r7 = int(r7_obj.get('used_percentage', 0))

def remaining_str(ts):
    if not ts:
        return ''
    remaining = max(0, int(ts - datetime.datetime.now().timestamp()))
    h, m = divmod(remaining // 60, 60)
    if h >= 24:
        d, h = divmod(h, 24)
        return f'(↺{d}d{h:02d}h)'
    return f'(↺{h}h{m:02d}m)'

reset5_str = remaining_str(r5_obj.get('resets_at'))
reset7_str = remaining_str(r7_obj.get('resets_at'))

def clr(p):
    return '\033[31m' if p >= 90 else '\033[33m' if p >= 70 else '\033[32m'

R = '\033[0m'
GRAY = '\033[90m'
GREEN = '\033[32m'
RED = '\033[31m'
model = (d.get('model') or {}).get('display_name', '?')
effort = (d.get('effort') or {}).get('level', '?')
exp = (d.get('prompt_cache') or {}).get('expires_at')
if exp:
    left = max(0, int(exp - datetime.datetime.now().timestamp()))
    cache_str = f'TTL {left//60:02d}:{left%60:02d}'
else:
    cache_str = 'TTL --:--'
# git: tracked changes vs HEAD (untracked ignored); always shown, 0 when clean
cwd = (d.get('workspace') or {}).get('current_dir') or d.get('cwd') or os.getcwd()
def git(*args):
    try:
        return subprocess.run(['git', '--no-optional-locks', '-C', cwd, *args],
                              capture_output=True, text=True, timeout=5).stdout
    except Exception:
        return ''
n_files = add = dele = 0
if git('rev-parse', '--is-inside-work-tree').strip() == 'true':
    for line in git('diff', 'HEAD', '--numstat').splitlines():
        parts = line.split('\t')
        if len(parts) < 3: continue
        n_files += 1
        if parts[0].isdigit(): add += int(parts[0])
        if parts[1].isdigit(): dele += int(parts[1])   # binary files show '-'
git_str = f" | git diff {n_files} files {GREEN}+{add}{R} {RED}-{dele}{R}"

print(f"{model.lower().replace(' ', '-')}-{effort} | ctx: {clr(pct)}{pct}%{R} ({cache_str}){git_str} | 5h: {clr(r5)}{r5}%{R} {GRAY}{reset5_str}{R} | 7d: {clr(r7)}{r7}%{R} {GRAY}{reset7_str}{R} | ${cost:.1f}")
PY
