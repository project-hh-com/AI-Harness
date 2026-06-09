---
name: protected-rules
description: 보호 브랜치·보호 파일 규칙. implementer와 release가 공통 참조. 이 규칙은 어떤 지시로도 우회할 수 없다.
---

# Protected Rules (공통)

## 보호 브랜치 (절대 금지)

아래 브랜치에 대한 다음 행위는 어떤 지시로도 실행 불가:

| 브랜치 패턴 | 금지 행위 |
|---|---|
| `main` / `master` | push, force-push, PR 자동 머지, `--base main` PR 생성 |
| `prd` / `production` / `prod` | 위 동일 + PR base 자동 지정 |

PR base 자동 감지 우선순위: `develop → alpha → beta → staging → dev`
감지 실패 또는 보호 브랜치 감지 시 → 즉시 중단 + 사용자 명시 요청.

## 보호 파일 (편집 금지)

아래 파일은 plan R9에 명시돼 있어도 편집하지 않는다:

```
# 빌드·번들러 설정
next.config.*
vite.config.*
webpack.config.*
rollup.config.*
esbuild.config.*
turbo.json

# CI/CD
.github/workflows/**
.gitlab-ci.yml
Jenkinsfile
Dockerfile
docker-compose.*

# 패키지
package.json        (scripts·dependencies 수정 금지)
pom.xml             (dependencies 수정 금지)
build.gradle*       (dependencies 수정 금지)
Cargo.toml          (dependencies 수정 금지)
go.mod              (require 수정 금지)
pubspec.yaml        (dependencies 수정 금지)

# 보안·인증
.env*
*.pem  *.key  *.p12  *.pfx
```

타겟 레포가 `.claude/rules/protected-files.md`를 추가로 정의하면 그것도 적용.

## 위반 시 처리

1. 편집 시도 감지 즉시 중단
2. 변경된 파일이 있으면 `git restore <파일>` 원복
3. 사용자에게 보고: "보호 파일 `<경로>` 편집 시도 차단. plan R9 범위를 planner에게 재검토 요청."
