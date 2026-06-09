#!/usr/bin/env bash
# AI-Harness · 공유 프로젝트 타입 감지 함수
#
# 사용법: source "$(dirname "${BASH_SOURCE[0]}")/detect-project-type.sh"
#         PROJECT_TYPE=$(detect_project_type [디렉토리])
#
# 인자 없으면 현재 디렉토리 기준. 인자 있으면 해당 경로 기준.

detect_project_type() {
  local DIR="${1:-.}"

  # ── JavaScript / TypeScript ──────────────────────────────────────────
  if [ -f "$DIR/package.json" ]; then
    grep -q '"next"'             "$DIR/package.json" && echo "nextjs"        && return
    grep -q '"expo"'             "$DIR/package.json" && echo "react-native"  && return
    grep -q '"@angular/core"'    "$DIR/package.json" && echo "angular"       && return
    grep -q '"@vue/core"\|"vue"' "$DIR/package.json" && echo "vue"           && return
    grep -q '"svelte"'           "$DIR/package.json" && echo "svelte"        && return
    grep -q '"astro"'            "$DIR/package.json" && echo "astro"         && return
    grep -q '"nuxt"'             "$DIR/package.json" && echo "nuxt"          && return
    grep -q '"@remix-run'        "$DIR/package.json" && echo "remix"         && return
    grep -q '"gatsby"'           "$DIR/package.json" && echo "gatsby"        && return
    grep -q '"electron"'         "$DIR/package.json" && echo "electron"      && return
    grep -q '"react"'            "$DIR/package.json" && echo "react"         && return
    grep -q '"express"\|"fastify"\|"koa"\|"hapi"' "$DIR/package.json" \
                                                    && echo "node-server"   && return
    echo "node" && return
  fi

  # ── Python ───────────────────────────────────────────────────────────
  if [ -f "$DIR/manage.py" ] || ([ -f "$DIR/requirements.txt" ] && grep -qi "django" "$DIR/requirements.txt" 2>/dev/null); then
    echo "django" && return
  fi
  if [ -f "$DIR/requirements.txt" ] && grep -qi "flask" "$DIR/requirements.txt" 2>/dev/null; then
    echo "flask" && return
  fi
  if [ -f "$DIR/requirements.txt" ] && grep -qi "fastapi" "$DIR/requirements.txt" 2>/dev/null; then
    echo "fastapi" && return
  fi
  { [ -f "$DIR/pyproject.toml" ] || [ -f "$DIR/setup.py" ] || [ -f "$DIR/requirements.txt" ]; } && echo "python" && return

  # ── Go ───────────────────────────────────────────────────────────────
  [ -f "$DIR/go.mod" ] && echo "go" && return

  # ── Rust ─────────────────────────────────────────────────────────────
  [ -f "$DIR/Cargo.toml" ] && echo "rust" && return

  # ── JVM ──────────────────────────────────────────────────────────────
  if [ -f "$DIR/pom.xml" ]; then
    grep -qi "spring-boot"               "$DIR/pom.xml" && echo "spring-boot" && return
    grep -qi "kotlin"                    "$DIR/pom.xml" && echo "kotlin-jvm"  && return
    grep -qi "javax.servlet\|jakarta.servlet" "$DIR/pom.xml" && echo "jsp-servlet" && return
    echo "java-maven" && return
  fi
  if [ -f "$DIR/build.gradle" ] || [ -f "$DIR/build.gradle.kts" ]; then
    grep -qi "spring-boot" "$DIR/build.gradle" "$DIR/build.gradle.kts" 2>/dev/null && echo "spring-boot"   && return
    grep -qi "com.android" "$DIR/build.gradle" "$DIR/build.gradle.kts" 2>/dev/null && {
      grep -qi "kotlin"    "$DIR/build.gradle" "$DIR/build.gradle.kts" 2>/dev/null && echo "android-kotlin" && return
      echo "android-java" && return
    }
    grep -qi "kotlin"      "$DIR/build.gradle" "$DIR/build.gradle.kts" 2>/dev/null && echo "kotlin-jvm"    && return
    echo "java-gradle" && return
  fi

  # ── Ruby ─────────────────────────────────────────────────────────────
  if [ -f "$DIR/Gemfile" ]; then
    grep -qi "rails"   "$DIR/Gemfile" && echo "rails"   && return
    grep -qi "sinatra" "$DIR/Gemfile" && echo "sinatra" && return
    echo "ruby" && return
  fi

  # ── PHP ──────────────────────────────────────────────────────────────
  if [ -f "$DIR/composer.json" ]; then
    grep -qi "laravel"   "$DIR/composer.json" && echo "laravel"   && return
    grep -qi "symfony"   "$DIR/composer.json" && echo "symfony"   && return
    grep -qi "wordpress" "$DIR/composer.json" && echo "wordpress" && return
    echo "php" && return
  fi
  [ -f "$DIR/wp-config.php" ] && echo "wordpress" && return

  # ── .NET ─────────────────────────────────────────────────────────────
  ls "$DIR"/*.csproj "$DIR"/*.sln 2>/dev/null | head -1 | grep -q '.' && {
    grep -qi "blazor\|razor"                          "$DIR"/*.csproj 2>/dev/null && echo "dotnet-blazor"  && return
    grep -qi "aspnet\|aspnetcore\|microsoft.aspnetcore" "$DIR"/*.csproj 2>/dev/null && echo "dotnet-aspnet" && return
    echo "dotnet" && return
  }

  # ── Swift / iOS / macOS ──────────────────────────────────────────────
  [ -f "$DIR/Package.swift" ] && echo "swift" && return
  ls "$DIR"/*.xcodeproj "$DIR"/*.xcworkspace 2>/dev/null | head -1 | grep -q '.' && echo "swift" && return

  # ── Dart / Flutter ───────────────────────────────────────────────────
  [ -f "$DIR/pubspec.yaml" ] && grep -q "flutter" "$DIR/pubspec.yaml" && echo "flutter" && return
  [ -f "$DIR/pubspec.yaml" ] && echo "dart" && return

  # ── Elixir / Phoenix ─────────────────────────────────────────────────
  [ -f "$DIR/mix.exs" ] && grep -qi "phoenix" "$DIR/mix.exs" && echo "phoenix" && return
  [ -f "$DIR/mix.exs" ] && echo "elixir" && return

  # ── Haskell ──────────────────────────────────────────────────────────
  { [ -f "$DIR/stack.yaml" ] || [ -f "$DIR/cabal.project" ]; } && echo "haskell" && return

  # ── C / C++ ──────────────────────────────────────────────────────────
  [ -f "$DIR/CMakeLists.txt" ] && echo "cmake-cpp" && return
  [ -f "$DIR/Makefile" ] && grep -q '\.cpp\|\.cc\|\.cxx' "$DIR/Makefile" 2>/dev/null && echo "cpp" && return
  [ -f "$DIR/Makefile" ] && echo "c-make" && return

  # ── Terraform / IaC ──────────────────────────────────────────────────
  ls "$DIR"/*.tf 2>/dev/null | head -1 | grep -q '.' && echo "terraform" && return

  # ── Generic fallback ─────────────────────────────────────────────────
  echo "generic"
}
