# auto-git Stop hook (Windows / PowerShell)
#
# Commits any uncommitted changes as a safety net, then pushes if — and only
# if — the current branch has an upstream and is ahead of it. Never force-pushes
# and never rewrites history. Always exits 0 so it can never block Claude.

# Drain stdin (the hook receives JSON we don't need) so nothing blocks.
try { $null = [Console]::In.ReadToEnd() } catch {}

# Operate from the project root when the harness tells us where it is.
if ($env:CLAUDE_PROJECT_DIR) {
    Set-Location -LiteralPath $env:CLAUDE_PROJECT_DIR -ErrorAction SilentlyContinue
}

# Only do anything inside a git work tree.
git rev-parse --is-inside-work-tree *> $null
if ($LASTEXITCODE -ne 0) { exit 0 }

# Stage everything. git add -A respects .gitignore, so ignored files stay out.
git add -A *> $null

# `git diff --cached --quiet` exits 0 when nothing is staged, non-zero when
# there are staged changes — so non-zero here means "there is something to commit".
git diff --cached --quiet *> $null
if ($LASTEXITCODE -ne 0) {
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    git commit -q -m "chore: auto-commit (safety net) $ts" *> $null
}

# Push only when an upstream is configured and we are ahead of it.
git rev-parse --abbrev-ref --symbolic-full-name '@{u}' *> $null
if ($LASTEXITCODE -eq 0) {
    $ahead = git rev-list --count '@{u}..HEAD' 2>$null
    if ($LASTEXITCODE -eq 0 -and [int]$ahead -gt 0) {
        git push *> $null
    }
}

exit 0
