#!/usr/bin/env bash
# AI-Harness · PreCompact Hook — 컨텍스트 압축 전 중요 상태 보존
# 현재 진행 중인 wave·plan 상태를 .claude/.session-resume.md에 저장

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$(pwd)/.claude}"
RESUME_FILE="$CLAUDE_DIR/.session-resume.md"

# 가장 최근 plan 파일
LATEST_PLAN=$(find "$CLAUDE_DIR/plans" -name "*.md" 2>/dev/null | sort -t- -k1 -r | head -1)
# 가장 최근 QA 리포트
LATEST_QA=$(find "$CLAUDE_DIR/qa-reports" -name "*.md" 2>/dev/null | sort -t- -k1 -r | head -1)
# git 상태
GIT_STATUS=$(git status --short 2>/dev/null | head -10 || echo "(git 없음)")
GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")

cat > "$RESUME_FILE" <<EOF
# Session Resume Context
> PreCompact 시 저장됨. 컨텍스트 압축 후 상태 복원에 사용.

## 현재 브랜치
$GIT_BRANCH

## 최근 plan
${LATEST_PLAN:-"없음"}

## 최근 QA 리포트
${LATEST_QA:-"없음"}

## Git 상태 (상위 10개)
\`\`\`
$GIT_STATUS
\`\`\`

## 재시작 후 할 것
1. \`cat $LATEST_PLAN\` 로 현재 plan 확인
2. 완료된 wave와 남은 wave 확인 (R11)
3. 마지막 QA 리포트 확인 후 다음 단계 진행
EOF

exit 0
