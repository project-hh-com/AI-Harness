---
name: harness-init-claude-md
description: 타겟 레포 구조를 분석해 계층 CLAUDE.md 파일을 생성하거나 기존 스켈레톤을 AI로 보강한다. 설치 후 한 번 실행 권장.
---

# /harness-init-claude-md 스킬

타겟 레포의 실제 구조를 분석해 계층 CLAUDE.md 파일을 생성한다.
기존 CLAUDE.md는 절대 덮어쓰지 않는다 (스켈레톤만 보강 가능).

## 실행 흐름

### Step 1 · 프로젝트 분석

```bash
# 1. project_type 확인
cat .claude/project-type.txt 2>/dev/null || detect_project_type

# 2. 디렉토리 구조 파악
find . -type d -not -path '*/node_modules/*' -not -path '*/.git/*' \
  -not -path '*/.next/*' -not -path '*/dist/*' -not -path '*/build/*' \
  | head -50

# 3. 기존 CLAUDE.md 현황
find . -name CLAUDE.md -not -path '*/node_modules/*' | sort

# 4. 매니페스트 로드
cat .claude/scripts/claude-md-manifest.tsv
```

### Step 2 · 생성 대상 결정

매니페스트의 각 행에 대해:
- 디렉토리 실제 존재 여부 확인
- 기존 CLAUDE.md 없는 경우 → 신규 생성
- 기존 CLAUDE.md가 스켈레톤(TODO 포함)인 경우 → AI 보강 제안
- 기존 CLAUDE.md가 실제 내용 있는 경우 → skip (덮어쓰지 않음)

### Step 3 · 각 디렉토리 CLAUDE.md 생성

각 디렉토리에 대해 실제 파일 2~5개를 읽어 패턴 파악 후 작성:

**루트 CLAUDE.md** — 프로젝트 전체 TL;DR:
```markdown
# CLAUDE.md — <프로젝트명>

## TL;DR
- project_type: <감지된 타입>
- 언어/프레임워크: <실제 버전>
- 주요 진입점: <실제 경로>

## Hard Stops (전역 절대 금지)
- <실제 발견한 보호 파일 목록>
- 보호 브랜치: main/master/prd 직접 push 금지

## Always (항상)
- <실제 사용 중인 패턴>

## Task → 진입 규칙
- <작업 유형별 시작 경로>

## 프로젝트 구조
<실제 디렉토리 구조 요약>

## 개발 워크플로우
- lint: <실제 명령>
- test: <실제 명령>
- build: <실제 명령>
```

**영역별 CLAUDE.md** (≤130줄) — 해당 디렉토리 실제 패턴:
```markdown
# CLAUDE.md — <영역명>

## TL;DR
- <이 영역에서 가장 먼저 알아야 할 것>

## Hard Stops
- <이 영역에서 절대 금지인 것>

## Always
- <이 영역에서 항상 해야 할 것>

## 패턴 · 참조 파일
- <실제 대표 파일 경로와 패턴>

## 의존 방향
- <import 허용/금지 방향>
```

### Step 4 · project-patterns.md 보강

기존 `.claude/rules/project-patterns.md`의 TODO 항목을 실제 프로젝트 패턴으로 채운다:
- 실제 사용 중인 API 클라이언트 래퍼 패턴
- 금지 패턴 (직접 호출·raw element 등)
- 아키텍처 레이어 규칙

## 제약

- 기존 CLAUDE.md는 덮어쓰지 않는다 (`--force` 없으면)
- 파일당 130줄 이내
- 실제 파일 경로/패턴만 인용 (추상적 지침 금지)
- 분석은 Read/Grep/Glob만 사용 (코드 수정 없음)

## 실행 후 확인

```bash
find . -name CLAUDE.md -not -path '*/node_modules/*' | sort
wc -l */CLAUDE.md src/*/CLAUDE.md 2>/dev/null | awk '$1 > 130 {print "⚠️ " $0}'
```
