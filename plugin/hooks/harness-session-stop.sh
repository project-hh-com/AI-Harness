#!/usr/bin/env bash
# AI-Harness · Stop Hook — 세션 종료 시 자기강화 신호 추출
# QA 리포트 분석 → 반복 실패 패턴을 project-patterns.md 등록 후보로 수집

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$(pwd)/.claude}"
QA_DIR="$CLAUDE_DIR/qa-reports"

[ ! -d "$QA_DIR" ] && exit 0

# 최근 QA 리포트에서 반복 실패 패턴 추출
RECENT_REPORTS=$(find "$QA_DIR" -name "*.md" -newer "$QA_DIR" -mmin -120 2>/dev/null | head -10)
[ -z "$RECENT_REPORTS" ] && exit 0

FAIL_COUNT=$(echo "$RECENT_REPORTS" | xargs grep -h "❌" 2>/dev/null | wc -l | tr -d ' ')

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "[AI-Harness] 세션 종료 — QA 실패 $FAIL_COUNT 건 감지"
  echo "   반복 실패 패턴은 .claude/rules/project-patterns.md 에 등록하면"
  echo "   다음 세션부터 Gate 3에서 자동 검출됩니다."
fi

exit 0
