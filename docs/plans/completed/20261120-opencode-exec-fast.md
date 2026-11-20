# opencode exec-fast mode

> **Revision after first use (2026-11-20):** the per-task checkpoint question was removed. The mode now runs uninterrupted, prints a progress block per task, and offers one optional review pass after the last task. Everything else below — isolation, one commit per task, finalize — still applies; the "checkpoint / Continue-Fix-Stop" wording is the original design.

## Overview

- `/planning/exec` is autonomous but slow: after the task loop it runs three review phases (5-agent fanout repeated up to 5 times, smells pass, critical pass), plus stats. For a model with a 1M-token context that review machinery dominates wall time.
- Add a second, additive execution mode: one primary agent implements the plan directly in a single context, commits one task at a time, and pauses after each task for the user to review the commit. No automated review phases, no stats, no progress file.
- The existing autonomous path (`executor`, `implementer`, `reviewer`, `exec` skill, its prompts and scripts) stays untouched. Only new files plus one option added to `make.md`.

## Context (from discovery)

- Files live in `common/home/.config/opencode/` (dotfiles repo, stowed to `~/.config/opencode/`). All edits go through the repo paths.
- Current exec chain: `commands/planning/exec.md` → `agents/executor.md` → `skills/exec/SKILL.md`. Review phases are SKILL steps 7–9; finalize is step 10; stats is step 11; completion is step 12.
- Reusable scripts (do not modify): `skills/exec/scripts/detect-branch.sh`, `create-branch.sh`, `stage-and-commit.sh`, `move-plan.sh`. Custom rules loader: `~/.config/opencode/scripts/resolve-rules.sh`.
- Worktree plumbing: `worktree_create`, `worktree_remove`, `session_move` tools (Code Mode `opencode` namespace), `worktree.directory = .lane/trees` in `opencode.json`. An unrelated worktree `opencode-agents-polish` exists; do not touch it.
- Config discovery verified today: `XDG_CONFIG_HOME=<repo>/common/home/.config opencode debug agents --standalone` and `opencode debug config` return the repo's config without stowing. This is the parse check to use in the worktree.
- `stage-and-commit.sh` commits with `-m <message>` and explicit file paths. A message of the form `fixup! <subject>` is enough for `git rebase --autosquash` to fold that commit into its task commit.

## Development Approach

- **testing approach**: not applicable — this is markdown/frontmatter/config only, with no test framework in the dotfiles repo and no runtime code added. Each task verifies by content inspection and cross-file reference consistency; the final task parses the config with `opencode debug agents` / `debug config`.
- complete each task fully before moving to the next
- make small, focused changes; do not refactor the exec workflow while adding this mode
- **CRITICAL**: do not touch `agents/executor.md`, `agents/implementer.md`, `agents/reviewer.md`, `skills/exec/**`, `commands/planning/exec.md` — the fast mode must not change autonomous behavior
- **CRITICAL**: update this plan file when scope changes during implementation

## Testing Strategy

- **unit tests**: none — no code. Do not add test scaffolding for prompt files.
- **config parse**: `XDG_CONFIG_HOME="$(git rev-parse --show-toplevel)/common/home/.config" opencode debug agents --standalone` must exit 0 and list `builder` (primary) with the pinned model.
- **cross-reference sweep**: every agent/command/skill/script path mentioned in the new files must exist (or be produced by a named task); `rg` for `exec-fast`, `builder`, and any stale `progress`/`stats` references.
- **manual interactive smoke run**: post-completion, because the executor implementing this plan cannot answer the new Checkpoint questions.

## Progress Tracking

- mark completed items with `[x]` immediately when done
- add newly discovered tasks with ➕ prefix
- document issues/blockers with ⚠️ prefix
- update plan if implementation deviates from original scope
- keep plan in sync with actual work done

## Solution Overview

- **`agents/builder.md`** — new primary agent. Full edit rights, shell with the same destructive-command guards as `implementer`, subagents denied, model `opencode-go/deepseek-v4.1-flash#high`. Prompt: implement directly, one task per checkpoint, never spawn reviews.
- **`commands/planning/exec-fast.md`** — `/planning/exec-fast <plan>` with `agent: builder`; loads the new skill.
- **`skills/exec-fast/SKILL.md`** — self-contained workflow: plan resolution, resume detection, isolation question, branch/worktree setup, per-task loop, checkpoint question, fix handling, finalize with optional squash, completion report.
- **`commands/planning/make.md`** — third option in the "Implementation mode?" question: Fast.
- Deliberate trade-off: the worktree/branch setup block is duplicated from the exec skill instead of cross-referenced. A fast run must not load the huge exec skill, and coupling to another skill's step numbers is brittle.

## Technical Details

### builder agent (`agents/builder.md`)

