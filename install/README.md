# v7 AI-Harness 설치 패키지

> 9개 에이전트 멀티 파이프라인을 한 명령으로 Claude Code에 설치.
> 대상 프로젝트의 `.claude/` 디렉토리에 agents · skills · rules · hooks를 자동 배치.

---

## 빠른 시작 (Quick Install)

```bash
# 1. 이 디렉토리로 이동
cd /path/to/front-end-dev-agent/install

# 2. 대상 프로젝트에 설치 (현재 디렉토리 기본)
./install.sh /path/to/your-project

# 또는 현재 디렉토리에 설치
cd /path/to/your-project
/path/to/front-end-dev-agent/install/install.sh

# 3. Claude Code에서 사용
/v7-implement <자연어 input 1~5줄>
```

---

## 무엇이 설치되나

```
your-project/.claude/
├── agents/                          ← 9개 v7 에이전트
│   ├── input-refiner.md             (Agent 0 · 사용자 input 정제)
│   ├── planner.md                   (Agent 1 · 9 steps 분석)
│   ├── implementer.md               (Agent 2 · 코드 작성, S2 long-lived)
│   ├── functional-qa.md             (Agent 3 · lint·type·manifest·yarn test)
│   ├── design-qa.md                 (Agent 4 · Figma 4축)
│   ├── visual-qa.md                 (Agent 5 · snapshot diff)
│   ├── tracking-implementer.md      (Agent 6 · TRACK 마커 치환, S2 이어받음)
│   ├── tracking-qa.md               (Agent 7 · 외부 SDK 신규 0 검증)
│   └── release.md                   (Agent 8 · Draft PR + 자기강화)
├── skills/
│   └── v7-implement/
│       └── SKILL.md                 ← 메인 진입 명령 /v7-implement
├── rules/
│   ├── tracking-policy.md           ← 외부 SDK 신규 금지 정책
│   └── tracking-marker.md           ← TRACK 주석 4가지 컨벤션
├── hooks/                           ← 가드레일 (chmod +x)
│   ├── v7-post-ui-check.sh          (Edit/Write 후 패턴 위반 검출)
│   ├── v7-pre-impact-check.sh       (Edit 전 영향 반경 출력)
│   └── v7-session-stop.sh           (세션 종료 시 통계 + 자기강화 신호)
├── refined-inputs/                  ← input-refiner 산출 누적
├── plans/                           ← planner plan 파일 누적
├── qa-reports/                      ← QA 리포트 누적
└── settings.local.json              ← hooks 자동 등록 (없을 때만 생성)
```

---

## 설치 옵션

```bash
./install.sh                         # 현재 디렉토리에 설치
./install.sh /path/to/project        # 특정 프로젝트에 설치
./install.sh --uninstall [경로]      # 제거
./install.sh --update [경로]         # 백업 없이 덮어쓰기
./install.sh --help                  # 도움말

# 단축
./uninstall.sh [경로]                # 제거 alias
```

---

## 기존 settings.local.json이 있는 경우

자동 등록이 안 됩니다 (덮어쓰기 방지). 다음 블록을 `settings.local.json`에 수동 병합:

`templates/hooks-snippet.json` 참고.

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command",
        "command": "bash ${CLAUDE_PROJECT_DIR}/.claude/hooks/v7-post-ui-check.sh" }]
    }],
    "PreToolUse": [{
      "matcher": "Edit",
      "hooks": [{ "type": "command",
        "command": "bash ${CLAUDE_PROJECT_DIR}/.claude/hooks/v7-pre-impact-check.sh" }]
    }],
    "Stop": [{
      "hooks": [{ "type": "command",
        "command": "bash ${CLAUDE_PROJECT_DIR}/.claude/hooks/v7-session-stop.sh" }]
    }]
  }
}
```

---

## 사용 예시

설치 후 Claude Code에서:

```
/v7-implement Cart 빈 화면 새 디자인 적용
Figma: https://www.figma.com/design/.../?node-id=172:61286
```

→ input-refiner가 표준 input으로 정제 → planner가 9 steps 분석 → ... → release가 Draft PR 생성.

상세는 `pages/quickstart.html` (HTML 문서) 참고:

```bash
open /path/to/front-end-dev-agent/index.html
```

---

## 안전성

### 백업
설치 시 기존 `.claude/agents`·`skills`·`rules`·`hooks`를 `_backup_v7_<timestamp>/`로 복사. 롤백 가능.

### 제거 시 보존
`--uninstall`은 v7 파일만 제거 (`input-refiner`·`planner`·... 9개 + `v7-implement` skill + `tracking-policy`·`tracking-marker` rule + `v7-*.sh` hooks). 다른 자산은 건드리지 않음.

### prd 보호 (release agent)
`release` agent는 `prd`·`main`·`master` 직접 타겟 PR을 절대 만들지 않음. base는 항상 `develop` 또는 명시 승인 브랜치.

---

## 트러블슈팅

### Q. Claude Code에서 `/v7-implement`가 자동완성 안 나옴
A. Claude Code를 재시작. skill은 시작 시 스캔됨.

### Q. Agent들이 호출 안 됨
A. `.claude/agents/*.md`의 frontmatter `name` 필드가 정확한지 확인.
   파일명과 `name` 필드가 일치해야 함.

### Q. hooks가 작동 안 함
A. 다음 점검:
   - `chmod +x .claude/hooks/v7-*.sh` 적용됐는지
   - `settings.local.json`에 hooks 블록이 있는지
   - hook 출력은 stderr이므로 Claude Code 디버그 모드에서 확인 가능

### Q. v7 자산이 충돌
A. `--uninstall` 후 재설치하거나, `_backup_v7_*` 디렉토리에서 복구.

### Q. 백업 디렉토리 정리
A. 안전 확인 후 직접 제거: `rm -rf .claude/_backup_v7_*`

---

## 문서

전체 문서는 `front-end-dev-agent/` 디렉토리의 26개 HTML 페이지로:

```bash
open /path/to/front-end-dev-agent/index.html
```

주요 페이지:
- `pages/quickstart.html` — 명령 사용법
- `pages/getting-started.html` — 7개 시나리오 input 가이드
- `pages/pipeline.html` — 9단계 전체 흐름 (Mermaid)
- `pages/glossary.html` — v7 용어 사전
- `pages/scorecard.html` — 채점 기준
- `pages/operations-playbook.html` — 운영 매뉴얼
- `pages/adoption-playbook.html` — 점진 도입 가이드

---

## v7 vs v6 차이

- v6: 단일 에이전트 → v7: **9개 멀티 에이전트 파이프라인**
- v6: 사용자가 plan 작성 → v7: **input-refiner가 표준 input 정제**
- v6: 트래킹 구현 중 같이 → v7: **visual-qa 통과 후 마지막 단계** + 외부 SDK 신규 0 정책
- v6: 분석 산출 묵시적 → v7: **9개 산출 범주 R1~R9 정규화**
- v6: 채점 추정 → v7: **9 에이전트 채점 매트릭스 + Two-Gate Evaluation**

상세: `pages/risks.html` (v6 → v7 변경점)
