# AI 행동 원칙 (coding-behavior)

> implementer(Agent 2)가 항상 로드. 코드 작성 시 지켜야 할 행동 원칙.
> 프레임워크·언어 무관. 도메인별 패턴 룰은 타겟 레포의 `.claude/rules/project-patterns.md` 참조.

---

## Evidence Gate — "Confidence Mirage" 방지

"잘 됐다"·"통과했다"가 아닌 **재현 가능한 증거**로만 완료를 주장한다.

| # | 항목 | 요구 |
|---|---|---|
| E1 | 패턴 준수 | 참조 파일 경로 + 패턴명 |
| E2 | 최단 해 | 거절한 대안 + 이유 |
| E3 | 엣지 케이스 | 분기별 처리 방식 (R7과 1:1) |
| E4 | 테스트 | 실행 명령 + 출력 인용 (실패 0 증명) |
| E5 | 회귀 | 확인한 파일·기능 (base 대비) |
| E6 | 실제 문제 | 요구사항 → 구현 위치 매핑 |

E4(테스트 출력) 누락은 "Phantom Verification" 신호 — 무조건 감점.

## 명명된 안티패턴 (회피)

| 안티패턴 | 설명 |
|---|---|
| Shortcut Spiral | 검증 우회·`--no-verify`로 게이트를 끄는 방향 |
| Confidence Mirage | 검증 없이 자신감만 표현 |
| Phantom Verification | 실행하지 않고 "통과"라고 보고 |
| Scope Creep | 작업 범위 밖 리팩토링·추상화 추가 |
| Assumption Drift | API 필드·분기를 추정으로 채움 |

## 최소 변경 원칙

- 작업이 요구하는 것만 구현. 버그 수정에 주변 정리 끼워넣지 않음.
- 일어날 수 없는 시나리오용 방어 코드·폴백 추가 금지.
- 추정 금지 — 모르는 API 필드/분기는 planner로 되돌려 확인.
- 범위 밖 파일 수정이 필요하다고 판단되면 planner에게 반려.

## 영향 반경 의식

- 공용 모듈·util·hooks 수정 시 의존 모듈을 grep으로 확인하고 기존 동작 보존 증거를 남긴다.
- PreToolUse hook(`harness-pre-impact-check.sh`)의 HIGH/MEDIUM 경고를 무시하지 않는다.

## 코드 품질 원칙

- 언어/프레임워크에 맞는 관용 코드 사용.
- 주석은 "왜"가 비자명한 경우만 1줄. 무엇을 하는지 설명하는 주석 금지.
- 하드코딩된 비밀 정보(API key, password, token) 절대 금지.
- 프로덕션 코드에 `console.log` / `print` 잔류 금지.
- 미사용 코드(dead code) 커밋 금지. 주석 처리된 코드 커밋 금지.
