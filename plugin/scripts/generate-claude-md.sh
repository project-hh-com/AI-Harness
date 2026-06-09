#!/usr/bin/env bash
# AI-Harness · 계층 CLAUDE.md 생성기 (범용)
#
# 매니페스트(claude-md-manifest.tsv)의 각 디렉토리에 대해 CLAUDE.md를 생성한다.
# 기본 동작: claude CLI를 헤드리스로 호출 → 실제 디렉토리 코드를 읽고 해당 영역의
# 실제 패턴/금지/규칙을 반영한 CLAUDE.md를 작성하게 한다.
# claude CLI가 없거나 --no-ai면 정적 스켈레톤으로 폴백한다.
#
# 규칙: 파일당 130줄 이내. 기존 CLAUDE.md는 절대 덮어쓰지 않음(--force 예외).
# 실제 존재하는 디렉토리에만 생성.
#
# 사용:
#   generate-claude-md.sh [TARGET]                대상 레포에 생성 (기본 cwd)
#   generate-claude-md.sh --no-ai [TARGET]        claude 호출 없이 스켈레톤만
#   generate-claude-md.sh --force [TARGET]        기존 CLAUDE.md도 재생성
#   generate-claude-md.sh --dry-run [TARGET]      생성 대상만 출력
# 환경변수:
#   HARNESS_CLAUDE_MODEL=sonnet   claude -p 모델 (기본: claude 기본값)

set -uo pipefail

MAX_LINES=130
USE_AI="yes"; FORCE="no"; DRY="no"; TARGET=""; PROJECT_TYPE="auto"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/claude-md-manifest.tsv"

while [ $# -gt 0 ]; do
  case "$1" in
    --no-ai) USE_AI="no" ;;
    --force) FORCE="yes" ;;
    --dry-run) DRY="yes" ;;
    --manifest) MANIFEST="$2"; shift ;;
    --project-type) PROJECT_TYPE="$2"; shift ;;
    -*) echo "알 수 없는 옵션: $1" >&2; exit 1 ;;
    *) TARGET="$1" ;;
  esac
  shift
done
TARGET="${TARGET:-$(pwd)}"
TARGET="$(cd "$TARGET" && pwd)"

[ -f "$MANIFEST" ] || { echo "매니페스트 없음: $MANIFEST" >&2; exit 1; }

# 공유 감지 함수 로드
# shellcheck source=./detect-project-type.sh
source "$SCRIPT_DIR/detect-project-type.sh"

# ── 프로젝트 타입 자동 감지 (35+ 스택) ──────────────────────────────
if [ "$PROJECT_TYPE" = "auto" ]; then
  PROJECT_TYPE=$(detect_project_type "$TARGET")
fi

echo "감지된 project_type: $PROJECT_TYPE"

# claude CLI 가용성
if [ "$USE_AI" = "yes" ] && ! command -v claude >/dev/null 2>&1; then
  echo "ℹ️  claude CLI 없음 — 스켈레톤 폴백으로 전환" >&2
  USE_AI="no"
fi

# ── 정적 스켈레톤 ────────────────────────────────────────────────────
write_skeleton() {
  local file="$1" title="$2" resp="$3" rel="$4"
  local parent
  if [ "$rel" = "." ]; then parent="(루트 — 최상위)"; else parent="../CLAUDE.md (상위 규칙 상속)"; fi
  cat > "$file" <<EOF
# CLAUDE.md — $title

> $resp
> 상위 CLAUDE.md 규칙을 상속하며, 이 영역 고유 규칙만 추가한다. ⚠️ 130줄 이내 유지.

## TL;DR
- TODO: 이 영역에서 가장 먼저 알아야 할 1~2줄.

## Hard Stops (이 영역 절대 금지)
- TODO: 예) 보호 파일 편집 금지 · 직접 외부 API 호출 금지.

## Always (이 영역 항상)
- TODO: 예) API 클라이언트 경유 · 타입 명시.

