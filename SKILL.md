---
name: auto-git
description: >-
  Set up automatic, per-round git commits for a code project so the user's work
  is committed every round and never lost. It runs git init, writes a sensible
  .gitignore, installs a Stop hook that auto-commits each round (and pushes when
  an upstream is configured), and makes the initial commit — then keeps
  committing as work continues, and keeps the project's progress files
  (progress.md, plan.md, and the like) current each round. Trigger it
  proactively whenever a new code project is being started or scaffolded, even
  if the user never mentions git:
  when they describe or kick off building an app, tool, or library, create the
  first source files, or ask you to write a CLAUDE.md for a codebase. Also
  trigger on explicit requests such as /auto-git, "turn on auto commit", "set up
  version control", "commit my changes automatically as we go", or "stop losing
  my work". Lean toward activating at the start of a coding project rather than
  missing it. Do NOT trigger for one-off git actions — a single "commit this",
  "push my branch", "undo my last commit", a rebase or cherry-pick, or
  merge-conflict help — nor for git how-to questions, since none of those set up
  the automation. Do NOT trigger for a request that only wants a .gitignore
  file, for general project tooling like eslint, prettier, or dependency setup,
  for reviewing or editing existing code, or for non-code work such as writing
  or research notes.
---

# auto-git

Automatic, per-round git safety net for code projects. The goal is simple: the
user should never lose a round of work, and their history should be readable
without them having to think about committing.

## The two-part design (read this first)

This skill combines two mechanisms because they have different strengths:

1. **A Stop hook — the backbone.** A project-local `autocommit` hook commits
   any uncommitted changes after every round, automatically, whether or not
   anyone remembers, and pushes when an upstream is configured. The harness
   runs it, so it cannot be forgotten. This is what *guarantees* nothing is
   lost. An optional companion, `progress-check`, is offered separately during
   setup and **never installed by default** (see step 4): if a round changed
   files but left `progress.md` stale, it blocks the stop once with a reminder
   so you update the progress files while you still have the context (it never
   writes content itself, and a `stop_hook_active` guard means it can never
   loop).

2. **You writing real commit messages — the polish.** A hook is a dumb shell
   script; it can only write a generic timestamped message. A commit message
   that actually says what changed can only come from you, during the turn.
   So when you're working in an auto-git project, you commit meaningful changes
   yourself as the last step of a round. The hook then finds a clean tree and
   only handles pushing (or sweeps up anything you left behind).

The result: meaningful messages whenever you're active, and a guaranteed commit
every round regardless.

## When to activate

Activate (run the setup below) when a **code project** is being started or set
up and auto-git is not already installed. Signals that it's a code project:

- The user writes or asks for a `CLAUDE.md`, or gives a project overview that
  describes building software.
- Source files or package manifests are present or being created:
  `package.json`, `requirements.txt` / `pyproject.toml`, `go.mod`,
  `Cargo.toml`, `*.csproj` / `*.sln`, `pom.xml` / `build.gradle`, `Gemfile`,
  `composer.json`, a `src/` directory of code, etc.
- The user asks to set up version control, auto-commit, or "stop losing work".

Do **not** activate for pure writing, research notes, or one-off git questions.
If it's ambiguous whether the user wants this, ask once rather than assuming.

## Setup procedure

Every step is idempotent — check the current state before acting, and re-running
setup on an already-configured project should change nothing.

### 0. Bail out early if already set up

If `.claude/settings.json` already contains a `Stop` hook that runs
`autocommit`, auto-git is installed. Briefly confirm the pieces exist
(`.gitignore`, the hook scripts, the initial commit) and stop. Don't duplicate
anything. Note: `autocommit` present without `progress-check` is a normal,
complete install — `progress-check` is opt-in, and its absence usually means
the user declined it. Don't re-offer it on every re-run; add it (per step 4,
inserted *before* the `autocommit` entry) only if the user asks for it.

### 1. Initialize the repository (if needed)

**Nested-repo guard first:** before running `git init`, check
`git rev-parse --is-inside-work-tree`. If it succeeds, you're already inside a
repo — compare `git rev-parse --show-toplevel` to the current directory. If they
match, this directory is already a repo (skip init). If the toplevel is a
*parent* directory, you'd be creating a repo nested inside another one — stop and
ask the user first, since that's rarely what they want.

