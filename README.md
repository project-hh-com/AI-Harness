# AI-Harness · Universal Multi-Agent Pipeline

> 자연어 한 줄 → 9개 에이전트 자동 실행 → Draft PR  
> Next.js · React Native · Python · Go · Rust · 모든 프레임워크 지원

---

## 한 눈에 보기

```
/implement <자연어 input>
      │
      ▼ 0. input-refiner   — 표준 input 정제 + project_type 감지
      ▼ 1. planner (Opus)  — 11 steps 분석 → plan 파일 생성
      ▼ 2. implementer     — wave 단위 코드 작성 (S2 long-lived)
      ▼ 3. functional-qa   — Lint / Type / Pattern / TDAD / Complexity / Impact Radius
      ▼ 4. design-qa       — Figma 4축 검증 (선택)
      ▼ 5. visual-qa       — 스냅샷 회귀 검증 (선택)
      ▼ 6. tracking-impl   — 트래킹 마커 치환 (선택)
      ▼ 7. tracking-qa     — 외부 SDK 신규 호출 0 검증 (선택)
      ▼ 8. release         — Draft PR 생성
```

---

## 설치

```bash
# 대상 프로젝트 루트에서 실행
bash /path/to/dev-agent/install/install.sh

# 또는 경로 지정
bash /path/to/dev-agent/install/install.sh /path/to/your-project
```

설치 후 Claude Code를 재시작하면 `/implement` 명령이 활성화됩니다.

### 설치 후 CLAUDE.md 생성 (권장)

```
/harness-init-claude-md
```

프로젝트 구조를 분석해 레이어별 CLAUDE.md를 자동 생성합니다.

---

## 사용법

```
# 기본
/implement 사용자 프로필 페이지에 아바타 업로드 기능 추가

# Figma 포함
/implement 결제 버튼 디자인 변경
Figma: https://www.figma.com/design/xxx/?node-id=172:61

# 버그픽스
/implement login page password reset button not working
area=src/pages/auth type=bugfix
```

---

## 지원 스택

| 언어/프레임워크 | 자동 감지 기준 | Lint | Test |
|---|---|---|---|
| Next.js | `"next"` in package.json | `next lint` | `jest` / `vitest` |
| React Native | `"expo"` in package.json | `eslint` | `jest` |
| React | `"react"` in package.json | `eslint` | `jest` / `vitest` |
| Python | `pyproject.toml` / `requirements.txt` | `ruff` / `flake8` | `pytest` |
| Go | `go.mod` | `golangci-lint` | `go test ./...` |
| Rust | `Cargo.toml` | `cargo clippy` | `cargo test` |
| Java | `pom.xml` / `build.gradle` | `checkstyle` | `mvn test` |
| Node | `package.json` | `eslint` | `jest` / `vitest` |

---

## QA 게이트 (6단계)

| Gate | 내용 | 실패 시 |
|---|---|---|
| 1. Lint | 프로젝트 lint 명령 | implementer 재진입 |
| 2. Type Check | tsc / mypy / go vet | implementer 재진입 |
| 3. Pattern | 프로젝트 금지 패턴 grep | implementer 재진입 |
| 4. TDAD Test | planner가 작성한 실패 테스트 통과 | implementer 재진입 |
| 5. Static Complexity | 함수 ≤20줄, 중첩 ≤3, 파라미터 ≤3 | implementer 재진입 |
| 6. **Impact Radius** | 변경 모듈을 import하는 모든 파일 검증 | implementer 재진입 |

Gate 6은 SWR 훅 · 전역 스토어 · API 클라이언트 변경 시 무한 호출 · 캐시 키 충돌 · 인터셉터 중복 등을 자동 탐지합니다.

---

## 설치 구조

```
your-project/.claude/
├── agents/           — 9개 에이전트 (md 파일)
├── skills/           — /implement, /harness-init-claude-md
├── rules/            — coding-behavior, handoff-contract, protected-files
├── hooks/            — 7개 가드레일 셸 스크립트
├── scripts/          — generate-claude-md.sh, check-patterns.sh
├── plans/            — planner 산출 누적
├── refined-inputs/   — input-refiner 산출 누적
└── qa-reports/       — QA 리포트 누적
```

---

## 안전 보호 장치

- **보호 파일**: `next.config.*`, `.github/workflows/**`, `package.json` 등 설정 파일 편집 차단
- **보호 브랜치**: `main` / `master` / `prd` / `production` 직접 push 차단
- **PR 베이스**: `develop → alpha → beta → staging → dev` 자동 감지 (prd 타겟 영구 금지)
- **인터셉터 중복**: API 클라이언트 변경 시 중복 등록 자동 감지
- **무한 호출 방지**: SWR/React Query 캐시 키 패턴 검증

---

## 전체 가이드

```bash
open /path/to/dev-agent/docs/guide.html
```

---

## 제거

```bash
bash /path/to/dev-agent/install/install.sh --uninstall /path/to/your-project
```

v7 파일만 제거합니다. 기존 `.claude/` 자산은 보존됩니다.
