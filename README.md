# custom-claude-status-bar-setup

Claude Code 하단 status line 설정.

출력 예시:

```
haiku-low | ctx: 12% (TTL 04:59) | git diff 1 files +281 -266 | 5h: 75% (↺2h10m) | 7d: 95% (↺3d04h) | $1.2
```

- `ctx`: 컨텍스트 사용률
- `TTL`: 프롬프트 캐시 만료까지 남은 시간
- `git diff N files +A -D`: 현재 작업 디렉터리의 **HEAD 대비** 추적 중인 파일 수와 추가/삭제 라인 수 (untracked 파일 제외, 변경이 없으면 `0 files +0 -0`)
- `5h`, `7d`: 사용량 한도와 재설정 시각. 퍼센트는 70% 미만 초록, 70% 이상 주황, 90% 이상 빨강

## 요구 사항

- Claude Code
- `python3`
- `git`
- bash

## 설치

```bash
git clone git@github.com:jiho264/custom-claude-status-bar-setup.git
cd custom-claude-status-bar-setup
bash install.sh
```

`install.sh`가 하는 일:

1. `statusline-command.sh`를 `~/.claude/statusline-command.sh`에 복사합니다.
2. `~/.claude/settings.json`의 `statusLine` 항목을 설정합니다. 다른 설정은 그대로 둡니다. 수정 전 파일은 `settings.json.bak.<시각>`으로 백업됩니다.

설치 후 Claude Code를 다시 시작하면 적용됩니다.

## 참고

- git 표시는 `git --no-optional-locks`로 실행되므로 1초마다 갱신돼도 index 락을 잡지 않습니다.
- git 리포가 아닌 디렉터리에서는 git 구간이 `0 files +0 -0`으로 나옵니다.
- 스크립트는 stdin으로 받은 JSON의 `workspace.current_dir`(없으면 `cwd`)를 기준으로 git을 실행합니다.