Otherwise initialize:

```
git init -b main        # sets the initial branch to main
```

If the running git is too old for `-b`, fall back to `git init` and rename the
branch after the first commit with `git branch -M main`.

### 2. Ensure a git identity is configured

Commits made by the hook run non-interactively, so a git identity **must** be
configured or every commit — including the initial one — fails silently with
exit 128. Do this *after* `git init`, because setting a repo-local identity
requires the repo to already exist. Check:

```
git config user.email
git config user.name
```

If either is empty (no global or local value), ask the user for the name/email
to use, then set it — locally for this repo unless they prefer global:

```
git config user.email "them@example.com"
git config user.name "Their Name"
```

### 3. Write `.gitignore`

The point is to keep "irrelevant" files out of history: build output,
dependencies, secrets, and OS/editor junk.

- If no `.gitignore` exists, create one from `assets/gitignore-base.txt`, then
  append the language-specific block(s) for whatever stack you detected. The
  per-language blocks are in `references/gitignore-languages.md` — read it and
  copy the relevant sections.
- If a `.gitignore` already exists, **do not overwrite it.** Read it, and append
  only the critical entries it's missing (especially the secrets block: `.env`,
  `*.pem`, `*.key`, credentials). Mention to the user what you added.

Secrets must never be committed — always make sure the secrets block is present.

### 4. Install the Stop hook — ask for explicit approval first

A Stop hook runs a shell command automatically after every round, so Claude Code
treats installing one as security-sensitive: under auto-accept / auto mode the
change is intercepted by the safety classifier rather than applied silently.
That's correct behavior — a hook should never appear without the user knowing.
So don't try to slip it in via auto-accept. Make installation a **deliberate,
approved step**.

**Show the user exactly what will be installed, then get a yes/no before writing
anything.** Present the hook script's path and the precise command that will run
each round, and ask with a clear approve/decline prompt (use AskUserQuestion, or
an equivalent explicit choice) — for example: *"Install the auto-commit Stop
hook? It will run `bash .claude/hooks/autocommit.sh` after every round to commit
your changes."*

- If the user **approves**, copy the script(s) and write the hook(s) (below).
  They'll also see Claude Code's own edit-permission prompt for `settings.json`
  — that's expected, and now they know to accept it.
- If the user **declines**, skip the hooks entirely and continue with the rest of
  setup. Everything else still works — git init, `.gitignore`, progress files,
  and the per-round commits you make by hand. Tell the user plainly that without
  the hook there's no automatic safety net, so they're relying on your
  end-of-round commits.

**The optional `progress-check` hook — always ask, never install by default.**
When the user approves `autocommit`, offer this one as a separate, explicit
choice, and spell out the consequence so they can actually decide — for example:

> *"Optionally, also install the `progress-check` Stop hook? What it changes:
> whenever a round modified files but progress.md wasn't updated, the hook
> blocks the stop once and I keep working — updating the progress files and
> committing — before the round truly ends. That keeps progress.md reliably
> current, but some rounds take one extra beat, and it can also fire when you
> edited files yourself and only asked me a question. If you skip it, nothing
> else changes: autocommit still commits everything; progress updates just rely
> on my per-round routine alone."*

Install it only on an explicit yes. On a no — or no clear answer — register
`autocommit` alone and move on; don't re-ask in later rounds.

When approved, copy the hook script(s) for this OS and register them:

- **Windows:** copy `scripts/autocommit.ps1` → `.claude/hooks/` (and
  `scripts/progress-check.ps1` too, if opted in). Hook commands:
  - autocommit: `pwsh -NoProfile -File .claude/hooks/autocommit.ps1`
  - progress-check (if opted in): `pwsh -NoProfile -File .claude/hooks/progress-check.ps1`
  (fall back to `powershell -NoProfile -ExecutionPolicy Bypass -File ...` if
  `pwsh` isn't available).
- **macOS / Linux:** copy `scripts/autocommit.sh` (and `scripts/progress-check.sh`
  if opted in) → `.claude/hooks/` and mark them executable (`chmod +x`). Hook
  commands: `bash .claude/hooks/autocommit.sh` and, if opted in,
  `bash .claude/hooks/progress-check.sh`.

Register by **merging** into any existing `.claude/settings.json` (never
clobber other settings or hooks). With `autocommit` alone the shape is:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "<autocommit command from above>" }
        ]
      }
    ]
  }
}
```

If the user opted into `progress-check`, its entry goes **before** the
autocommit entry in the same array:

```json
        "hooks": [
          { "type": "command", "command": "<progress-check command from above>" },
          { "type": "command", "command": "<autocommit command from above>" }
        ]
```

**Order matters:** `progress-check` must be listed before `autocommit` — it has
to see the dirty tree before `autocommit` sweeps it clean.

If a `Stop` array already exists, add these entries to it rather than replacing
it. Don't add duplicates if `autocommit` / `progress-check` commands are already
present.

### 5. Set up progress tracking (progress.md)

auto-git also keeps the project's progress files current each round, so the state
of the work is always readable and survives context loss between sessions. During
setup, create `progress.md` from `assets/progress-template.md` if it doesn't
already exist (never overwrite an existing one).

**`progress.md` is a snapshot, not a ledger.** It describes the project *now*:

```markdown
# Progress

## Current status
## Active decisions & constraints
## Next steps
## Known issues
```

Every section has overwrite semantics — updating means rewriting it to current
truth and **deleting** what no longer applies: completed steps, superseded
decisions, fixed issues. History is git's job, not this file's — every previous
version is one `git log -p -- progress.md` away, so deleting here never loses
anything. Two writing rules keep the snapshot trustworthy:

- **Claims carry pointers.** "Auth done (src/auth.ts)" — a later session can
  verify that in seconds; "auth done" alone it can only believe or doubt.
- **Size tracks task complexity, not elapsed time.** A progress.md that only
  ever grows has become a ledger — trim it on the spot.

**Old-format files:** if the project already has a progress.md with an
append-only "Log" section (this skill's earlier shape), fold it in on the next
update — keep the snapshot sections, delete the Log outright; its content is
already in git history.

Leave any other progress-type files the project already has (`plan.md`,
`TODO.md`, `ROADMAP.md`, a changelog, etc.) in place — you'll keep them current
each round too, with the same snapshot discipline where it fits (a changelog is
a deliberate ledger; leave it one). Don't fabricate a planning structure the
user didn't ask for beyond this one `progress.md`.

### 6. Record the per-round instructions in CLAUDE.md

Future sessions won't have this skill loaded, so leave a durable reminder that
carries the per-round behavior forward. Append this section to the project's
`CLAUDE.md` (create the file if it doesn't exist), unless an equivalent note is
already there:

```markdown
## Auto-git: per-round routine

At the end of any round that changed the project, do these before finishing:

1. **Update `progress.md`** — it is a snapshot of the project *now*, not a
   history. Rewrite its sections (Current status / Active decisions &
   constraints / Next steps / Known issues) to current truth, and delete
   anything completed, superseded, or fixed — history lives in `git log`, so
   deleting here loses nothing. Give claims pointers to where they live in the
   code ("auth done — src/auth.ts"). If the file only ever grows, it is
   drifting into a ledger — trim it. If it still has an append-only "Log"
   section (an older format), fold it in now: keep the snapshot sections,
   delete the Log outright — its content is already in git history.
2. **Refresh other progress files** that already exist — check off completed
   items in `plan.md` / `TODO.md`, add a changelog line, etc.
3. **Update `CLAUDE.md` itself only when this round changed something it
   documents** — architecture, key decisions, commands, or structure. Don't
   rewrite it every round.
4. **Commit** with a clear, descriptive message as the final step. A Stop hook is
   a safety net that commits anything left over and pushes when an upstream is
   configured. Commit locally; never rewrite history or force-push.

