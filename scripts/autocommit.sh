#!/usr/bin/env bash
# auto-git Stop hook (macOS / Linux)
#
# Commits any uncommitted changes as a safety net, then pushes if — and only
# if — the current branch has an upstream and is ahead of it. Never force-pushes
# and never rewrites history. Always exits 0 so it can never block Claude.
set -u

# Drain stdin (the hook receives JSON we don't need) so nothing blocks.
cat >/dev/null 2>&1 || true

# Operate from the project root when the harness tells us where it is.
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || true
fi

# Only do anything inside a git work tree.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# Stage everything. git add -A respects .gitignore, so ignored files stay out.
git add -A >/dev/null 2>&1

# `git diff --cached --quiet` exits 0 when nothing is staged, non-zero when
# there are staged changes — so a non-zero status means there is something to commit.
if ! git diff --cached --quiet 2>/dev/null; then
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  git commit -q -m "chore: auto-commit (safety net) ${ts}" >/dev/null 2>&1
fi

# Push only when an upstream is configured and we are ahead of it.
if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  ahead="$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)"
  if [ "${ahead:-0}" -gt 0 ]; then
    git push >/dev/null 2>&1 || true
  fi
fi

exit 0
