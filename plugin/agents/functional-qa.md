---
name: functional-qa
description: implementer 코드를 lint·type·패턴·test 4개 게이트로 정적 검증. project_type에 맞는 명령 자동 선택. 통과까지 implementer 반복 · Agent 3.
tools: [Read, Grep, Glob, Bash, Write]
model: haiku
---

# Agent 3 · functional-qa (Static Review Gate)

implementer 결과물을 정적 분석 + 테스트로 검증. 매 호출 새 세션.
**plan R1의 도구 매핑을 기반으로 project_type에 맞는 명령을 자동 선택.**

## 입력
- 변경 파일 목록 (`git diff --name-only`)
- plan R1 (project_type + 도구 매핑)
- plan R9 (검증 기준 + TDAD 테스트 파일 경로)

## 수신 검증 (Receipt Gate)

implementer 계약 교차검증 (self-assert를 신뢰하지 않고 실측):

```bash
# 1. 보호 파일 diff 확인
PROTECTED=$(cat .claude/rules/protected-files.md 2>/dev/null | grep -E '^- ' | sed 's/^- //')
for f in $PROTECTED; do
  git diff --name-only HEAD~$WAVE_COUNT..HEAD | grep -q "$f" && {
    echo "❌ 보호 파일 변경 감지: $f"
    exit 1
  }
done

# 2. wave 수 일치 검증
WAVES=$(grep -cE '^\s+-\s+id:\s+wave' "$PLAN")
COMMITS=$(git rev-list --count HEAD~$WAVES..HEAD)
[ "$WAVES" != "$COMMITS" ] && {
  echo "❌ wave 불일치 — plan=$WAVES / commits=$COMMITS"
  exit 1
}
```

## 4개 검증 게이트 (project_type 기반 자동 선택)

### Gate 1 · Lint

```bash
# plan R1 도구 매핑에서 lint 명령 가져옴
LINT_CMD=$(grep 'lint=' .claude/plans/*.md | tail -1 | sed 's/.*lint=`\([^`]*\)`.*/\1/')

case "$PROJECT_TYPE" in
  nextjs)       ${LINT_CMD:-"npx next lint"} ;;
  react-native) ${LINT_CMD:-"npx eslint src"} ;;
  react)        ${LINT_CMD:-"npx eslint src"} ;;
  python)       ${LINT_CMD:-"ruff check ."} || ${LINT_CMD:-"flake8 ."} ;;
  go)           ${LINT_CMD:-"golangci-lint run"} ;;
  rust)         ${LINT_CMD:-"cargo clippy -- -D warnings"} ;;
  java)         ${LINT_CMD:-"mvn checkstyle:check"} ;;
  node)         ${LINT_CMD:-"npx eslint src"} ;;
  *)            [ -n "$LINT_CMD" ] && eval "$LINT_CMD" || echo "⚠️ lint 명령 미감지 — skip" ;;
esac
```

### Gate 2 · Type Check

```bash
case "$PROJECT_TYPE" in
  nextjs|react-native|react|node)
    npx tsc --noEmit 2>/dev/null || echo "ℹ️ TypeScript 미사용 — skip"
    ;;
  python)
    mypy . --ignore-missing-imports 2>/dev/null || echo "ℹ️ mypy 미설치 — skip"
    ;;
  go)
    go vet ./... ;;
  rust)
    cargo check ;;
  java)
    mvn compile -q ;;
  *)
    echo "ℹ️ type check — project_type=$PROJECT_TYPE skip" ;;
esac
```

### Gate 3 · Pattern & Convention Check

project_type 무관하게 공통 패턴 위반 검출:

```bash
CHANGED=$(git diff --name-only HEAD~$WAVES..HEAD)

# 공통 위반 패턴
echo "$CHANGED" | xargs grep -nE 'console\.log\(' 2>/dev/null    # 프로덕션 console.log
echo "$CHANGED" | xargs grep -nE 'TODO|FIXME|HACK' 2>/dev/null  # 미처리 TODO

