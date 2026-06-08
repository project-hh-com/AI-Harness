#!/usr/bin/env bash
# AI-Harness 범용 설치 스크립트
# Next.js, React Native, React, Python, Go, Rust, Java, Node 프로젝트 지원
#
# 사용법:
#   ./install.sh                              현재 디렉토리에 설치
#   ./install.sh /path/to/project             특정 프로젝트에 설치
#   ./install.sh --uninstall [경로]           제거
#   ./install.sh --update [경로]              백업 없이 덮어쓰기
#   ./install.sh --doctor [경로]              의존성 검사만
#   ./install.sh --skip-claude-md [경로]      계층 CLAUDE.md 생성 건너뜀
#   ./install.sh --claude-md-skeleton [경로]  AI 호출 없이 스켈레톤만 생성

set -euo pipefail

RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'; PURPLE=$'\033[0;35m'; CYAN=$'\033[0;36m'
BOLD=$'\033[1m'; RESET=$'\033[0m'

TARGET=""
MODE="install"
CLAUDE_MD="ai"

for arg in "$@"; do
  case "$arg" in
    --uninstall) MODE="uninstall" ;;
    --update) MODE="update" ;;
    --doctor) MODE="doctor" ;;
    --skip-claude-md) CLAUDE_MD="skip" ;;
    --claude-md-skeleton) CLAUDE_MD="skeleton" ;;
    --help|-h)
      cat <<EOF
${BOLD}AI-Harness 범용 설치 스크립트${RESET}

사용법:
  ./install.sh                              현재 디렉토리에 설치
  ./install.sh /path/to/project             특정 프로젝트에 설치
  ./install.sh --uninstall [경로]           제거
  ./install.sh --update [경로]              백업 없이 덮어쓰기
  ./install.sh --doctor [경로]              의존성 검사만
  ./install.sh --skip-claude-md [경로]      계층 CLAUDE.md 생성 건너뜀
  ./install.sh --claude-md-skeleton [경로]  AI 호출 없이 스켈레톤만 생성

지원 프로젝트 타입 (자동 감지):
  • Next.js  • React Native/Expo  • React  • Node.js
  • Python  • Go  • Rust  • Java  • Generic

설치 항목:
  • 9개 에이전트 (.claude/agents/)
  • implement · harness-init-claude-md 스킬 (.claude/skills/)
  • 4개 룰 파일 (.claude/rules/)
  • 7개 hooks (.claude/hooks/)
  • 출력 디렉토리 (.claude/refined-inputs/, plans/, qa-reports/)
  • 계층 CLAUDE.md (파일당 ≤130줄)
  • settings.local.json (hooks 자동 등록)
EOF
      exit 0
      ;;
    -*) echo -e "${RED}❌ 알 수 없는 옵션: $arg${RESET}"; exit 1 ;;
    *) TARGET="$arg" ;;
  esac
done

TARGET="${TARGET:-$(pwd)}"
TARGET="$(cd "$TARGET" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# install/에 자산이 있으면 그걸 쓰고, plugin/이 있으면 plugin/ 우선
PLUGIN_DIR=""
if [ -d "$SCRIPT_DIR/../plugin/agents" ]; then
  PLUGIN_DIR="$(cd "$SCRIPT_DIR/../plugin" && pwd)"
elif [ -d "$SCRIPT_DIR/agents" ]; then
  PLUGIN_DIR="$SCRIPT_DIR"
fi
CLAUDE_DIR="$TARGET/.claude"

echo -e "${BOLD}${PURPLE}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${PURPLE}║      AI-Harness · Universal Multi-Agent          ║${RESET}"
echo -e "${BOLD}${PURPLE}╚══════════════════════════════════════════════════╝${RESET}"
echo ""

if [ ! -d "$TARGET" ]; then
  echo -e "${RED}❌ 대상 디렉토리가 존재하지 않습니다: $TARGET${RESET}"
  exit 1
fi

if [ -z "$PLUGIN_DIR" ] || [ ! -d "$PLUGIN_DIR/agents" ]; then
  echo -e "${RED}❌ agents/ 디렉토리를 찾을 수 없습니다.${RESET}"
  exit 1
fi

