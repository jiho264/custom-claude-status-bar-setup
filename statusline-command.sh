#!/bin/bash
export STATUSLINE_INPUT="$(cat)"

python3 <<'PY'
import json, os, datetime

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

in_new = in_cached = out_tot = 0
last_ts = None; last_ttl = 300
tp = d.get('transcript_path')
if tp and os.path.exists(tp):
    try:
        with open(tp) as f:
            for line in f:
                try: e = json.loads(line)
                except: continue
                u = (e.get('message') or {}).get('usage')
                if not u: continue
                cc = u.get('cache_creation') or {}
                if e.get('timestamp') and not e.get('isSidechain'):
                    try:
                        last_ts = datetime.datetime.fromisoformat(e['timestamp'].replace('Z', '+00:00')).timestamp()
                        if cc.get('ephemeral_1h_input_tokens', 0) > 0: last_ttl = 3600
                        elif cc.get('ephemeral_5m_input_tokens', 0) > 0: last_ttl = 300
                    except: pass
                in_new += int(u.get('input_tokens', 0))
                in_new += int(u.get('cache_creation_input_tokens', 0))
                in_cached += int(u.get('cache_read_input_tokens', 0))
                out_tot += int(u.get('output_tokens', 0))
    except: pass

def fmt(n):
    return f'{n/1e6:.1f}M'

def clr(p):
    return '\033[31m' if p >= 90 else '\033[33m' if p >= 70 else '\033[32m'

cache_str = ''
if last_ts:
    left = int(last_ts + last_ttl - datetime.datetime.now().timestamp())
    cache_str = ' ⏳cache:' + (f'{left//60}:{left%60:02d}' if left > 0 else 'expired')

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
import subprocess
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
