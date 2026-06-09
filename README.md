# AI-Harness · Universal Multi-Agent Pipeline

> One natural-language prompt → 9 agents run automatically → Draft PR  
> Works with Next.js · React Native · Python · Go · Rust · any framework

[한국어](#한국어) | [English](#english)

---

## English

### Overview

AI-Harness is a multi-agent development pipeline for Claude Code. Describe a task in plain language and 9 specialized agents handle planning, implementation, 6-gate QA, and Draft PR creation automatically.

### Install via Claude Code plugin marketplace

```
/plugin marketplace add https://github.com/project-hh-com/AI-Harness
/plugin install ai-harness@ai-harness
```

After installation, restart Claude Code to activate the `/implement` command.

### Install via script (local project)

```bash
# Run from your project root
bash /path/to/AI-Harness/install/install.sh

# Or specify a path
bash /path/to/AI-Harness/install/install.sh /path/to/your-project
```

### Generate layered CLAUDE.md (recommended after install)

```
/harness-init-claude-md
```

Analyzes your project structure and auto-generates per-layer `CLAUDE.md` files so agents learn your project's patterns.

### Usage

```
# New feature
/implement Add avatar upload to user profile page

# With Figma spec
/implement Update checkout button design
Figma: https://www.figma.com/design/xxx/?node-id=172:61

# Bug fix
/implement login page password reset button not working
area=src/pages/auth type=bugfix
```

### Pipeline

```
/implement <input>
      │
      ▼ 0. input-refiner   — normalize input + detect project_type
      ▼ 1. planner (Opus)  — 11-step analysis → plan file
      ▼ 2. implementer     — write code in waves (S2 long-lived)
      ▼ 3. functional-qa   — Lint / Type / Pattern / TDAD / Complexity / Impact Radius
      ▼ 4. design-qa       — Figma 4-axis check (optional)
      ▼ 5. visual-qa       — snapshot regression (optional)
      ▼ 6. tracking-impl   — replace TRACK markers (optional)
      ▼ 7. tracking-qa     — zero new external SDK calls (optional)
      ▼ 8. release         — create Draft PR
```

### 6-Gate QA

| Gate | What it checks | On fail |
|---|---|---|
| 1. Lint | Project lint command | Re-enter implementer |
| 2. Type Check | tsc / mypy / go vet / cargo check | Re-enter implementer |
| 3. Pattern | Forbidden pattern grep + custom rules | Re-enter implementer |
| 4. TDAD Test | Pass the failing tests planner wrote | Re-enter implementer |
| 5. Static Complexity | Function ≤20 lines, nesting ≤3, params ≤3 | Re-enter implementer |
| 6. **Impact Radius** | All files importing the changed module | Re-enter implementer |

Gate 6 automatically detects infinite-call loops, cache key collisions, and duplicate interceptor registration when shared hooks, stores, or API clients are modified.

### Supported Stacks

**JavaScript / TypeScript**

| Stack | Auto-detected by | Lint | Test |
|---|---|---|---|
| Next.js | `"next"` in package.json | `next lint` | `jest` / `vitest` |
| React Native | `"expo"` in package.json | `eslint` | `jest` |
| React | `"react"` in package.json | `eslint` | `jest` / `vitest` |
| Vue | `"vue"` in package.json | `eslint` | `vitest` |
| Nuxt | `"nuxt"` in package.json | `eslint` | `vitest` |
| Angular | `"@angular/core"` in package.json | `ng lint` | `ng test` |
| Svelte | `"svelte"` in package.json | `eslint` | `vitest` |
| Astro | `"astro"` in package.json | `eslint` | `vitest` |
| Remix | `"remix"` in package.json | `eslint` | `vitest` |
| Gatsby | `"gatsby"` in package.json | `eslint` | `jest` |
| Electron | `"electron"` in package.json | `eslint` | `jest` |
| Node (server) | `express`/`fastify`/`koa` in package.json | `eslint` | `jest` / `vitest` |
| Node | `package.json` (fallback) | `eslint` | `jest` / `vitest` |

**Python**

| Stack | Auto-detected by | Lint | Test |
|---|---|---|---|
| Django | `manage.py` or `django` in requirements | `ruff` / `flake8` | `pytest` / `manage.py test` |
| Flask | `flask` in requirements | `ruff` / `flake8` | `pytest` |
| FastAPI | `fastapi` in requirements | `ruff` / `flake8` | `pytest` |
| Python (generic) | `pyproject.toml` / `setup.py` | `ruff` / `flake8` | `pytest` |

**Go / Rust**

| Stack | Auto-detected by | Lint | Test |
|---|---|---|---|
| Go | `go.mod` | `golangci-lint` | `go test ./...` |
| Rust | `Cargo.toml` | `cargo clippy` | `cargo test` |

**JVM**

| Stack | Auto-detected by | Lint | Test |
|---|---|---|---|
| Spring Boot | `spring-boot` in pom.xml/build.gradle | `checkstyle` | `mvn test` / `gradle test` |
| Java (Maven) | `pom.xml` | `checkstyle` | `mvn test` |
| Java (Gradle) | `build.gradle` | `checkstyle` | `gradle test` |
| Kotlin JVM | `kotlin` in build.gradle | `ktlint` | `gradle test` |
| Android Kotlin | `com.android` + `kotlin` in build.gradle | `ktlint` + `lint` | `gradle testDebugUnitTest` |
| Android Java | `com.android` in build.gradle | `lint` | `gradle testDebugUnitTest` |
| JSP / Servlet | `javax.servlet` in pom.xml | `checkstyle` | `mvn test` |

**Ruby / PHP**

| Stack | Auto-detected by | Lint | Test |
|---|---|---|---|
| Rails | `rails` in Gemfile | `rubocop` | `rspec` / `rails test` |
| Sinatra | `sinatra` in Gemfile | `rubocop` | `rspec` |
| Ruby | `Gemfile` | `rubocop` | `rspec` |
| Laravel | `laravel` in composer.json | `phpstan` | `phpunit` |
| Symfony | `symfony` in composer.json | `phpstan` | `phpunit` |
| WordPress | `wp-config.php` / composer | `phpcs` | `phpunit` |
| PHP (generic) | `composer.json` | `phpcs` | `phpunit` |

**Other Platforms**

| Stack | Auto-detected by | Lint | Test |
|---|---|---|---|
| .NET / ASP.NET | `*.csproj` / `*.sln` | `dotnet format` | `dotnet test` |
| Blazor | `.csproj` with Blazor | `dotnet format` | `dotnet test` |
| Swift / iOS | `Package.swift` / `*.xcodeproj` | `swiftlint` | `swift test` |
| Flutter | `pubspec.yaml` + `flutter` | `flutter analyze` | `flutter test` |
| Dart | `pubspec.yaml` | `dart analyze` | `dart test` |
| Phoenix | `mix.exs` + `phoenix` | `mix credo` | `mix test` |
| Elixir | `mix.exs` | `mix credo` | `mix test` |
| Haskell | `stack.yaml` / `cabal.project` | `hlint` | `stack test` |
| C++ (CMake) | `CMakeLists.txt` | `clang-tidy` | `ctest` |
| C++ (Make) | `Makefile` + `.cpp` | `clang-tidy` | `make test` |
| C (Make) | `Makefile` | `clang-tidy` | `make test` |
| Terraform | `*.tf` files | `terraform fmt -check` | `terraform validate` |

### Safety Guardrails

- **Protected files** — blocks edits to `next.config.*`, `.github/workflows/**`, `package.json`, etc.
- **Protected branches** — blocks direct push to `main` / `master` / `prd` / `production`
- **PR base** — auto-detects `develop → alpha → beta → staging → dev` (prd target permanently blocked)
- **Infinite-call prevention** — validates SWR / React Query cache key patterns
- **Duplicate interceptor detection** — catches double-registered axios/fetch interceptors

### Uninstall

```bash
bash /path/to/AI-Harness/install/install.sh --uninstall /path/to/your-project
```

Only removes AI-Harness files. Existing `.claude/` assets are preserved.

### Full guide

Open `docs/guide.html` in a browser for the interactive visual guide.

---

## 한국어

> 자연어 한 줄 → 9개 에이전트 자동 실행 → Draft PR  
> Next.js · React Native · Python · Go · Rust · 모든 프레임워크 지원

### 마켓플레이스로 설치

```
/plugin marketplace add https://github.com/project-hh-com/AI-Harness
/plugin install ai-harness@ai-harness
```

설치 후 Claude Code를 재시작하면 `/implement` 명령이 활성화됩니다.

### 스크립트로 설치 (로컬 프로젝트)

```bash
# 대상 프로젝트 루트에서 실행
bash /path/to/AI-Harness/install/install.sh

# 또는 경로 지정
bash /path/to/AI-Harness/install/install.sh /path/to/your-project
```

### 설치 후 CLAUDE.md 생성 (권장)

```
/harness-init-claude-md
```

프로젝트 구조를 분석해 레이어별 CLAUDE.md를 자동 생성합니다.

### 사용법

```
# 새 기능
/implement 사용자 프로필 페이지에 아바타 업로드 기능 추가

# Figma 포함
/implement 결제 버튼 디자인 변경
Figma: https://www.figma.com/design/xxx/?node-id=172:61

# 버그픽스
/implement login page password reset button not working
area=src/pages/auth type=bugfix
```

### 파이프라인

```
/implement <input>
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

### QA 게이트 (6단계)

| Gate | 내용 | 실패 시 |
|---|---|---|
| 1. Lint | 프로젝트 lint 명령 | implementer 재진입 |
| 2. Type Check | tsc / mypy / go vet | implementer 재진입 |
| 3. Pattern | 프로젝트 금지 패턴 grep | implementer 재진입 |
| 4. TDAD Test | planner가 작성한 실패 테스트 통과 | implementer 재진입 |
| 5. Static Complexity | 함수 ≤20줄, 중첩 ≤3, 파라미터 ≤3 | implementer 재진입 |
| 6. **Impact Radius** | 변경 모듈을 import하는 모든 파일 검증 | implementer 재진입 |

Gate 6은 SWR 훅 · 전역 스토어 · API 클라이언트 변경 시 무한 호출 · 캐시 키 충돌 · 인터셉터 중복 등을 자동 탐지합니다.

### 지원 스택

**JavaScript / TypeScript**: Next.js, React Native, React, Vue, Nuxt, Angular, Svelte, Astro, Remix, Gatsby, Electron, Node.js (server/generic)

**Python**: Django, Flask, FastAPI, Python (generic)

**Go / Rust**: Go, Rust

**JVM**: Spring Boot, Java (Maven/Gradle), Kotlin JVM, Android Kotlin, Android Java, JSP/Servlet

**Ruby / PHP**: Rails, Sinatra, Ruby, Laravel, Symfony, WordPress, PHP (generic)

**기타**: .NET/ASP.NET/Blazor, Swift/iOS, Flutter, Dart, Phoenix, Elixir, Haskell, C++/CMake, C, Terraform

모든 스택은 프로젝트 파일(`package.json`, `pom.xml`, `go.mod`, `Cargo.toml` 등)을 분석해 자동 감지됩니다.

### 안전 보호 장치

- **보호 파일** — `next.config.*`, `.github/workflows/**`, `package.json` 등 설정 파일 편집 차단
- **보호 브랜치** — `main` / `master` / `prd` / `production` 직접 push 차단
- **PR 베이스** — `develop → alpha → beta → staging → dev` 자동 감지 (prd 타겟 영구 금지)
- **무한 호출 방지** — SWR/React Query 캐시 키 패턴 검증
- **인터셉터 중복 감지** — axios/fetch 인터셉터 중복 등록 자동 탐지

### 설치 구조

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

### 제거

```bash
bash /path/to/AI-Harness/install/install.sh --uninstall /path/to/your-project
```

AI-Harness 파일만 제거합니다. 기존 `.claude/` 자산은 보존됩니다.

### 전체 가이드

`docs/guide.html`을 브라우저에서 열면 인터랙티브 시각 가이드를 볼 수 있습니다.