# ── 프로젝트 타입 자동 감지 ──────────────────────────────────────────
detect_project_type() {
  local dir="$1"
  if [ -f "$dir/package.json" ]; then
    grep -q '"next"' "$dir/package.json" 2>/dev/null && echo "nextjs" && return
    grep -q '"expo"' "$dir/package.json" 2>/dev/null && echo "react-native" && return
    grep -q '"react"' "$dir/package.json" 2>/dev/null && echo "react" && return
    echo "node" && return
  fi
  [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ] && echo "python" && return
  [ -f "$dir/go.mod" ] && echo "go" && return
  [ -f "$dir/Cargo.toml" ] && echo "rust" && return
  [ -f "$dir/pom.xml" ] || [ -f "$dir/build.gradle" ] && echo "java" && return
  echo "generic"
}

PROJECT_TYPE=$(detect_project_type "$TARGET")
echo -e "${CYAN}대상 프로젝트:${RESET} $TARGET"
echo -e "${CYAN}설치 모드:${RESET}    $MODE"
echo -e "${CYAN}프로젝트 타입:${RESET} $PROJECT_TYPE (자동 감지)"
echo ""

# ── 프리플라이트 ──────────────────────────────────────────────────────
preflight() {
  echo -e "${BOLD}프리플라이트 — 의존성 검사${RESET}"
  local warn=0

  command -v git >/dev/null 2>&1 && \
    echo -e "  ${GREEN}✓${RESET} git" || \
    { echo -e "  ${RED}✗${RESET} git 없음"; warn=1; }

  command -v gh >/dev/null 2>&1 && \
    echo -e "  ${GREEN}✓${RESET} gh (Draft PR 생성)" || \
    echo -e "  ${YELLOW}⚠️${RESET}  gh 없음 — release Agent PR 생성 불가 (https://cli.github.com)"

  case "$PROJECT_TYPE" in
    nextjs|react|react-native|node)
      command -v node >/dev/null 2>&1 && \
        echo -e "  ${GREEN}✓${RESET} node $(node -v)" || \
        { echo -e "  ${RED}✗${RESET} node 없음"; warn=1; }
      ;;
    python)
      command -v python3 >/dev/null 2>&1 && \
        echo -e "  ${GREEN}✓${RESET} python3" || \
        { echo -e "  ${RED}✗${RESET} python3 없음"; warn=1; }
      ;;
    go)
      command -v go >/dev/null 2>&1 && \
        echo -e "  ${GREEN}✓${RESET} go" || \
        { echo -e "  ${RED}✗${RESET} go 없음"; warn=1; }
      ;;
    rust)
      command -v cargo >/dev/null 2>&1 && \
        echo -e "  ${GREEN}✓${RESET} cargo" || \
        { echo -e "  ${RED}✗${RESET} cargo 없음"; warn=1; }
      ;;
  esac

  # release base 브랜치 후보
  if [ -d "$TARGET/.git" ]; then
    local BASE=""
    for c in develop alpha beta staging dev; do
      (cd "$TARGET" && git show-ref --verify --quiet "refs/heads/$c" 2>/dev/null) \
        || (cd "$TARGET" && git show-ref --verify --quiet "refs/remotes/origin/$c" 2>/dev/null) \
        && { BASE="$c"; break; } || true
    done
    [ -n "$BASE" ] && \
      echo -e "  ${GREEN}✓${RESET} release base 후보: ${BOLD}$BASE${RESET}" || \
      echo -e "  ${YELLOW}⚠️${RESET}  develop/alpha/beta 브랜치 없음 — release 시 사용자 명시 필요"
  fi

  [ "$warn" -eq 1 ] && \
    echo -e "  ${YELLOW}일부 의존성 누락${RESET}" || \
    echo -e "  ${GREEN}핵심 의존성 충족${RESET}"
  echo ""
}

# doctor 모드
if [ "$MODE" = "doctor" ]; then
  preflight; exit 0
fi

# 제거 모드
if [ "$MODE" = "uninstall" ]; then
  if [ ! -d "$CLAUDE_DIR" ]; then
    echo -e "${YELLOW}⚠️  .claude 디렉토리가 없습니다.${RESET}"; exit 0
  fi
  echo -e "${YELLOW}⚠️  AI-Harness 파일을 제거합니다.${RESET}"
  read -p "$(echo -e ${YELLOW}계속할까요? \[y/N\]${RESET}) " -n 1 -r; echo ""
  [[ ! $REPLY =~ ^[Yy]$ ]] && { echo "취소됨."; exit 0; }

  for agent in input-refiner planner implementer functional-qa design-qa visual-qa tracking-implementer tracking-qa release; do
    rm -f "$CLAUDE_DIR/agents/$agent.md"
  done
  rm -rf "$CLAUDE_DIR/skills/implement" "$CLAUDE_DIR/skills/harness-init-claude-md"
  rm -f "$CLAUDE_DIR/rules/coding-behavior.md" "$CLAUDE_DIR/rules/handoff-contract.md" \
        "$CLAUDE_DIR/rules/protected-files.md" "$CLAUDE_DIR/rules/project-patterns.md"
  rm -f "$CLAUDE_DIR/hooks/harness-"*.sh
  rm -f "$CLAUDE_DIR/scripts/generate-claude-md.sh" "$CLAUDE_DIR/scripts/claude-md-manifest.tsv"
  rmdir "$CLAUDE_DIR/scripts" 2>/dev/null || true
  echo -e "${GREEN}✓ 제거 완료 (생성된 CLAUDE.md는 보존)${RESET}"
  exit 0
