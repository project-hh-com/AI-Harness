#!/usr/bin/env bash
# AI-Harness · PostToolUse(Edit|Write) Hook — UI 파일 변경 후 빠른 패턴 검사
# STDIN: {"tool_input": {"file_path": "<path>"}, "tool_response": {...}}
# 경고만 출력 (차단 없음 — functional-qa가 공식 게이트)

set -uo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

[ -z "$FILE" ] || [ ! -f "$FILE" ] && exit 0

# 빠른 패턴 체크 (변경된 파일만)
WARNINGS=()

# 공통 패턴
grep -qnE 'console\.(log|warn|error)\(' "$FILE" 2>/dev/null && \
  WARNINGS+=("console.log 잔류 — 프로덕션 코드에서 제거 필요")

grep -qnE '(TODO|FIXME|HACK)\(' "$FILE" 2>/dev/null && \
  WARNINGS+=("미처리 TODO/FIXME 감지 — plan에 명시됐는지 확인")

# JS/TS 특화
if echo "$FILE" | grep -qE '\.(js|jsx|ts|tsx)$'; then
  grep -qnE "import axios from 'axios'" "$FILE" 2>/dev/null && \
    WARNINGS+=("axios 직접 import — 프로젝트 API 래퍼 사용 권장")

  grep -qnE "process\.env\.[A-Z_]+" "$FILE" 2>/dev/null && \
    echo "$FILE" | grep -qE '^(pages|app|src/pages|src/app)/' && \
    WARNINGS+=("클라이언트 코드에서 process.env 직접 접근 감지")
fi

# Python 특화
if echo "$FILE" | grep -qE '\.py$'; then
  grep -qnE '^import \*' "$FILE" 2>/dev/null && \
    WARNINGS+=("wildcard import — 명시적 import 사용 권장")
fi

# 경고 출력
if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo "⚠️ [AI-Harness] post-edit 패턴 경고 — $FILE"
  for w in "${WARNINGS[@]}"; do
    echo "   · $w"
  done
fi

exit 0
