#!/usr/bin/env bash
# auto-git Stop hook (macOS / Linux) — progress-check
#
# The companion to autocommit.sh: a dumb, deterministic checker that nudges
# Claude when a round changed files but progress.md was left stale. It never
# writes content itself — it emits {"decision":"block","reason":...} once so
# Claude (which has the context) updates the progress files and commits.
# Register it BEFORE autocommit.sh in the Stop hooks array. Fails open: any
# doubt → exit 0 silently, so it can never trap the session.
set -u

# Read the hook input JSON from stdin.
INPUT="$(cat 2>/dev/null || true)"

# Never loop: if this stop already came from a blocked stop, stay quiet and
# let autocommit.sh sweep whatever is left.
if printf '%s' "$INPUT" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

# Operate from the project root when the harness tells us where it is.
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || true
fi

# Only act inside a git work tree.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Only guard auto-git projects: progress.md must exist at the repo root.
top="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -n "$top" ] && [ -f "$top/progress.md" ] || exit 0

# Uncommitted changes (staged + unstaged + untracked, .gitignore respected).
changes="$(git status --porcelain 2>/dev/null)" || exit 0
[ -n "$changes" ] || exit 0

# progress.md already touched this round → the routine was followed (or the
# sweep will include it). Loose match on purpose: over-matching fails open.
if printf '%s\n' "$changes" | grep -q 'progress\.md'; then
  exit 0
fi

# Changes exist but progress.md is stale → nudge Claude once, then exit 0.
cat <<'EOF'
{"decision":"block","reason":"auto-git: this round changed files but progress.md was not updated. Before finishing: (1) rewrite the 'Current status' section of progress.md and append a dated Log entry for this round, (2) refresh any other progress files that exist (plan.md, TODO.md, changelog), (3) commit everything with a descriptive message. If the changes are trivial or not yours (e.g. the user's own edits), a one-line Log entry and a short commit are enough."}
EOF
exit 0