Frontmatter:
- `description`: implements plan tasks in the current context, one checkpoint per task
- `mode: primary`
- `model: opencode-go/deepseek-v4.1-flash#high`
- permissions: edit allow `*`; shell allow `*`; shell ask for `git push *`, `git reset --hard *`, `rm -rf *`; subagent deny `*`

Body must state:
- implement code, tests, and plan checkboxes yourself; you are the only implementer in this mode
- no subagents, no review phases, no stats, no extra tasks
- ask only at the checkpoints and edge-case questions defined by the `exec-fast` skill; no exploratory questions
- validate before every commit; never commit broken code
- never push/deploy; worktree removal or branch deletion only through the skill's explicit confirmation
- on Stop, leave branch and plan as they are and report state
- follow the `exec-fast` skill exactly

### command (`commands/planning/exec-fast.md`)

Frontmatter: `description: Execute a plan with per-task checkpoints and no automated reviews`, `agent: builder`.

Body: load the `exec-fast` skill and execute the plan at `$ARGUMENTS`; with no path, list `docs/plans/*.md` excluding `completed/` and ask which plan to run. Same shape as `commands/planning/exec.md`.

### exec-fast skill (`skills/exec-fast/SKILL.md`)

Frontmatter: `name: exec-fast`; description triggers on "exec-fast", "fast exec", "checkpointed plan execution", "execute a plan with per-task checkpoints".

**Startup**
1. Custom rules: run `bash ~/.config/opencode/scripts/resolve-rules.sh planning-rules.md ~/.config/opencode`; non-empty output is additional instruction for the whole run.
2. Resolve plan: explicit path wins; else `docs/plans/*.md` excluding `completed/`; one file → use it, several → `question`. Read the plan, count `### Task N:` / `### Iteration N:` sections. Default branch via `bash ~/.config/opencode/skills/exec/scripts/detect-branch.sh`.
3. Resume detection before creating anything:
   - derive `name=$(bash ~/.config/opencode/skills/exec/scripts/create-branch.sh --print-name <plan>)`
   - three states count as an existing run: current branch equals `name`; `git worktree list --porcelain` has a worktree on `refs/heads/<name>`; or the branch exists but is checked out nowhere (`git show-ref --verify --quiet refs/heads/<name>` succeeds). The third state matters: `create-branch.sh` would silently reuse the stale branch in-place, and `checkout -b` in a worktree would fail.
   - if found, ask **Resume / Start over**. Resume (worktree) calls `session_move` into the worktree and continues; Resume (in-place) checks out and continues here. Start over requires one explicit confirmation that covers commit loss and any local changes (on a dirty tree, warn and ask again); then discard: in-place `git checkout <default>` + `git branch -D <name>`; worktree mode `session_move` back to the main tree, `worktree_remove(directory, force: true)`, then `git branch -D <name>` — never remove a worktree the session sits in, and remove the branch separately because worktree removal leaves it behind. Recreate afterwards.
4. Isolation question, same two cases and semantics as exec SKILL Step 2 (on default branch: Worktree / In-place; on another feature branch: Run here / Create a new branch for this plan). Copy the question payloads; do not move an unrelated existing branch into a worktree.
   - Worktree mode: verify the plan is committed (`git ls-files --error-unmatch`, clean status); create via `worktree_create`, capture directory, `git -C <path> checkout <name>` when the branch already exists and `checkout -b <name>` only when it does not, then `session_move`, record main tree path/branch, and skip `create-branch.sh`. Guard: main tree branch must stay unchanged.
   - In-place mode: `create-branch.sh <plan>`.
5. No progress file, no init script, no stats.

**Task loop**
1. Re-read the first `### Task N:` / `### Iteration N:` section with `[ ]` checkboxes. None → finalize. Announce task title and its open checkboxes.
2. Implement every checkbox in that section, including tests required by the plan, then run the plan's validation commands.
3. Validation failure: fix and re-run, at most 2 attempts. Still failing → checkpoint with **Fix / Stop** only, showing the failing command and an error excerpt.
4. Mark `[x]` immediately, add `➕` for discovered tasks and `⚠️` for blockers. Never move/rename/delete the plan file, even if a checkbox says to; mark that checkbox `[x]` and leave the move to finalize.
5. Commit with `bash ~/.config/opencode/skills/exec/scripts/stage-and-commit.sh "feat: <task description>" <files...>` listing every changed file (source, tests, plan). Commit failure → fix and retry; no checkpoint without a commit.
6. Checkpoint output: task title, `git log -1 --format='%h %s'`, `git show --stat --format= <sha>`, a one-line decisions/deviations summary, and a warning listing `git status --porcelain` leftovers if non-empty. Then ask **Continue / Fix / Stop**.
   - Continue → loop.
   - Fix → collect the user's free-text note. Scope rules: out-of-scope note → ask **Add task / Fix here**; note contradicting the plan → ask **Update plan / Apply anyway**. Apply, validate, commit as `fixup! <task commit subject>` where the subject is copied verbatim from `git log -1 --format='%s'` — a paraphrased subject silently fails to fold and survives the autosquash rebase. Show the new stat, ask again.
   - Stop → report tasks done, branch, worktree path, validation state; stop without finalize.
