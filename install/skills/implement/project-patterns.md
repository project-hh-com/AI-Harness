# 프로젝트 패턴 규칙 (project-patterns)

> 이 파일은 **타겟 레포가 채운다**. 설치 시 스켈레톤으로 생성되며,
> `/harness-init-claude-md` 또는 수동으로 프로젝트 실제 패턴을 등록한다.
> functional-qa(Agent 3)의 Gate 3이 이 파일을 참조해 커스텀 패턴 위반을 검출한다.

---

## 금지 패턴 (위반 시 Gate 3 fail)

```
# 형식: PATTERN | DESCRIPTION | RECOMMENDATION
# 예시 (주석 처리 — 실제 패턴으로 교체):
# import axios from 'axios' | axios 직접 import | apiClient 또는 프로젝트 래퍼 사용
# <button | raw <button> 태그 | Button 컴포넌트 사용
```

## 권장 패턴 (위반 시 Gate 3 경고)

```
# 예시:
# console\.log | 프로덕션 console.log | logger 유틸 사용
```

## 아키텍처 레이어 규칙

```
# 예시 (단방향 import 강제):
# pages/ → components/ → hooks/ → lib/ → services/ → types/
# 역방향 import 금지
```

## 컴포넌트 레벨 결정 기준

```
# 예시:
# 공용(common): 4개 이상 도메인에서 재사용
# 도메인(domain/<x>): 특정 도메인 전용
# 페이지-local: 단일 페이지에서만 사용
```

---

> ⚠️ 이 파일을 채우지 않으면 Gate 3은 공통 패턴만 검출합니다 (console.log, TODO 등).
> 프로젝트 고유 패턴을 등록할수록 파이프라인 품질이 높아집니다.
