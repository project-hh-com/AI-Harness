#!/usr/bin/env bash
# AI-Harness · PreToolUse(Edit) Hook — 편집 영향도 사전 경고
# STDIN: {"tool_input": {"file_path": "<path>", ...}}
# HIGH/MEDIUM 경고를 stdout에 출력 (차단하지 않고 에이전트에게 인식시킴)

set -uo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

[ -z "$FILE" ] && exit 0

# 1. 보호 파일 확인
PROTECTED_PATTERNS=(
  "next.config" "vite.config" "webpack.config" "babel.config"
  ".eslintrc" ".prettierrc" "tailwind.config"
  ".github/workflows" "Dockerfile" "docker-compose"
  "package.json" "yarn.lock" "package-lock.json"
)

for p in "${PROTECTED_PATTERNS[@]}"; do
  if echo "$FILE" | grep -q "$p"; then
    echo "🛑 [AI-Harness] HIGH: 보호 파일 편집 시도 — $FILE"
    echo "   rules/protected-files.md 참조. 이 파일은 편집 금지입니다."
    exit 2
  fi
done

# 타겟 레포 커스텀 보호 파일
if [ -f ".claude/rules/protected-files.md" ]; then
  CUSTOM_BLOCK=$(awk '/## 타겟 레포 커스텀/,0' .claude/rules/protected-files.md 2>/dev/null)
  while IFS= read -r line; do
    pattern=$(echo "$line" | sed 's/^# - //' | tr -d ' ')
    [ -z "$pattern" ] && continue
    if echo "$FILE" | grep -q "$pattern"; then
      echo "🛑 [AI-Harness] HIGH: 커스텀 보호 파일 편집 시도 — $FILE"
      exit 2
    fi
  done <<< "$CUSTOM_BLOCK"
fi

# 2. 공용 영역 편집 경고 (MEDIUM — 차단하지 않음)
if echo "$FILE" | grep -qE '/(utils|helpers|lib|hooks|common)/'; then
  IMPORTER_COUNT=$(grep -r "from.*$(basename "$FILE" | sed 's/\.[^.]*$//')" \
    --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
    --include="*.py" --include="*.go" \
    . 2>/dev/null | grep -v node_modules | grep -v ".git" | wc -l | tr -d ' ')
  if [ "$IMPORTER_COUNT" -gt 5 ]; then
    echo "⚠️ [AI-Harness] MEDIUM: 공용 영역 파일 편집 — $FILE (${IMPORTER_COUNT}개 모듈이 의존)"
    echo "   기존 동작 보존 증거(E5)를 남겨야 합니다."
  fi
fi

exit 0
