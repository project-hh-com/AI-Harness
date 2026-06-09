#!/usr/bin/env bash
# AI-Harness · SessionStart Hook
# 세션 시작 시 파이프라인 정책·상태 리마인더를 컨텍스트로 주입.
# 빠르고 비차단이어야 함. stdout → 세션 컨텍스트로 주입됨.

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$(pwd)/.claude}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 공유 감지 함수 로드
# shellcheck source=../scripts/detect-project-type.sh
source "$SCRIPT_DIR/../scripts/detect-project-type.sh"

# CLAUDE.md 상태
ROOT_CLAUDE="없음 ⚠️"
[ -f "CLAUDE.md" ] && ROOT_CLAUDE="있음"
CLAUDE_MD_COUNT=$(find . -name CLAUDE.md -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')

# 프로젝트 타입 감지 (35+ 스택)
PROJECT_TYPE=$(detect_project_type "$(pwd)")

cat <<EOF
[AI-Harness 활성]
- 진입점: /implement <자연어 input> — input-refiner→planner→implementer→QA→release 9단계 자동.
- 핵심 정책: 보호 파일(.claude/rules/protected-files.md) 편집 금지 · 보호 브랜치 직접 타겟 금지.
- 코드 작성 시 rules/coding-behavior.md(Evidence Gate·최소변경·추정금지) 준수.
- 감지된 project_type: ${PROJECT_TYPE}
- 계층 CLAUDE.md: 루트 ${ROOT_CLAUDE} · 총 ${CLAUDE_MD_COUNT}개 (없으면 /harness-init-claude-md 로 생성, 파일당 ≤130줄).
EOF

exit 0
