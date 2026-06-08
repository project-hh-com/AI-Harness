#!/usr/bin/env bash
# AI-Harness · SessionStart Hook
# 세션 시작 시 파이프라인 정책·상태 리마인더를 컨텍스트로 주입.
# 빠르고 비차단이어야 함. stdout → 세션 컨텍스트로 주입됨.

set -uo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$(pwd)/.claude}"

# CLAUDE.md 상태
ROOT_CLAUDE="없음 ⚠️"
[ -f "CLAUDE.md" ] && ROOT_CLAUDE="있음"
CLAUDE_MD_COUNT=$(find . -name CLAUDE.md -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | wc -l | tr -d ' ')

# 프로젝트 타입 감지
PROJECT_TYPE="unknown"
if [ -f "package.json" ]; then
  grep -q '"next"' package.json 2>/dev/null && PROJECT_TYPE="nextjs"
  grep -q '"expo"' package.json 2>/dev/null && PROJECT_TYPE="react-native"
  [ "$PROJECT_TYPE" = "unknown" ] && grep -q '"react"' package.json 2>/dev/null && PROJECT_TYPE="react"
  [ "$PROJECT_TYPE" = "unknown" ] && PROJECT_TYPE="node"
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
  PROJECT_TYPE="python"
elif [ -f "go.mod" ]; then
  PROJECT_TYPE="go"
elif [ -f "Cargo.toml" ]; then
  PROJECT_TYPE="rust"
elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
  PROJECT_TYPE="java"
fi

cat <<EOF
[AI-Harness 활성]
- 진입점: /implement <자연어 input> — input-refiner→planner→implementer→QA→release 9단계 자동.
- 핵심 정책: 보호 파일(.claude/rules/protected-files.md) 편집 금지 · 보호 브랜치 직접 타겟 금지.
- 코드 작성 시 rules/coding-behavior.md(Evidence Gate·최소변경·추정금지) 준수.
- 감지된 project_type: ${PROJECT_TYPE}
- 계층 CLAUDE.md: 루트 ${ROOT_CLAUDE} · 총 ${CLAUDE_MD_COUNT}개 (없으면 /harness-init-claude-md 로 생성, 파일당 ≤130줄).
EOF

exit 0
