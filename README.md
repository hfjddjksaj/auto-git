# auto-git

A [Claude Code](https://claude.com/claude-code) skill that gives any code
project an automatic, per-round git safety net — your work gets committed
every round and is never lost, with readable progress tracking on top.

## What it does

When activated in a code project, Claude:

1. Runs `git init`, writes a sensible `.gitignore` (with a mandatory secrets
   block), creates `progress.md`, and makes the initial commit.
2. With your explicit approval, installs a project-local **Stop hook** that
   runs after every round:
   - **autocommit** — commits anything left uncommitted as a safety net, and
     pushes only when the current branch already has an upstream and is ahead
     of it. Never force-pushes, never rewrites history, always exits 0.
3. Offers one more hook as a **separate, opt-in choice — never installed by
   default**, with its consequences spelled out first:
   - **progress-check** — if a round changed files but `progress.md` wasn't
     updated, it blocks the stop once with a reminder so Claude (which has the
     context) refreshes the snapshot and commits. Trade-off: some rounds
     take one extra beat, and it can also fire on your own manual edits. It
     never loops and never writes content itself.
4. Records a per-round routine in the project's `CLAUDE.md` so future sessions
   keep `progress.md`, `plan.md`, etc. current and write meaningful commit
   messages. `progress.md` is maintained as a **snapshot of the current state**
   — completed, superseded, and fixed items get deleted, not accumulated;
   history stays in `git log`.

Cross-platform: every hook ships as both bash (`.sh`, macOS/Linux) and
PowerShell (`.ps1`, Windows).

## Install

Clone into your personal Claude Code skills directory:

**macOS / Linux**

```bash
git clone https://github.com/hfjddjksaj/auto-git.git ~/.claude/skills/auto-git
```

**Windows (PowerShell)**

```powershell
git clone https://github.com/hfjddjksaj/auto-git.git "$env:USERPROFILE\.claude\skills\auto-git"
```

Then start a **new** Claude Code session in any code project and say something
like *"set up auto-git"* / *"开启自动提交"* — or just start building; the skill
triggers automatically when a new code project is scaffolded. The hooks are
only ever installed per-project, and only after you approve them.

**Update later:**

```bash
git -C ~/.claude/skills/auto-git pull
```

## Layout

```
SKILL.md                      # the skill definition Claude Code loads
scripts/
  autocommit.sh / .ps1        # Stop hook: commit safety net + safe push
  progress-check.sh / .ps1    # Stop hook: stale-progress.md reminder
assets/
  gitignore-base.txt          # universal .gitignore starting point
  progress-template.md        # progress.md template
references/
  gitignore-languages.md      # per-language .gitignore blocks
```

## Safety rules

- Local-first: only ever **adds** commits — no reset, rebase, amend, or
  force-push.
- Pushes only when an upstream is already configured and the branch is ahead.
- Secrets block in `.gitignore` is mandatory; hooks respect `.gitignore`.
- Hooks always exit 0 — they can never block or break your session.

## License

[MIT](LICENSE)

---

## 中文说明

这是一个 Claude Code skill：为代码项目提供每轮自动 git 提交的安全网 ——
每一轮的工作都会被提交，永远不会丢失，并自动维护 `progress.md` 等进度文件。

**安装**（macOS / Linux）：

```bash
git clone https://github.com/hfjddjksaj/auto-git.git ~/.claude/skills/auto-git
```

Windows（PowerShell）：

```powershell
git clone https://github.com/hfjddjksaj/auto-git.git "$env:USERPROFILE\.claude\skills\auto-git"
```

装好后，在任意代码项目里**新开**一个 Claude Code 会话，说"开启自动提交"即可；
新建项目时 skill 也会自动触发。autocommit hook（兜底提交/推送）只会装进具体
项目，且安装前会征求你的同意；progress-check（进度提醒）是**可选项** ——
安装时会单独询问并先说明后果，不同意就不装，默认不启用。

更新：`git -C ~/.claude/skills/auto-git pull`