7. In worktree mode, verify the main tree branch is unchanged before each checkpoint; any change → stop and report the isolation breach.
8. Question budget: only these checkpoints and edge-case questions. No exploratory questions.

**Finalize and completion**
1. `git fetch origin` then `git rebase origin/<default-branch>`. Repos without an origin: skip the fetch and rebase onto the local `<default-branch>`; a failed fetch warns and continues best-effort. Conflict → ask **Resolve / Abort**; Abort runs `git rebase --abort`, then reports and stops leaving the branch untouched.
2. Ask **Squash?** with three options:
   - **Fold fixups into their tasks** — `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>` (`origin/<default>` when it exists, otherwise local `<default>`); one commit per task remains. Conflict → same Resolve / Abort.
   - **Keep all commits** — leave history as produced.
   - **Squash everything into one** — `git reset --soft <base>` (`origin/<default>` when it exists, otherwise local `<default>`), then plain `git commit -m "feat: <plan H1 title>"`; everything is already staged, so `stage-and-commit.sh` and its file list do not apply. Keep the Conventional Commits type.
3. Run the plan's validation commands against the final history. Failure → report and stop; do not attempt rollback.
4. Move the plan with `bash ~/.config/opencode/skills/exec/scripts/move-plan.sh <plan>` — the script commits internally, so do not commit again (best-effort; report a non-zero exit without blocking).
5. Report: tasks completed, commit count and subjects, branch, worktree path if any, validation results, every judgment call/deviation made without asking, squash result. No stats script, no progress file, no push.

### make.md

In the "Implementation mode?" question add a third option:

```json
{"label": "Fast", "description": "Run /planning/exec-fast for checkpointed, single-context execution without auto-reviews"}
```

Add the matching workflow bullet: **Fast** → tell the user to run `/planning/exec-fast <plan-file-path>`; never invoke the command directly.

## What Goes Where

- **Implementation Steps** (`[ ]` checkboxes): creating the agent, command, skill, make.md option, config parse verification.
- **Post-Completion** (no checkboxes): stow after merge, interactive smoke run, manual validation of checkpoint/squash paths.

## Implementation Steps

### Task 1: Add builder agent

**Files:**
- Create: `common/home/.config/opencode/agents/builder.md`

- [x] frontmatter: `description`, `mode: primary`, `model: opencode-go/deepseek-v4.1-flash#high`
- [x] permissions: edit allow `*`; shell allow `*`; shell ask `git push *`, `git reset --hard *`, `rm -rf *`; subagent deny `*`
- [x] body: single-window boundaries (implement yourself, no subagents/reviews, checkpoints only, validate before commit, never push, stop semantics, follow the `exec-fast` skill)
- [x] verify the frontmatter matches the shape of `agents/implementer.md` + `mode: primary`

### Task 2: Add exec-fast command

**Files:**
- Create: `common/home/.config/opencode/commands/planning/exec-fast.md`

- [x] frontmatter: `description: Execute a plan with per-task checkpoints and no automated reviews`; `agent: builder`
- [x] body: load `exec-fast` skill, pass `$ARGUMENTS`; empty-argument fallback lists `docs/plans/*.md` excluding `completed/` and asks which plan
- [x] verify the command mirrors `commands/planning/exec.md` structure and names the skill/agent exactly

### Task 3: Skill startup, resume, and isolation

**Files:**
- Create: `common/home/.config/opencode/skills/exec-fast/SKILL.md`

- [x] frontmatter: `name: exec-fast`, description triggering on "exec-fast" / "fast exec" / "checkpointed plan execution"
- [x] arguments + plan resolution + task counting + `detect-branch.sh`, matching exec semantics
- [x] custom rules loading via `resolve-rules.sh planning-rules.md` at start
- [x] resume detection for all three states (current branch, worktree on the branch, branch exists but checked out nowhere) with **Resume / Start over**; Start over needs one explicit confirmation covering commit loss and dirty-tree changes, then moves the session out before `worktree_remove(force: true)` and deletes the branch separately
- [x] isolation question (both exec cases) and worktree/in-place setup copied from exec Step 2–4 semantics: plan-committed check, `worktree_create` + `checkout` when the branch exists / `checkout -b` when it does not + `session_move`, skip `create-branch.sh` in worktree mode, main-tree isolation guard, in-place `create-branch.sh`
- [x] explicit statement: no progress file, no stats, no review phases

