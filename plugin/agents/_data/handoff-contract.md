---
name: handoff-contract
description: 에이전트 간 핸드오프 YAML 계약 스키마. 모든 에이전트가 출력 말미에 이 형식으로 계약을 작성하고, 수신 에이전트가 Receipt Gate에서 검증한다.
---

# Handoff Contract Schema

모든 에이전트는 작업 완료 후 아래 YAML 블록을 출력 말미에 첨부한다.
수신 에이전트는 `status: ready` 확인 후에만 작업을 시작한다.

## 형식

```yaml
# handoff
from: <agent-name>          # 발신 에이전트
to: <agent-name>            # 수신 에이전트
status: ready | needs-clarification | blocked
artifact: <파일 경로 또는 git 명령>
required_present:
  <key>: true | false       # 수신 에이전트가 검증할 항목
assumptions: []             # 불확실하게 가정한 사항 목록 (없으면 빈 배열)
checksum:
  <key>: <값>               # 수량 일치 검증용 (파일 수, wave 수 등)
```

## 에이전트별 계약 명세

| from → to | artifact | required_present 핵심 항목 |
|---|---|---|
| input-refiner → planner | `.claude/refined-inputs/<task>.md` | `project_type`, `confidence ≥ medium` |
| planner → implementer | `.claude/plans/<task>.md` | `R1`, `R9`, `R10`, `R11` |
| implementer → functional-qa | `git diff --name-only HEAD~N..HEAD` | `changed_files`, `waves_completed`, `checkpoint_commits` |
| functional-qa → design-qa | `.claude/qa-reports/functional-*.md` | `gate1~4: pass`, `gate6: pass` |
| design-qa → visual-qa | `.claude/qa-reports/design-*.md` | `token_match`, `mapping_match` |
| visual-qa → tracking-implementer | `.claude/qa-reports/visual-*.md` | `pixel_diff ≤ threshold` |
| tracking-implementer → tracking-qa | changed files | `track_markers_replaced` |
| tracking-qa → release | `.claude/qa-reports/tracking-*.md` | `new_sdk_calls: 0`, `regression: 0` |
| release → user | PR URL | Draft PR created |

## Receipt Gate — 수신 에이전트 검증 절차

```
1. handoff 블록 파싱
2. status == "ready" 확인 → 아니면 발신 에이전트 반려
3. required_present 항목 실측 확인 (self-assert 신뢰 금지)
4. checksum 수치 일치 확인
5. 통과 시에만 작업 시작
```

## needs-clarification / blocked 처리

- `needs-clarification`: 수신 에이전트가 발신 에이전트에게 구체적 질문과 함께 반려
- `blocked`: 외부 요인(API 명세 없음, 보호 파일 수정 필요 등) — 사용자에게 보고 후 대기