fi

# 백업 (install 모드)
if [ "$MODE" = "install" ] && [ -d "$CLAUDE_DIR" ]; then
  HAS_EXISTING=false
  for d in agents skills rules hooks; do
    [ -d "$CLAUDE_DIR/$d" ] && [ "$(ls -A "$CLAUDE_DIR/$d" 2>/dev/null)" ] && { HAS_EXISTING=true; break; } || true
  done
  if [ "$HAS_EXISTING" = true ]; then
    BACKUP="$CLAUDE_DIR/_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP"
    for d in agents skills rules hooks; do
      [ -d "$CLAUDE_DIR/$d" ] && cp -r "$CLAUDE_DIR/$d" "$BACKUP/" 2>/dev/null || true
    done
    echo -e "${BLUE}💾 백업:${RESET} $BACKUP"
    echo ""
  fi
fi

# 디렉토리 생성
mkdir -p "$CLAUDE_DIR/agents" "$CLAUDE_DIR/skills" \
         "$CLAUDE_DIR/rules" "$CLAUDE_DIR/hooks" "$CLAUDE_DIR/scripts" \
         "$CLAUDE_DIR/refined-inputs" "$CLAUDE_DIR/plans" "$CLAUDE_DIR/qa-reports"

echo -e "${BOLD}설치 중...${RESET}"

# Agents
for agent in input-refiner planner implementer functional-qa design-qa visual-qa tracking-implementer tracking-qa release; do
  [ -f "$PLUGIN_DIR/agents/$agent.md" ] && \
    cp "$PLUGIN_DIR/agents/$agent.md" "$CLAUDE_DIR/agents/" && \
    echo -e "  ${GREEN}✓${RESET} agents/$agent.md" || true
done

# Skills
for skill in implement harness-init-claude-md; do
  [ -f "$PLUGIN_DIR/skills/$skill/SKILL.md" ] && \
    mkdir -p "$CLAUDE_DIR/skills/$skill" && \
    cp "$PLUGIN_DIR/skills/$skill/SKILL.md" "$CLAUDE_DIR/skills/$skill/" && \
    echo -e "  ${GREEN}✓${RESET} skills/$skill/SKILL.md" || true
done

# Rules
for rule in coding-behavior handoff-contract protected-files project-patterns; do
  [ -f "$PLUGIN_DIR/rules/$rule.md" ] && \
    cp "$PLUGIN_DIR/rules/$rule.md" "$CLAUDE_DIR/rules/" && \
    echo -e "  ${GREEN}✓${RESET} rules/$rule.md" || true
done

# Scripts
[ -f "$PLUGIN_DIR/scripts/generate-claude-md.sh" ] && \
  cp "$PLUGIN_DIR/scripts/generate-claude-md.sh" "$CLAUDE_DIR/scripts/" && \
  chmod +x "$CLAUDE_DIR/scripts/generate-claude-md.sh" && \
  echo -e "  ${GREEN}✓${RESET} scripts/generate-claude-md.sh" || true
[ -f "$PLUGIN_DIR/scripts/claude-md-manifest.tsv" ] && \
  cp "$PLUGIN_DIR/scripts/claude-md-manifest.tsv" "$CLAUDE_DIR/scripts/" || true

# Hooks
for hook in harness-session-start harness-pre-bash-guard harness-pre-impact-check harness-post-ui-check harness-claude-md-lint harness-session-stop harness-pre-compact; do
  [ -f "$PLUGIN_DIR/hooks/$hook.sh" ] && \
    cp "$PLUGIN_DIR/hooks/$hook.sh" "$CLAUDE_DIR/hooks/" && \
    chmod +x "$CLAUDE_DIR/hooks/$hook.sh" && \
    echo -e "  ${GREEN}✓${RESET} hooks/$hook.sh ${CYAN}(executable)${RESET}" || true
