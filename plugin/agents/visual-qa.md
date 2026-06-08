---
name: visual-qa
description: 시각 회귀 검증. Storybook/Playwright/스냅샷 등 프로젝트 도구에 맞게 자동 선택. 픽셀 diff ≤ 임계값 · Agent 5.
tools: [Read, Grep, Glob, Bash, Write]
model: sonnet
---

# Agent 5 · visual-qa (Dynamic Execution Gate)

UI 변경이 없는 작업(API only, CLI tool 등)이면 전체 skip.
있는 경우 프로젝트 테스트 도구에 맞게 검증 방법을 자동 선택.

## 입력
- plan R3 (디자인 스펙) — 없으면 Figma 없는 경우
- 변경된 UI 컴포넌트/화면 목록 (plan R9)

## 검증 도구 자동 선택

```bash
detect_visual_tool() {
  # Storybook
  grep -q '"storybook"' package.json 2>/dev/null && \
    grep -q '"storybook:test"' package.json 2>/dev/null && \
    echo "storybook" && return

  # Playwright
  [ -f "playwright.config.*" ] && echo "playwright" && return

  # Jest snapshot (React Native / React)
  grep -q '"jest"' package.json 2>/dev/null && echo "jest-snapshot" && return

  # Python: pytest-screenshot
  [ -f "pyproject.toml" ] && grep -q 'pytest-screenshot\|syrupy' pyproject.toml 2>/dev/null && \
    echo "pytest-screenshot" && return

  echo "manual"
}
```

## 검증 실행

### storybook
```bash
yarn storybook:test
# 픽셀 diff 임계값: 0.1%
```

### playwright
```bash
npx playwright test --update-snapshots=false
```

### jest-snapshot
```bash
npx jest --testPathPattern="<변경 컴포넌트>" --ci
```

### manual (도구 없는 경우)
리포트에 "수동 시각 확인 필요" + 스크린샷 경로 안내 출력.
실패로 처리하지 않되 visual-qa 리포트에 "도구 미설치" 명시.

## Contract Probe (옵션 — `data-verify-*` 부착된 컴포넌트만)

implementer가 `data-verify-unit` attribute와 invariants 파일을 생성한 컴포넌트에만 적용:

```bash
# DOM에 publish된 contract를 읽어 invariants 실행
for inv_file in src/**/*.invariants.*; do
  node -e "
    const { invariants } = require('./$inv_file');
    // Playwright에서 data-verify-* 읽어 실행
  "
done
```

부재 시: 이 절 skip (강제 아님).

## 출력 — `.claude/qa-reports/visual-<YYYYMMDD>.md`

```markdown
# Visual QA Report — <task> · <date>
- 결과: ❌ N건 | ✅ pass
- 사용한 도구: <storybook|playwright|jest-snapshot|manual>

## 회귀 감지 (N건)
- <컴포넌트>: diff <X>% (임계값 0.1% 초과)

## Contract 검증 (해당 시)
- <컴포넌트>: invariant <id> — <결과>
```

## 핸드오프

✓ pass → Agent 6 · tracking-implementer (트래킹 계획 있는 경우) / Agent 8 · release
✗ fail → implementer(S2) 재진입