Rounds that only answered a question and changed nothing need no update or commit.
```

**Upgrade an older note in place — don't just skip it.** "An equivalent note is
already there" means one that already carries this snapshot discipline, not merely
any auto-git mention. If the project's `CLAUDE.md` has an *older or weaker* version
of this note — one written before the snapshot rule, or that still tells sessions
to keep an append-only "Log" — rewrite it to the wording above instead of leaving
it stale. Preserve any deliberate project-specific choices the old note encoded
(a commit-only "the hook never pushes" policy, a non-default progress-file name, a
project working language) and change only the progress-file discipline. One caveat:
if the project's progress file is gitignored, keep the "delete freely, history is in
`git log`" clause out of its note — with nothing versioned, deleting there loses
history, so treat that file as a running log kept readable, not a git-backed
snapshot. This in-place upgrade is what keeps existing projects from drifting when
this skill is later updated — updating the central skill never touches a project
that was set up earlier, so the note has to be refreshed the next time setup runs
there.

### 7. Make the initial commit

Stage everything that isn't ignored and commit the baseline — include all files
currently present:

```
git add -A
git commit -m "chore: initial commit (auto-git baseline)"
```

Then tell the user what you set up in a couple of lines: repo initialized,
`.gitignore` written, `progress.md` created, Stop hook installed (or skipped, if
they declined), initial commit made, and whether auto-push is active (it is only
once they add a remote + upstream).

## Working in an auto-git project (every round after setup)

When a round changed the project, wrap it up in this order before you finish:

1. **Update progress files.** Rewrite `progress.md` as a snapshot of the
   project *now*: sections to current truth, deleting anything completed,
   superseded, or fixed (history lives in `git log`; deleting here loses
   nothing), claims with pointers into the code. Check off / adjust any
   existing `plan.md`, `TODO.md`, changelog, etc. Update `CLAUDE.md` *only* if
   this round changed something it documents (architecture, decisions, commands,
   structure) — don't churn it every round.
2. **Commit last.** Stage and commit with a message that describes what actually
   changed — a real subject line, not a timestamp. Committing last (after the
   progress updates) means those updates land in the same commit and the hook
   doesn't have to sweep up after you.

Group a round's work into one sensible commit when you can; a couple of commits
is fine if the round did genuinely separate things. You don't need to push
manually — the hook pushes when an upstream exists.

A round that only answered a question and changed nothing needs no progress
update and no commit. And if you forget the wrap-up, nothing is lost: if the
optional `progress-check` hook is installed it blocks once with a reminder so
you can catch up, and either way the `autocommit` hook commits the leftovers
with a generic message — the routine just keeps `progress.md` and history
readable.

## Safety rules (non-negotiable)

These exist because auto-committing tools are dangerous when they're too
aggressive — the whole point is to help, never to surprise or destroy:

- **Local-first, no history rewriting.** Never `git reset --hard`, `rebase`,
  `commit --amend`, force-push, or anything that discards work. Only ever add
  commits.
- **Push only when it's safe.** The hook pushes solely when the current branch
  already has an upstream tracking branch and is ahead of it. It never creates
  remotes, sets upstreams, or force-pushes. If a push fails (e.g. the remote
  moved), it stays quiet and leaves the commit local — it does not retry
  destructively.
- **Never commit secrets.** The `.gitignore` secrets block is mandatory. If you
  notice a secret-looking file that isn't ignored, flag it rather than committing
  it.
- **Idempotent.** Re-running setup must never duplicate hooks or clobber the
  user's `.gitignore` / settings.

## Bundled resources

- `scripts/autocommit.ps1` — Windows Stop-hook script (the safety net + push).
- `scripts/autocommit.sh` — macOS/Linux Stop-hook script.
- `scripts/progress-check.ps1` — Windows Stop-hook script (stale-progress.md
  reminder; **opt-in only** — asked separately during setup, registered before
  autocommit when accepted).
- `scripts/progress-check.sh` — macOS/Linux counterpart.
- `assets/gitignore-base.txt` — universal `.gitignore` starting point.
- `assets/progress-template.md` — starting structure for the project's
  `progress.md` (a snapshot of current state — no append-only log; history
  stays in git).
- `references/gitignore-languages.md` — per-language `.gitignore` blocks to
  append based on the detected stack.
