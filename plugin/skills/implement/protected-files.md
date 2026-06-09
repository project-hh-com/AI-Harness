# 보호 파일 정책 (protected-files)

> implementer(Agent 2) · functional-qa(Agent 3)가 로드.
> 아래 파일들은 AI-Harness 에이전트가 **절대 편집하지 않는다**.
> 타겟 레포가 이 파일에 추가 항목을 append해 커스터마이즈 가능.

---

## 기본 보호 목록 (모든 프로젝트 공통)

### 프로젝트 설정 파일
- `next.config.*`
- `vite.config.*`
- `webpack.config.*`
- `babel.config.*`
- `jest.config.*`
- `vitest.config.*`
- `tsconfig.json`
- `jsconfig.json`
- `.eslintrc.*`
- `.prettierrc.*`
- `tailwind.config.*`

### CI/CD
- `.github/workflows/**`
- `.gitlab-ci.yml`
- `Jenkinsfile`
- `Dockerfile*`
- `docker-compose*`

### 보안/인증
- `**/middleware.*` (Next.js/Express 미들웨어)
- `**/auth/**` (인증 설정 파일)
- `.env*` (환경변수 파일 — 커밋 자체도 금지)

### 패키지 관리
- `package.json` (devDependencies 변경 포함)
- `package-lock.json`
- `yarn.lock`
- `pnpm-lock.yaml`
- `Cargo.lock`
- `go.sum`
- `poetry.lock`

---

## 타겟 레포 커스텀 보호 파일 (설치 후 추가)

```
# 예시 — 이 섹션 아래에 추가:
# - src/lib/analytics/**
# - src/utils/tracking/**
```

---

## 위반 감지

functional-qa(Agent 3)가 `git diff --name-only`로 위 패턴에 해당하는 파일이 변경됐는지 확인.
감지 시 즉시 fail → implementer 반려 + 사용자 보고.

```bash
check_protected() {
  local changed="$1"
  local patterns=(
    "next.config" "vite.config" "webpack.config" "babel.config"
    ".eslintrc" ".prettierrc" "tailwind.config"
    ".github/workflows" "Dockerfile" "docker-compose"
    "package.json" "package-lock.json" "yarn.lock"
  )
  for p in "${patterns[@]}"; do
    echo "$changed" | grep -q "$p" && echo "❌ 보호 파일 변경: $p" && return 1
  done
  # 타겟 레포 커스텀 보호 파일 추가 확인
  if [ -f ".claude/rules/protected-files.md" ]; then
    local custom
    custom=$(grep -A100 '## 타겟 레포 커스텀' .claude/rules/protected-files.md | \
             grep '^# - ' | sed 's/^# - //')
    for f in $custom; do
      echo "$changed" | grep -q "$f" && echo "❌ 보호 파일 변경: $f" && return 1
    done
  fi
  return 0
}
```