## 패턴 · 참조 파일
- TODO: 대표 파일 경로 + 패턴명 (실제 경로로 채울 것).

## 의존 방향
- TODO: import 허용 방향 명시.

## 관련
- 상위: $parent
EOF
}

# ── Claude Code 호출 생성 ─────────────────────────────────────────────
generate_with_ai() {
  local file="$1" title="$2" resp="$3" rel="$4"
  local sections
  if [ "$rel" = "." ]; then
    sections="## TL;DR / ## Hard Stops (프로젝트 전역 절대 금지) / ## Always / ## Task → 진입 규칙 / ## 프로젝트 구조 / ## 개발 워크플로우"
  else
    sections="## TL;DR / ## Hard Stops (이 영역 절대 금지) / ## Always / ## 패턴·참조 파일 (실제 경로) / ## 의존 방향 / ## 관련"
  fi

  local prompt
  prompt=$(cat <<PROMPT
이 레포지토리의 '${rel}' 디렉토리를 위한 계층 CLAUDE.md를 작성해주세요.

프로젝트 타입: ${PROJECT_TYPE}
영역: ${title} — ${resp}

지침:
1. 이 디렉토리의 실제 파일 2~5개를 Read 도구로 읽어 현재 패턴을 파악하세요.
2. 다음 섹션으로 구성하세요: ${sections}
3. 실제 파일 경로와 패턴을 인용하세요 (추상적 지침 금지).
4. 130줄 이내로 압축하세요.
5. 이 영역에서 자주 발생하는 실수/위반을 Hard Stops에 명시하세요.
6. Korean으로 작성하세요.

출력: CLAUDE.md 내용만 (다른 설명 없이).
PROMPT
)

  local MODEL_FLAG=""
  [ -n "${HARNESS_CLAUDE_MODEL:-}" ] && MODEL_FLAG="--model $HARNESS_CLAUDE_MODEL"

  # claude -p 헤드리스 호출 (타겟 디렉토리 컨텍스트)
  local result
  result=$(cd "$(dirname "$TARGET/$rel")" && \
    claude -p $MODEL_FLAG "$prompt" 2>/dev/null) || true

  if [ -n "$result" ] && [ "$(echo "$result" | wc -l)" -gt 5 ]; then
    echo "$result" > "$file"
    echo "  ✓ AI 생성: $file"
  else
    write_skeleton "$file" "$title" "$resp" "$rel"
    echo "  ✓ 스켈레톤 폴백: $file"
  fi
}

# ── 매니페스트 처리 ──────────────────────────────────────────────────
CREATED=0; SKIPPED=0

while IFS='|' read -r rel tier title resp; do
  # 주석·빈 줄 skip
  [[ "$rel" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${rel// }" ]] && continue

  rel="${rel// /}"
  tier="${tier// /}"
  title="${title// /}"
  resp="${resp// /}"

  # 실제 디렉토리 확인
  TARGET_DIR="$TARGET/$rel"
  [ "$rel" = "." ] && TARGET_DIR="$TARGET"
  [ ! -d "$TARGET_DIR" ] && continue

  TARGET_FILE="$TARGET_DIR/CLAUDE.md"

  # 기존 파일 보존 (--force 아니면)
  if [ -f "$TARGET_FILE" ] && [ "$FORCE" = "no" ]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [ "$DRY" = "yes" ]; then
    echo "  [dry-run] 생성 예정: $TARGET_FILE"
    continue
  fi

  if [ "$USE_AI" = "yes" ]; then
    generate_with_ai "$TARGET_FILE" "$title" "$resp" "$rel"
  else
    write_skeleton "$TARGET_FILE" "$title" "$resp" "$rel"
    echo "  ✓ 스켈레톤: $TARGET_FILE"
  fi
  CREATED=$((CREATED + 1))

done < "$MANIFEST"

echo ""
echo "완료: ${CREATED}개 생성 / ${SKIPPED}개 기존 파일 보존"
echo "생성 후 /harness-init-claude-md 로 AI 보강 가능."
