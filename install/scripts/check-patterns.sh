#!/usr/bin/env bash
# check-patterns.sh — functional-qa Gate 3 커스텀 패턴 검증
# Usage: bash .claude/scripts/check-patterns.sh "<changed_files>" <project-patterns.md>
#
# project-patterns.md의 FORBIDDEN 섹션을 파싱해 변경 파일에 grep한다.
# 위반 발견 시 stdout에 출력하고 exit 1.
#
# project-patterns.md 포맷 (금지 패턴 섹션):
#   ## FORBIDDEN
#   - pattern: <grep_pattern>
#     message: <위반 메시지>
#   - ...

CHANGED="$1"
PATTERNS_FILE="$2"

if [ ! -f "$PATTERNS_FILE" ]; then
  echo "ℹ️ project-patterns.md 없음 — 커스텀 패턴 skip"
  exit 0
fi

FORBIDDEN_SECTION=$(awk '/^## FORBIDDEN/{found=1; next} /^##/{found=0} found{print}' "$PATTERNS_FILE")
if [ -z "$FORBIDDEN_SECTION" ]; then
  echo "ℹ️ FORBIDDEN 섹션 없음 — skip"
  exit 0
fi

VIOLATIONS=0

# 패턴 파싱: "- pattern: <regex>" 줄 추출
while IFS= read -r line; do
  PATTERN=$(echo "$line" | sed -n 's/.*pattern:[[:space:]]*\(.*\)/\1/p' | tr -d '"'"'"' ')
  [ -z "$PATTERN" ] && continue

  MSG=$(grep -A1 "pattern:.*$PATTERN" "$PATTERNS_FILE" | grep 'message:' | sed 's/.*message:[[:space:]]*//')

  # 변경 파일들에 패턴 검색
  echo "$CHANGED" | while read -r f; do
    [ -f "$f" ] || continue
    HITS=$(grep -nE "$PATTERN" "$f" 2>/dev/null)
    if [ -n "$HITS" ]; then
      echo "$HITS" | while IFS= read -r hit; do
        echo "$f:$hit — 위반: ${MSG:-$PATTERN}"
      done
      VIOLATIONS=$((VIOLATIONS + 1))
    fi
  done
done <<< "$FORBIDDEN_SECTION"

[ "$VIOLATIONS" -gt 0 ] && exit 1 || exit 0
