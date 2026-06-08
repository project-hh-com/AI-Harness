#!/usr/bin/env bash
# AI-Harness · PreToolUse(Bash) Hook — 위험 명령 사전 차단
# STDIN: {"tool_input": {"command": "<bash command>"}}
# 차단 시 exit 2 (사용자 확인 요청) 또는 exit 1 (즉시 거부)

set -uo pipefail

INPUT=$(cat)
CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")

# 1. 보호 브랜치 직접 push 차단
if echo "$CMD" | grep -qE 'git push.*(origin )?(main|master|prd|production|prod)\b'; then
  echo "❌ [AI-Harness] 보호 브랜치 직접 push 차단. release Agent를 통해 Draft PR로 진행하세요."
  exit 2
fi

# 2. 강제 push 차단 (--force / -f)
if echo "$CMD" | grep -qE 'git push.*--force\b|git push.*\s-f\b'; then
  echo "❌ [AI-Harness] --force push 차단. --force-with-lease 검토 또는 사용자 승인 필요."
  exit 2
fi

# 3. 환경변수 파일 커밋 차단
if echo "$CMD" | grep -qE 'git add.*\.env|git commit.*\.env'; then
  echo "❌ [AI-Harness] .env 파일 커밋 시도 차단. 시크릿을 저장소에 커밋하지 마세요."
  exit 1
fi

# 4. node_modules 직접 수정 차단
if echo "$CMD" | grep -qE '(edit|write|rm|cp|mv).*node_modules/'; then
  echo "❌ [AI-Harness] node_modules 직접 수정 차단."
  exit 1
fi

# 5. git reset --hard 경고 (사용자 확인 요청)
if echo "$CMD" | grep -qE 'git reset --hard'; then
  echo "⚠️ [AI-Harness] git reset --hard 감지. 미커밋 변경사항이 사라집니다. 계속하려면 승인하세요."
  exit 2
fi

exit 0
