---
name: tool-mapping
description: project_type별 lint·typecheck·test·build 명령 참조표. planner Step 1, functional-qa Gate 1/2/4에서 Read로 참조.
---

# Tool Mapping Reference

| project_type | lint | type check | test | build |
|---|---|---|---|---|
| **JS / TypeScript** | | | | |
| nextjs | `next lint` / `eslint` | `tsc --noEmit` | `jest` / `vitest` | `next build` |
| react-native | `eslint` | `tsc --noEmit` | `jest` | `expo prebuild` |
| react | `eslint` | `tsc --noEmit` | `jest` / `vitest` | `vite build` |
| vue | `eslint` | `vue-tsc --noEmit` | `vitest` | `vite build` |
| nuxt | `eslint` | `nuxi typecheck` | `vitest` | `nuxt build` |
| angular | `ng lint` | `tsc --noEmit` | `ng test --watch=false` | `ng build` |
| svelte | `eslint` | `svelte-check` | `vitest` | `vite build` |
| astro | `eslint` | `astro check` | `vitest` | `astro build` |
| remix | `eslint` | `tsc --noEmit` | `vitest` | `remix build` |
| gatsby | `eslint` | `tsc --noEmit` | `jest` | `gatsby build` |
| electron | `eslint` | `tsc --noEmit` | `jest` | `electron-builder` |
| node-server | `eslint` | `tsc --noEmit` | `jest` / `vitest` | `tsc` |
| node | `eslint` | `tsc --noEmit` | `jest` / `vitest` | — |
| **Python** | | | | |
| django | `ruff` / `flake8` | `mypy` | `pytest` / `manage.py test` | — |
| flask | `ruff` / `flake8` | `mypy` | `pytest` | — |
| fastapi | `ruff` / `flake8` | `mypy` | `pytest` | — |
| python | `ruff` / `flake8` | `mypy` | `pytest` | — |
| **Go** | | | | |
| go | `golangci-lint run` | `go vet ./...` | `go test ./...` | `go build ./...` |
| **Rust** | | | | |
| rust | `cargo clippy -- -D warnings` | `cargo check` | `cargo test` | `cargo build` |
| **JVM** | | | | |
| spring-boot | `mvn checkstyle:check` / `./gradlew checkstyleMain` | `mvn compile -q` | `mvn test` / `./gradlew test` | `mvn package` / `./gradlew bootJar` |
| java-maven | `mvn checkstyle:check` | `mvn compile -q` | `mvn test` | `mvn package` |
| java-gradle | `./gradlew checkstyleMain` | `./gradlew compileJava` | `./gradlew test` | `./gradlew build` |
| kotlin-jvm | `./gradlew ktlintCheck` | `./gradlew compileKotlin` | `./gradlew test` | `./gradlew build` |
| android-kotlin | `./gradlew ktlintCheck` / `./gradlew lint` | `./gradlew compileDebugKotlin` | `./gradlew testDebugUnitTest` | `./gradlew assembleDebug` |
| android-java | `./gradlew lint` | `./gradlew compileDebugJavaSources` | `./gradlew testDebugUnitTest` | `./gradlew assembleDebug` |
| jsp-servlet | `mvn checkstyle:check` | `mvn compile -q` | `mvn test` | `mvn package` |
| **Ruby** | | | | |
| rails | `rubocop` | `srb tc` (Sorbet) | `rspec` / `rails test` | — |
| sinatra | `rubocop` | — | `rspec` / `rake test` | — |
| ruby | `rubocop` | — | `rspec` / `rake test` | — |
| **PHP** | | | | |
| laravel | `./vendor/bin/phpstan analyse` | — | `./vendor/bin/phpunit` / `php artisan test` | — |
| symfony | `./vendor/bin/phpstan analyse` | — | `./vendor/bin/phpunit` | — |
| wordpress | `phpcs --standard=WordPress` | — | `phpunit` | — |
| php | `phpcs` / `phpstan` | — | `phpunit` | — |
| **.NET** | | | | |
| dotnet-aspnet | `dotnet format --verify-no-changes` | `dotnet build` | `dotnet test` | `dotnet publish` |
| dotnet-blazor | `dotnet format --verify-no-changes` | `dotnet build` | `dotnet test` | `dotnet publish` |
| dotnet | `dotnet format --verify-no-changes` | `dotnet build` | `dotnet test` | `dotnet publish` |
| **Swift / iOS** | | | | |
| swift | `swiftlint` | `swift build` | `swift test` | `swift build -c release` |
| **Dart / Flutter** | | | | |
| flutter | `flutter analyze` | `dart analyze` | `flutter test` | `flutter build apk` |
| dart | `dart analyze` | `dart analyze` | `dart test` | `dart compile exe` |
| **Elixir** | | | | |
| phoenix | `mix credo` | `mix dialyzer` | `mix test` | `mix phx.digest` |
| elixir | `mix credo` | `mix dialyzer` | `mix test` | — |
| **Haskell** | | | | |
| haskell | `hlint .` | `stack build` | `stack test` | `stack build --flag '*:optimize'` |
| **C / C++** | | | | |
| cmake-cpp | `clang-tidy` / `cpplint` | `cmake --build .` | `ctest` | `cmake --build . --config Release` |
| cpp | `clang-tidy` / `cpplint` | `make` | `make test` | `make` |
| c-make | `clang-tidy` | `make` | `make test` | `make` |
| **IaC** | | | | |
| terraform | `terraform fmt -check` | `terraform validate` | `terratest` | `terraform plan` |
| **Fallback** | | | | |
| generic | `<scripts.lint>` | — | `<scripts.test>` | — |
