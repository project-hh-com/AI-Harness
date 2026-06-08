---
name: implement
description: 자연어 input → 9-에이전트 파이프라인 자동 실행. input-refiner→planner→implementer→QA→release 전 과정 오케스트레이션.
---

# /implement 스킬 — 9-에이전트 파이프라인 오케스트레이터

사용자의 자연어 input을 받아 9개 에이전트를 순서대로 실행한다.
모든 에이전트가 완료되면 Draft PR URL을 반환한다.

## 파이프라인 흐름

```
/implement <input>
     │
     ▼ Agent 0
  input-refiner ──(self_score < 80)──▶ AskUserQuestion ──▶ 재진입
     │ .claude/refined-inputs/<task>.md
     ▼ Agent 1
  planner (Opus)
     │ .claude/plans/<task>.md
     ▼ Agent 2
  implementer (Sonnet S2, wave 단위)
     │ wave별 checkpoint commit
     ▼ Agent 3 (매 wave 후)
  functional-qa ──(fail)──▶ implementer 재진입
     │
     ├─ 디자인 변경 있으면 ──▶ Agent 4 · design-qa
     │                            │
     │                            ▼ Agent 5 · visual-qa
     │
     ├─ 트래킹 계획 있으면 ──▶ Agent 6 · tracking-implementer
     │                            │
     │                            ▼ Agent 7 · tracking-qa
     │
     ▼ Agent 8
  release ──▶ Draft PR URL 반환
```

## 실행 방법

```
/implement <자연어 input>
```

예시:
```
/implement 사용자 프로필 페이지에 아바타 업로드 기능 추가
Figma: https://www.figma.com/design/xxx/node-id=172:61

/implement login page password reset button not working
area=src/pages/auth type=bugfix
```

## 오케스트레이터 로직

### Step 1 · input-refiner 실행
```
에이전트: input-refiner
입력: 사용자 원본 input
출력: .claude/refined-inputs/<task>.md
```

refined-input의 `confidence < medium` 또는 `unresolved_ambiguity` 비어있지 않으면
→ AskUserQuestion 도구로 사용자에게 명확화 질문 제시
→ 답변을 input에 합쳐 input-refiner 재실행

### Step 2 · planner 실행
```
에이전트: planner
입력: .claude/refined-inputs/<task>.md
출력: .claude/plans/<task>.md
```

handoff `status: needs-clarification`이면 → AskUserQuestion으로 사용자 질의

### Step 3 · implementer → functional-qa 루프 (wave 단위)

plan R11의 각 wave마다:
```
1. implementer(S2) 실행 — 해당 wave 코드 작성 + checkpoint commit
2. functional-qa 실행 — 4개 게이트 검증
   ✅ pass → 다음 wave 또는 QA 단계로
   ❌ fail → implementer(S2) 재진입 (같은 wave, 무제한 반복)
```

### Step 4 · 조건부 QA 단계

plan R3 (디자인 스펙) 있으면:
- design-qa → visual-qa 순서로 실행
- fail → implementer 재진입

plan R8 (트래킹 계획) 있으면:
- tracking-implementer → tracking-qa 순서로 실행
- fail → tracking-implementer 재진입

### Step 5 · release
```
에이전트: release
입력: 모든 QA 리포트 + plan
출력: Draft PR URL
```

## 에이전트 skip 조건

| 에이전트 | skip 조건 |
|---|---|
| design-qa | plan R3 = N/A (Figma URL 없음) |
| visual-qa | UI 변경 없음 또는 design-qa skip |
| tracking-implementer | plan R8 = N/A |
| tracking-qa | tracking-implementer skip |

## 에러 처리

- 에이전트가 `status: blocked`를 반환하면 → 사용자에게 보고 + 파이프라인 일시 중단
- 같은 gate fail이 3회 반복되면 → 사용자에게 보고 (무한 루프 방지)
- 보호 파일 변경 감지 시 → 즉시 중단 + 사용자 보고

## 실행 진행상황 출력

```
[AI-Harness] /implement 시작 — <task-name>
  Agent 0 · input-refiner ⟳
  Agent 1 · planner ⟳
  Agent 2 · implementer (wave 1/3) ⟳
  Agent 3 · functional-qa ✅
  Agent 2 · implementer (wave 2/3) ⟳
  Agent 3 · functional-qa ✅
  Agent 2 · implementer (wave 3/3) ⟳
  Agent 3 · functional-qa ✅
  Agent 4 · design-qa ✅
  Agent 5 · visual-qa ✅
  Agent 8 · release ✅
[AI-Harness] 완료 — Draft PR: https://github.com/...
```
