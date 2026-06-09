---
name: forbidden-patterns
description: project_type별 Gate 3 금지 패턴 목록. functional-qa Gate 3에서 참조. check-patterns.sh도 이 파일을 사용한다.
---

# Forbidden Patterns by Stack

## 공통 (모든 스택)

| 패턴 | 이유 |
|---|---|
| `console\.log\(` | 프로덕션 코드 로그 금지 |
| `TODO\|FIXME\|HACK` | 미처리 기술 부채 |

## JS / TypeScript 계열

| 스택 | 패턴 | 이유 |
|---|---|---|
| nextjs/react/vue/svelte 등 | `<button[[:space:]>]` | raw button — 접근성 위반 |
| nextjs/react 계열 | `import axios from 'axios'` | 래퍼 없이 직접 axios |
| react | `dangerouslySetInnerHTML` | XSS |
| electron | `nodeIntegration.*true` | 보안 위반 |
| electron | `contextIsolation.*false` | 보안 위반 |
| node | `eval\(` | 코드 실행 |
| node | `require\('child_process'\)` | 직접 shell 실행 |

## Python 계열

| 스택 | 패턴 | 이유 |
|---|---|---|
| django | `DEBUG\s*=\s*True` | 프로덕션 DEBUG 노출 |
| 모든 Python | `import \*` | wildcard import |
| 모든 Python | `eval\(\|exec\(` | 코드 실행 |

## Go

| 패턴 | 이유 |
|---|---|
| `panic\(` | naked panic |
| `_ = err` | 에러 무시 |

## Rust

| 패턴 | 이유 |
|---|---|
| `#\[allow\(dead_code\)\]` | dead code 허용 |
| `unwrap\(\)` | 패닉 위험 |

## JVM 계열

| 스택 | 패턴 | 이유 |
|---|---|---|
| Java/Spring | `printStackTrace\(\)` | 스택 트레이스 노출 |
| Java/Spring | `System\.out\.print` | 프로덕션 출력 |
| Java/Spring | `catch\s*\(\s*Exception\s` | 과도한 catch |
| Android Kotlin | `!!` | null 강제 (NPE) |
| Android Kotlin/Java | `AsyncTask` | deprecated API |

## Ruby

| 패턴 | 이유 |
|---|---|
| `render.*html.*safe` | XSS |
| `raw\s` | html raw 출력 |
| `eval\(` | 코드 실행 |

## PHP

| 패턴 | 이유 |
|---|---|
| `\$_GET\|\$_POST\|\$_REQUEST` | 직접 user input |
| `eval\(` | 코드 실행 |
| `var_dump\|print_r` | 디버그 출력 |

## .NET

| 패턴 | 이유 |
|---|---|
| `Console\.Write\|Debug\.Print` | 프로덕션 출력 |
| `catch\s*\(\s*Exception\s` | 과도한 catch |

## Swift / iOS

| 패턴 | 이유 |
|---|---|
| `fatalError\|force_try\|try!` | 강제 실행 |
| `print(` | 프로덕션 출력 |

## Flutter / Dart

| 패턴 | 이유 |
|---|---|
| `print\(` | 프로덕션 출력 |

## Elixir

| 패턴 | 이유 |
|---|---|
| `IO\.puts\|IO\.inspect` | 프로덕션 출력 |

## Terraform / IaC

| 패턴 | 이유 |
|---|---|
| `password\s*=\s*"[^"]` | 하드코딩 credentials |
| `access_key\s*=\s*"[^"]` | 하드코딩 credentials |
