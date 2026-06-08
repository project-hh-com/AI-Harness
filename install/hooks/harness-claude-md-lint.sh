#!/usr/bin/env bash
# AI-Harness · PostToolUse(Edit|Write) Hook — CLAUDE.md 파일 130줄 제한 검사
# STDIN: {"tool_input": {"file_path": "<path>"}, ...}

set -uo pipefail

INPUT=$(cat)
FILE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

[ -z "$FILE" ] && exit 0

# CLAUDE.md 파일이 아니면 skip
echo "$FILE" | grep -q "CLAUDE.md" || exit 0
[ ! -f "$FILE" ] && exit 0

MAX_LINES=130
LINE_COUNT=$(wc -l < "$FILE" | tr -d ' ')

if [ "$LINE_COUNT" -gt "$MAX_LINES" ]; then
  echo "⚠️ [AI-Harness] CLAUDE.md 줄 수 초과 — $FILE ($LINE_COUNT 줄 / 최대 $MAX_LINES 줄)"
  echo "   파일을 분리하거나 내용을 압축하세요."
fi

exit 0
