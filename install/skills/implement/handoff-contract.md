# Handoff Contract — 에이전트 간 인계 계약

> 모든 파이프라인 에이전트가 로드. 한 에이전트의 출력은 다음 에이전트의 입력이 된다.
> 산문(prose)만으로 넘기면 누락·추정(Assumption Drift)이 생기므로, **기계검증 가능한
> 계약 블록**을 출력 끝에 두고, 받는 쪽은 **수신 검증(Receipt Gate)**으로 먼저 확인한다.

---

## 1. 계약 블록 형식 (생산자 — 출력 끝에 필수)

```yaml
# handoff
from: <agent-name>
to: <next-agent-name>
status: ready | needs-clarification | blocked
artifact: <산출 파일 경로 or "inline">
required_present:
  - <키>: true|false
assumptions: []
open_questions: []
checksum:
  changed_files: <n>
```

- `status: ready`는 `required_present` 전부 true, `assumptions` 비었을 때만.
- 추정이 1건이라도 있으면 `status: needs-clarification` + `open_questions` 채우고 **진행 금지**.

## 2. 수신 검증 (소비자 — 작업 시작 전 필수)

1. 계약 블록 존재 + `status: ready`인가? 아니면 → 생산자에게 반려, 추측으로 진행 금지.
2. `required_present` 키가 내 작업에 필요한 항목을 모두 true로 두는가?
3. `checksum`을 실제로 교차검증. 불일치 → 반려.
4. 통과 시에만 본 작업 시작.

## 3. 단계별 핵심 required_present

| 인계 | 필수 키 |
|---|---|
| input-refiner → planner | `intent`, `type_hint`, `confidence≥medium`, `project_type` |
| planner → implementer | `R1`,`R9`,`R10`,`R11`; 디자인 시 `R5`; API 영향 시 `R4` |
| implementer → functional-qa | `changed_files`, `waves_completed`, `checkpoint_commits` |
| functional-qa → design/visual | `gates_passed`, `lint:0`, `type:0` |
| tracking-implementer → tracking-qa | `external_sdk_new: 0`, `markers_replaced` |
| release ← 전 단계 | 모든 직전 계약 `status: ready` |

## 관련
- `coding-behavior.md` (Evidence Gate E1~E6)
- `protected-files.md` (보호 파일 목록)