### Task 4: Skill task loop and checkpoints

**Files:**
- Modify: `common/home/.config/opencode/skills/exec-fast/SKILL.md`

- [x] per-task loop: re-read the current task section, announce, implement all checkboxes, write plan-required tests, run plan validation
- [x] validation failure: max 2 fix attempts, then **Fix / Stop** checkpoint with failing command and error excerpt
- [x] checkbox discipline: mark `[x]` immediately, `➕` new tasks, `⚠️` blockers, never move/rename/delete the plan file
- [x] commit every task with `stage-and-commit.sh` and explicit file list; no checkpoint without a commit; no commit on failing validation
- [x] checkpoint output: task title, `git log -1 --format='%h %s'`, `git show --stat`, decisions/deviations line, uncommitted-leftovers warning
- [x] **Continue / Fix / Stop** question semantics; Stop reports state and skips finalize
- [x] Fix path: free-text note; **Add task / Fix here** for out-of-scope; **Update plan / Apply anyway** for plan contradictions; commit as `fixup! <subject copied verbatim from git log -1 --format='%s'>`; re-validate; show new stat; ask again
- [x] worktree isolation guard before each checkpoint; question budget rule (no exploratory questions)

### Task 5: Skill finalize and completion

**Files:**
- Modify: `common/home/.config/opencode/skills/exec-fast/SKILL.md`

- [x] `git fetch origin` + `git rebase origin/<default>` with an origin-less/offline fallback (rebase onto local `<default>`; failed fetch warns and continues); conflict → **Resolve / Abort**, Abort runs `git rebase --abort` and stops with the branch untouched
- [x] squash question with three options: fold fixups (`GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>`), keep all commits, squash everything (`git reset --soft <base>` + plain `git commit -m "feat: <plan H1>"` with everything staged)
- [x] run plan validation against final history; failure → report and stop without rollback
- [x] move plan with `move-plan.sh` (it commits internally — no second commit), best-effort, non-blocking on failure
- [x] completion report: tasks, commits count/subjects, branch, worktree path, validation, autonomous decisions/deviations, squash result; explicitly no push, no stats, no progress file

### Task 6: Add Fast option to make.md

**Files:**
- Modify: `common/home/.config/opencode/commands/planning/make.md`

- [x] add the third option to the "Implementation mode?" question payload
- [x] add the **Fast** workflow bullet: tell the user to run `/planning/exec-fast <plan-file-path>`; do not invoke it directly
- [x] leave Interactive and Autonomous options and bullets unchanged

### Task 7: Verify acceptance criteria

- [x] cross-reference sweep: `rg -n 'exec-fast|builder' common/home/.config/opencode` — names match filenames, every script path mentioned exists
- [x] confirm no stale `progress`/`stats`/`init-progress`/`append-progress` references inside `skills/exec-fast/SKILL.md` (only explicit "no progress/stats" statements remain)
- [x] confirm `git diff --stat` shows no modifications under `agents/executor.md`, `agents/implementer.md`, `agents/reviewer.md`, `skills/exec/**`, `commands/planning/exec.md`
- [x] config parse: `XDG_CONFIG_HOME="$(git rev-parse --show-toplevel)/common/home/.config" opencode debug agents --standalone` exits 0 and lists `builder` as primary with `deepseek-v4.1-flash#high`
- [x] config parse: `XDG_CONFIG_HOME="$(git rev-parse --show-toplevel)/common/home/.config" opencode debug config` exits 0
- [x] read the full `skills/exec-fast/SKILL.md` against this plan's Technical Details — every checkpoint, squash option, and edge case present

## Post-Completion

*Items requiring manual intervention or external systems — no checkboxes, informational only*

**Manual verification**:
- After merging to `main`, run `scripts/stow_pc.sh` from the main tree so `~/.config/opencode/agents/builder.md`, `commands/planning/exec-fast.md`, and `skills/exec-fast/` become visible. New files are not stowed from a worktree.
- Interactive smoke run in a scratch repo against a tiny 2-task plan (no origin is fine — exercise the origin-less finalize fallback): verify the isolation question, per-task checkpoint (Continue), one Fix round ending in a `fixup!` commit, Stop/resume, and all three squash options at finalize.
- Confirm no review or stats subagents are spawned during the fast run (session tree has zero subagents).
- Confirm `/planning/exec` behavior is unchanged on an existing plan.

**Deliberate decisions**:
- No progress file and no stats in fast mode: the plan checkboxes, commits, and the single session are the record. Resume after a long gap relies on commit messages and the plan.
- Worktree/branch setup is duplicated from the exec skill rather than cross-referenced, so a fast run never loads the exec skill.
- Fix rounds are unlimited because the user is present; there is no artificial cap beyond validation retries.