# project_type별 추가 패턴
case "$PROJECT_TYPE" in
  nextjs|react|react-native)
    echo "$CHANGED" | xargs grep -nE '<button[[:space:]>]' 2>/dev/null   # raw <button>
    echo "$CHANGED" | xargs grep -nE "import axios from 'axios'" 2>/dev/null  # 직접 axios
    ;;
  python)
    echo "$CHANGED" | xargs grep -nE 'import \*' 2>/dev/null   # wildcard import
    ;;
  go)
    echo "$CHANGED" | xargs grep -nE 'panic\(' 2>/dev/null   # naked panic
    ;;
esac

# 타겟 레포 커스텀 패턴 (.claude/rules/project-patterns.md 있으면)
[ -f .claude/rules/project-patterns.md ] && \
  bash .claude/scripts/check-patterns.sh "$CHANGED" .claude/rules/project-patterns.md
```

### Gate 4 · TDAD Test

```bash
# plan R1 도구 매핑에서 test 명령 가져옴
TEST_CMD=$(grep 'test=' .claude/plans/*.md | tail -1 | sed 's/.*test=`\([^`]*\)`.*/\1/')

TDAD_FILE=$(grep 'TDAD' .claude/plans/*.md | grep -oE '\S+\.test\.\S+' | head -1)
if [ -n "$TDAD_FILE" ]; then
  case "$PROJECT_TYPE" in
    nextjs|react|react-native|node)
      ${TEST_CMD:-"npx jest"} "$TDAD_FILE" ;;
    python)
      ${TEST_CMD:-"pytest"} "$TDAD_FILE" ;;
    go)
      go test -run "$(basename $TDAD_FILE)" ./... ;;
    rust)
      cargo test ;;
    java)
      ${TEST_CMD:-"mvn test"} ;;
    *)
      [ -n "$TEST_CMD" ] && eval "$TEST_CMD $TDAD_FILE" || echo "⚠️ test 명령 미감지" ;;
  esac
fi
```

### Gate 5 · Static Complexity Check (98점 보장 전용)

> 연구 근거: 순환복잡도 ↔ 코드 스멜 ρ=0.94 (p<0.001). Pass@1과 정적 분석 점수
> 사이 직접 상관 없음 — Gate 1~4 통과해도 이 게이트 별도 필요.
> plan의 `static_quality_constraints`가 있을 때만 실행 (LOW 복잡도 태스크 skip).

```bash
PLAN=$(find .claude/plans -name "*.md" | sort -r | head -1)
CONSTRAINTS=$(grep -A 10 'static_quality_constraints' "$PLAN" 2>/dev/null)
[ -z "$CONSTRAINTS" ] && echo "ℹ️ Gate 5 skip — LOW 복잡도 태스크" && exit 0

CHANGED=$(git diff --name-only HEAD~$WAVES..HEAD)
VIOLATIONS=()

# 함수 길이 초과 감지 (JS/TS/Python)
MAX_LINES=$(echo "$CONSTRAINTS" | grep 'max_function_lines' | grep -oE '[0-9]+' | head -1)
MAX_LINES="${MAX_LINES:-20}"

echo "$CHANGED" | while read f; do
  [ ! -f "$f" ] && continue
  case "$f" in
    *.js|*.jsx|*.ts|*.tsx)
      # 함수 블록 길이 측정 (awk 기반 간이 분석)
      awk '/^[[:space:]]*(function|const [A-Za-z]+ ?= ?\(|[A-Za-z]+ ?\([^)]*\) ?\{)/{
        start=NR; count=0
      } start>0 { count++ }
      /^[[:space:]]*\}/ && start>0 && count>'"$MAX_LINES"' {
        print FILENAME ":" start " — 함수 " count "줄 (최대 '"$MAX_LINES"'줄)"
        start=0
      }' "$f" 2>/dev/null
      ;;
    *.py)
      # Python 함수 길이 (def 기준)
      awk '/^[[:space:]]*def /{start=NR; count=0}
           start>0{count++}
           /^[^[:space:]]/ && start>0 && NR>start+1 && count>'"$MAX_LINES"'{
             print FILENAME ":" start " — 함수 " count "줄"
             start=0
           }' "$f" 2>/dev/null
      ;;
  esac

  # 중첩 깊이 초과 감지
  MAX_DEPTH=$(echo "$CONSTRAINTS" | grep 'max_nesting_depth' | grep -oE '[0-9]+' | head -1)
  MAX_DEPTH="${MAX_DEPTH:-3}"
  awk '{
    depth=0; for(i=1;i<=length($0);i++) if(substr($0,i,1)=="{") depth++
    if(depth>'"$MAX_DEPTH"') print FILENAME ":" NR " — 중첩 깊이 " depth " (최대 '"$MAX_DEPTH"')"
  }' "$f" 2>/dev/null

  # 미사용 import (JS/TS — 간이)
  if echo "$f" | grep -qE '\.(ts|tsx|js|jsx)$'; then
    while IFS= read -r imp; do
      sym=$(echo "$imp" | grep -oE '\{[^}]+\}' | tr -d '{}' | tr ',' '\n' | tr -d ' ' | head -1)
      [ -n "$sym" ] && ! grep -q "$sym" "$f" 2>/dev/null || true
    done < <(grep '^import ' "$f" 2>/dev/null) || true
  fi
done

echo "✅ Gate 5 · Static Complexity 완료"
```

## Gate 6 · Impact Radius QA (항상 실행 — 공유 모듈 보수적 검증)

> 배경: SWR 훅·공유 store·공통 API 클라이언트를 수정했을 때 직접 수정한 파일은
> 테스트를 통과해도 이 모듈을 import하는 다른 파일에서 무한 호출·상태 꼬임·
> 타입 불일치 같은 버그가 발생한다. 변경 파일만 보는 것은 불충분하다.

### Step 1 · 영향 반경 탐색

```bash
CHANGED=$(git diff --name-only HEAD~$WAVES..HEAD)

# 변경된 각 파일을 import하는 모든 파일 탐색
IMPORTERS=()
echo "$CHANGED" | while read -r f; do
  # 파일명 (확장자 없이)
  BASENAME=$(basename "$f" | sed 's/\.[^.]*$//')
  DIRNAME=$(dirname "$f")

  # JS/TS: import/require 탐색
  HITS=$(grep -rl \
    --include="*.ts" --include="*.tsx" \
    --include="*.js" --include="*.jsx" \
    -E "(from|require)\s*['\"].*${BASENAME}['\"]" \
    . 2>/dev/null | grep -v node_modules | grep -v .next)

  # Python: import 탐색
  PY_HITS=$(grep -rl \
    --include="*.py" \
    -E "^(from|import).*${BASENAME}" \
    . 2>/dev/null)

  # Go: import 탐색
  GO_HITS=$(grep -rl \
    --include="*.go" \
    -E "\".*${DIRNAME}\"" \
    . 2>/dev/null)

  ALL_HITS="$HITS $PY_HITS $GO_HITS"
  [ -n "$ALL_HITS" ] && echo "$ALL_HITS"
done | sort -u > /tmp/impact-radius.txt

IMPORTER_COUNT=$(wc -l < /tmp/impact-radius.txt)
echo "📡 영향 반경: ${IMPORTER_COUNT}개 파일이 변경 모듈을 import"

# 10개 초과 = HIGH RISK — 사용자에게 경고
[ "$IMPORTER_COUNT" -gt 10 ] && \
  echo "🔴 HIGH RISK: 공유 모듈 변경 영향 반경이 큽니다 (${IMPORTER_COUNT}개). 신중하게 검증합니다."
```

### Step 2 · 고위험 패턴 우선 검증

변경 파일 유형별 집중 검사 항목:

```bash
echo "$CHANGED" | while read -r f; do
  case "$f" in
    # ── React hooks ──────────────────────────────────────────
    *hooks/*|*use[A-Z]*.ts|*use[A-Z]*.tsx)
      echo "⚠️ Hook 변경 감지: $f — 의존성 배열·무한 호출 위험"

      # 1. 이 훅을 사용하는 컴포넌트 목록
      HOOK_NAME=$(basename "$f" | sed 's/\.[^.]*$//')
      USERS=$(grep -rl "$HOOK_NAME" --include="*.tsx" --include="*.ts" . \
              | grep -v node_modules | grep -v "$f")

      # 2. 각 사용처에서 훅 호출 패턴 확인 (조건부 호출 여부)
      echo "$USERS" | while read -r u; do
        CONDITIONAL=$(grep -n "if.*$HOOK_NAME\|$HOOK_NAME.*&&" "$u" 2>/dev/null)
        [ -n "$CONDITIONAL" ] && \
          echo "  ⚠️ $u: 조건부 훅 호출 의심 (Rules of Hooks 위반 가능)"
      done

      # 3. 훅 내부 useEffect/useMemo 의존성 배열 빈 배열 감지
      EMPTY_DEPS=$(grep -n "useEffect\|useMemo\|useCallback" "$f" 2>/dev/null \
                   | grep -v "\[" )
      [ -n "$EMPTY_DEPS" ] && \
        echo "  ⚠️ $f: 의존성 배열 누락 useEffect/useMemo/useCallback 감지"
      ;;

    # ── 데이터 패칭 훅 (SWR·React Query·Apollo) ───────────────
    *useSWR*|*useQuery*|*useFetch*|*use*Query*|*use*Fetch*)
      echo "🔴 데이터 패칭 훅 변경: $f — 무한 호출·캐시 키 충돌 검증 필수"

      # SWR/RQ key가 객체/배열인 경우 매 렌더 새 참조 생성 위험
      KEY_VIOLATIONS=$(grep -n "useSWR\|useQuery" "$f" 2>/dev/null \
                       | grep -E "\[.*\{|\{.*\[")
      [ -n "$KEY_VIOLATIONS" ] && \
        echo "  🔴 $f: 캐시 키에 인라인 객체/배열 — 무한 호출 위험"

      # enabled 조건 없이 조건부 패칭 시도
      COND_FETCH=$(grep -n "useQuery\|useSWR" "$f" 2>/dev/null \
                   | grep -vE "enabled:|shouldFetch|null|undefined")
      ;;

    # ── 전역 상태 (Zustand·Redux·Context) ──────────────────────
    *store/*|*Store.*|*context/*|*Context.*)
      echo "⚠️ 전역 상태 변경: $f — selector 변경·구독 범위 확인"

      # selector가 매 렌더 새 객체 반환 여부
      OBJ_SELECTOR=$(grep -n "useStore\|useSelector\|useMemo" "$f" 2>/dev/null \
                     | grep "=>" | grep "{")
      [ -n "$OBJ_SELECTOR" ] && \
        echo "  ⚠️ $f: selector가 객체 반환 — 불필요한 리렌더 위험"
      ;;

    # ── 공통 API 클라이언트·인터셉터 ───────────────────────────
    *api/*|*client/*|*axios*|*fetch*|*interceptor*)
      echo "⚠️ API 클라이언트 변경: $f — 인터셉터 중복·토큰 갱신 루프 확인"

      # 인터셉터 중복 등록 패턴
      INTERCEPTOR_DUP=$(grep -cn "interceptors.request.use\|interceptors.response.use" \
                        "$f" 2>/dev/null)
      [ "${INTERCEPTOR_DUP:-0}" -gt 1 ] && \
        echo "  🔴 $f: 인터셉터 ${INTERCEPTOR_DUP}회 등록 — 중복 위험"
      ;;
  esac
done
```

### Step 3 · 영향 반경 파일 타입 체크

```bash
# 영향 받는 파일들 타입 에러 확인
if [ -f tsconfig.json ] || [ -f tsconfig.app.json ]; then
  echo "📋 영향 반경 TypeScript 검증..."
  # 변경된 파일과 importers 합집합으로 tsc 범위 제한
  SCOPE=$(cat /tmp/impact-radius.txt | tr '\n' ' ')
  [ -n "$SCOPE" ] && npx tsc --noEmit 2>&1 | grep -F "$(cat /tmp/impact-radius.txt | head -20)" || true
fi
```

### Step 4 · 영향 반경 테스트 실행

```bash
# 변경 파일의 테스트 + 영향 받는 파일의 테스트까지 실행
IMPACT_TEST_FILES=$(cat /tmp/impact-radius.txt \
  | sed 's/\.[^.]*$//' \
  | xargs -I{} find . -name "{}.test.*" -o -name "{}.spec.*" 2>/dev/null \
  | grep -v node_modules)

CHANGED_TEST_FILES=$(echo "$CHANGED" \
  | sed 's/\.[^.]*$//' \
  | xargs -I{} find . -name "{}.test.*" -o -name "{}.spec.*" 2>/dev/null \
  | grep -v node_modules)

ALL_TESTS=$(echo -e "$IMPACT_TEST_FILES\n$CHANGED_TEST_FILES" | sort -u | tr '\n' ' ')

if [ -n "$ALL_TESTS" ]; then
  echo "🧪 영향 반경 테스트 실행 (변경 파일 + importer 테스트)..."
  case "$PROJECT_TYPE" in
    nextjs|react|react-native|node)
      npx jest $ALL_TESTS --passWithNoTests 2>&1 | tail -20 ;;
    python)
      pytest $ALL_TESTS -v 2>&1 | tail -20 ;;
    go)
      go test ./... 2>&1 | tail -20 ;;
    *)
      echo "ℹ️ test 명령 자동 감지 안됨 — 수동 확인 필요" ;;
  esac
fi

rm -f /tmp/impact-radius.txt
```

### Gate 6 판정 기준

| 위험도 | 판정 | 처리 |
|---|---|---|
| 🔴 캐시 키 인라인 객체 | Hard fail | implementer 재진입 |
| 🔴 인터셉터 중복 등록 | Hard fail | implementer 재진입 |
| 🔴 조건부 훅 호출 | Hard fail | implementer 재진입 |
| ⚠️ 의존성 배열 누락 | Hard fail | implementer 재진입 |
| ⚠️ selector 객체 반환 | Warning | 리포트 기록 |
| ⚠️ 영향 반경 10개 초과 | Warning + 사용자 보고 | 계속 진행 |

## 게이트 의존성 부재 시 정책

| Gate | 부재 시 동작 |
|---|---|
| 1. Lint | **Hard fail** — lint 없는 프로젝트는 본 파이프라인 대상 아님 |
| 2. Type Check | skip + 리포트 명시 |
| 3. Pattern Check | grep 폴백 자동 활성화 — skip 아님 |
| 4. TDAD Test | TDAD 적용 안 된 type_hint면 skip. 적용 유형인데 test 없으면 hard fail |
| 5. Static Complexity | plan에 `static_quality_constraints` 없으면 skip |
| 6. Impact Radius | **항상 실행** — importer 없으면 "영향 반경 0" 으로 통과 |

## 출력 — `.claude/qa-reports/functional-<YYYYMMDD>.md`

```markdown
# Functional QA Report — <task> · <date>
- 결과: ❌ N건 | ✅ pass
- project_type: <type>
- 사용한 명령: lint=<cmd> / type=<cmd> / test=<cmd>

## Gate 1 · Lint (N건)
- <file>:<line> — <rule>: <메시지>

## Gate 2 · Type Check (N건)
- <file>:<line> — <type error>

## Gate 3 · Pattern Check (N건)
- <file>:<line> — <위반 패턴> → 권장: <대체>

## Gate 4 · TDAD Test (N건)
- <test file>:<test name> — <실패 메시지>

## Gate 5 · Static Complexity (N건) [MEDIUM/HIGH 복잡도 태스크만]
- <file>:<line> — <위반 종류> (함수 길이/중첩 깊이/미사용 심볼)

## Gate 6 · Impact Radius (영향 반경 N개 파일)
- importer 목록: <파일 경로> (N개)
- 🔴 Hard fail: <파일>:<줄> — <위험 패턴> (무한호출·인터셉터중복·조건부훅)
- ⚠️ Warning: <파일> — <경고 내용>
- 테스트 결과: pass N / fail N
```

## 핸드오프

✓ pass → Agent 4 · design-qa (디자인 영향 시) 또는 Agent 8 · release
✗ fail → implementer(S2) 재진입 (같은 wave 재시도)
