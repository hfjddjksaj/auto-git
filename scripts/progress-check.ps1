# auto-git Stop hook (Windows / PowerShell) — progress-check
#
# The companion to autocommit.ps1: a dumb, deterministic checker that nudges
# Claude when a round changed files but progress.md was left stale. It never
# writes content itself — it emits {"decision":"block","reason":...} once so
# Claude (which has the context) updates the progress files and commits.
# Register it BEFORE autocommit.ps1 in the Stop hooks array. Fails open: any
# doubt → exit 0 silently, so it can never trap the session.

# Read the hook input JSON from stdin.
$stdin = ""
try { $stdin = [Console]::In.ReadToEnd() } catch {}

# Never loop: if this stop already came from a blocked stop, stay quiet and
# let autocommit.ps1 sweep whatever is left.
if ($stdin -match '"stop_hook_active"\s*:\s*true') { exit 0 }

# Operate from the project root when the harness tells us where it is.
if ($env:CLAUDE_PROJECT_DIR) {
    Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
}

# Only act inside a git work tree.
git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { exit 0 }

# Only guard auto-git projects: progress.md must exist at the repo root.
$top = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or -not $top) { exit 0 }
if (-not (Test-Path (Join-Path $top 'progress.md'))) { exit 0 }

# Uncommitted changes (staged + unstaged + untracked, .gitignore respected).
$changes = git status --porcelain 2>$null | Out-String
if (-not $changes.Trim()) { exit 0 }

# progress.md already touched this round → the routine was followed (or the
# sweep will include it). Loose match on purpose: over-matching fails open.
if ($changes -match 'progress\.md') { exit 0 }

# Changes exist but progress.md is stale → nudge Claude once, then exit 0.
Write-Output '{"decision":"block","reason":"auto-git: this round changed files but progress.md was not updated. Before finishing: (1) rewrite the ''Current status'' section of progress.md and append a dated Log entry for this round, (2) refresh any other progress files that exist (plan.md, TODO.md, changelog), (3) commit everything with a descriptive message. If the changes are trivial or not yours (e.g. the user''s own edits), a one-line Log entry and a short commit are enough."}
exit 0
