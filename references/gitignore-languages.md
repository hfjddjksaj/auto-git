# Per-language .gitignore blocks

Append the block(s) matching the detected stack to the base `.gitignore`.
Only add blocks for stacks actually present in the project.

## Node.js / JavaScript / TypeScript

```
# --- Node ---
node_modules/
.npm/
.pnpm-store/
.yarn/cache/
*.tsbuildinfo
.next/
.nuxt/
.svelte-kit/
.turbo/
.vite/
.parcel-cache/
```

## Python

```
# --- Python ---
__pycache__/
*.py[cod]
*.egg-info/
.eggs/
.venv/
venv/
env/
.pytest_cache/
.mypy_cache/
.ruff_cache/
.tox/
.ipynb_checkpoints/
htmlcov/
.coverage
```

## Go

```
# --- Go ---
*.exe
*.test
*.out
vendor/
```

## Rust

```
# --- Rust ---
target/
**/*.rs.bk
```

## Java / Kotlin (Maven & Gradle)

```
# --- Java / Kotlin ---
target/
.gradle/
*.class
*.jar
!gradle/wrapper/gradle-wrapper.jar
.settings/
.classpath
.project
```

## C# / .NET

```
# --- .NET ---
bin/
obj/
*.user
*.suo
packages/
TestResults/
```

## Ruby

```
# --- Ruby ---
.bundle/
vendor/bundle/
*.gem
```

## PHP

```
# --- PHP ---
vendor/
composer.phar
```

## C / C++

```
# --- C / C++ ---
*.o
*.obj
*.a
*.lib
*.so
*.dylib
*.dll
*.exe
cmake-build-*/
CMakeCache.txt
CMakeFiles/
```

## Swift / Xcode

```
# --- Swift / Xcode ---
.build/
DerivedData/
*.xcuserstate
xcuserdata/
Pods/
```

## Web assets / misc

```
# --- Web / misc ---
.cache/
.sass-cache/
*.map
```