done

# project_type 캐시
echo "$PROJECT_TYPE" > "$CLAUDE_DIR/project-type.txt"
echo -e "  ${GREEN}✓${RESET} .claude/project-type.txt ($PROJECT_TYPE)"

# settings.local.json
SETTINGS="$CLAUDE_DIR/settings.local.json"
if [ ! -f "$SETTINGS" ]; then
  cat > "$SETTINGS" <<EOF
{
  "hooks": {
    "SessionStart": [
      { "hooks": [
        { "type": "command", "command": "bash $CLAUDE_DIR/hooks/harness-session-start.sh" }
      ]}
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write", "hooks": [
        { "type": "command", "command": "bash $CLAUDE_DIR/hooks/harness-post-ui-check.sh" },
        { "type": "command", "command": "bash $CLAUDE_DIR/hooks/harness-claude-md-lint.sh" }
      ]}
    ],
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [
        { "type": "command", "command": "bash $CLAUDE_DIR/hooks/harness-pre-bash-guard.sh" }
      ]},
      { "matcher": "Edit", "hooks": [
        { "type": "command", "command": "bash $CLAUDE_DIR/hooks/harness-pre-impact-check.sh" }
      ]}
    ],
    "Stop": [
      { "hooks": [
        { "type": "command", "command": "bash $CLAUDE_DIR/hooks/harness-session-stop.sh" }
      ]}
    ],
    "PreCompact": [
      { "hooks": [
        { "type": "command", "command": "bash $CLAUDE_DIR/hooks/harness-pre-compact.sh" }
      ]}
    ]
  }
}
EOF
  echo -e "  ${GREEN}✓${RESET} settings.local.json ${CYAN}(hooks 자동 등록)${RESET}"
else
  echo -e "  ${YELLOW}⚠️${RESET}  settings.local.json 이미 존재 — hooks 수동 등록 필요"
fi

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}║       ✓ AI-Harness 설치 완료                     ║${RESET}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${RESET}"
echo ""
preflight

# 계층 CLAUDE.md 생성
if [ "$CLAUDE_MD" != "skip" ] && [ -f "$CLAUDE_DIR/scripts/generate-claude-md.sh" ]; then
  echo -e "${BOLD}계층 CLAUDE.md 생성 (파일당 ≤130줄, 기존 파일 보존)${RESET}"
  if [ "$CLAUDE_MD" = "ai" ] && ! command -v claude >/dev/null 2>&1; then
    echo -e "  ${BLUE}ℹ️${RESET}  claude CLI 없음 — 스켈레톤으로 생성 (나중에 ${BOLD}/harness-init-claude-md${RESET} 로 AI 보강)"
  fi
  AI_FLAG=""; [ "$CLAUDE_MD" = "skeleton" ] && AI_FLAG="--no-ai"
  bash "$CLAUDE_DIR/scripts/generate-claude-md.sh" \
    --manifest "$CLAUDE_DIR/scripts/claude-md-manifest.tsv" \
    --project-type "$PROJECT_TYPE" \
    $AI_FLAG "$TARGET" || true
fi

echo ""
echo -e "${BOLD}다음 단계:${RESET}"
echo ""
echo -e "  ${CYAN}1.${RESET} Claude Code 재시작 (skill 스캔)"
echo ""
echo -e "  ${CYAN}2.${RESET} 명령:"
echo -e "     ${BOLD}/implement${RESET} <자연어 input 1~5줄>"
echo ""
echo -e "  ${CYAN}3.${RESET} 예시 ($PROJECT_TYPE):"
case "$PROJECT_TYPE" in
  nextjs)       echo -e "     ${PURPLE}/implement 로그인 페이지 비밀번호 찾기 기능 추가${RESET}" ;;
  react-native) echo -e "     ${PURPLE}/implement 설정 화면 알림 토글 UI 추가${RESET}" ;;
  python)       echo -e "     ${PURPLE}/implement 사용자 목록 API에 페이지네이션 추가${RESET}" ;;
  go)           echo -e "     ${PURPLE}/implement /api/users 엔드포인트 rate limiting 추가${RESET}" ;;
  *)            echo -e "     ${PURPLE}/implement <원하는 기능이나 버그 수정 설명>${RESET}" ;;
esac
echo ""
echo -e "  ${CYAN}4.${RESET} 제거: ${PURPLE}./install.sh --uninstall $TARGET${RESET}"
echo ""
