---
name: exec-fast
description: "Execute a plan in one context without per-task prompts. Use when the user says 'exec-fast', 'fast exec', or wants uninterrupted plan execution for simpler tasks, with an optional one-pass review."
---

# exec-fast

Execute plan tasks in the current session without pausing between them. You implement directly: no task subagents, no automated review loops, no stats, no progress file. Work runs uninterrupted; one optional review pass may run after the last task. Report progress as you go.

## Arguments

- `$ARGUMENTS` — path to the plan file, supplied by the `/planning/exec-fast` command. If it is missing, ask the user to pick from `docs/plans/` (excluding `completed/`).

## Startup

### 1. Load custom rules

Run:

```bash
bash ~/.config/opencode/scripts/resolve-rules.sh planning-rules.md ~/.config/opencode
```

Non-empty output is additional instruction for the whole run. Apply it alongside this skill; it may affect plan interpretation, naming, and validation commands.

### 2. Resolve the plan

- An explicit path wins.
- Otherwise list `docs/plans/*.md` excluding `completed/`. One file → use it automatically. Several → ask with the `question` tool.
- Read the plan and count `### Task N:` / `### Iteration N:` sections.
- Detect the default branch:

```bash
bash ~/.config/opencode/skills/exec/scripts/detect-branch.sh
```

### 3. Detect an existing run

Derive the branch name with no git side effects:

```bash
name=$(bash ~/.config/opencode/skills/exec/scripts/create-branch.sh --print-name <plan-file-path>)
```

An existing run exists when any of these holds:

- `git branch --show-current` equals `$name`
- `git worktree list --porcelain` lists a worktree on `refs/heads/$name`
- `git show-ref --verify --quiet refs/heads/$name` succeeds although the branch is checked out nowhere

The third state matters: `create-branch.sh` would silently reuse the stale branch in-place, and `checkout -b` would fail in a worktree.

If found, ask **Resume / Start over**.

- **Resume** — worktree: call `session_move` into that worktree directory and continue there. In-place: `git checkout "$name"` if not already on it. Skip step 4 and go to the task loop.
- **Start over** — ask one explicit confirmation that names both losses: commits on the branch and uncommitted changes. If `git status --porcelain` is non-empty, warn and ask again. Then discard:
  - in-place: `git checkout <default-branch>` then `git branch -D "$name"`
  - worktree: `session_move` back to the main tree first, then `worktree_remove({ directory, force: true })`, then `git branch -D "$name"`. Never remove a worktree the session sits in; worktree removal leaves the branch behind.

Continue with step 4.

### 4. Isolation question

Ask where the work runs. Do not decide for the user.

**On the default branch:**

```json
{
  "questions": [{
    "question": "Where should the feature branch be created?",
    "header": "Branch location",
    "options": [
      {"label": "Worktree (isolated)", "description": "Create the feature branch in a new isolated git worktree under the configured worktree.directory. Main working directory stays on the default branch."},
      {"label": "In-place", "description": "Create the feature branch in this working directory. Main directory switches to the feature branch for the duration of the run."}
    ],
    "multiple": false
  }]
}
```

**On another feature branch:**

```json
{
  "questions": [{
    "question": "You're already on a feature branch. Run the plan here, or in a new worktree branch?",
    "header": "Isolation",
    "options": [
      {"label": "Run here", "description": "Run the plan in this working directory on the current branch."},
      {"label": "New worktree branch", "description": "Create this plan's branch from the current HEAD in a new isolated worktree. The current branch is not moved."}
    ],
    "multiple": false
  }]
}
```

**Worktree mode:**

1. Record `main_tree=$(git rev-parse --show-toplevel)` and `main_branch=$(git branch --show-current)`.
2. Verify the plan is committed: `git ls-files --error-unmatch <plan-file-path>` must succeed and `git status --porcelain <plan-file-path>` must be empty. If not, commit it first.
3. Create the worktree with the native `worktree_create` tool (Code Mode namespace `opencode`), passing `<name>`; capture the returned `directory` as `worktree_path`.
4. Inside it, use `git -C <worktree_path> checkout "$name"` when the branch already exists, otherwise `git -C <worktree_path> checkout -b "$name"`. Never commit on the detached HEAD `worktree_create` leaves.
5. Move the session with `session_move({ directory: <worktree_path> })`. It takes effect at a safe boundary; do later, destination-dependent work in a later step.
6. In worktree mode the in-place branch creation is skipped entirely. Guard: `git -C "$main_tree" branch --show-current` must still equal `main_branch`.

**In-place mode:**

```bash
bash ~/.config/opencode/skills/exec/scripts/create-branch.sh <plan-file-path>
```

Use the branch name it prints. If the current branch is already a feature branch, the script stays on it.

### 5. No other setup

No progress file, no `init-progress.sh`, no `append-progress.sh`, no stats. The only review is the single optional pass after the last task.

## Task loop

Repeat until no Task section has `[ ]` checkboxes. Do not ask the user between tasks.

1. Read the plan. Find the first `### Task N:` / `### Iteration N:` section with `[ ]` checkboxes. Re-read that section immediately before implementing it. If none remains, go to Finalize.
2. Announce the task title and list its open checkboxes.
3. Implement every checkbox in the section, including the tests the plan requires. Run the plan's validation commands.
4. Validation failure: fix and re-run, at most 2 attempts. Still failing → stop the run and report the failing task, the failing command, an error excerpt, and the branch state. Do not ask, and do not continue to another task.
5. Mark `[x]` immediately for each completed item. Add `➕` for discovered tasks and `⚠️` for blockers. Never move, rename, or delete the plan file, even when a checkbox says to move it; mark that checkbox `[x]` and leave the move to Finalize.
6. Commit once the task is green:

```bash
bash ~/.config/opencode/skills/exec/scripts/stage-and-commit.sh "feat: <task description>" <files...>
```

List every changed file (source, tests, plan). Never commit on failing validation. A failed commit → fix and retry; a task is not done without a commit.

7. After the commit print one progress block and continue immediately:
   - `Task N: <title> — <sha> <subject>` from `git log -1 --format='%h %s'`
   - `git show --stat --format= <sha>` or a one-line summary of it
   - one line of decisions/deviations made without asking (or `none`)
   - if `git status --porcelain` is non-empty, a warning listing the leftover paths
   No question, no pause.
8. In worktree mode, check `git -C "$main_tree" branch --show-current` after each task; if it no longer equals `main_branch`, stop and report the isolation breach.

## Mid-run corrections

If the user sends a correction while the run is active:

- apply it, validate, and commit as `fixup! <subject>`, where `<subject>` is copied verbatim from `git log -1 --format='%s'` of the related task commit; use a normal `fix:` commit when it relates to no task.
- show the new `git show --stat` and continue the task loop.

There is no dedicated fix checkpoint; the user speaks only if they choose to.

## Interruptions

Ask only when a real decision cannot be settled safely:

- startup: plan selection, **Resume / Start over**, isolation
- the optional end-of-run review choice
- a destructive action beyond the skill's confirmed paths
- missing external input (credentials, unavailable service) that blocks the current task
- a requirement so ambiguous that any choice would risk unrelated work

Everything else — naming, structure, file splits, scope judgment, plan contradictions, out-of-scope discoveries — decide from the plan, `AGENTS.md`, the project's lint rules, and the dominant surrounding pattern. Take the smaller, reversible option when torn. Log each decision or deviation and report it at completion.

Never ask exploratory questions.

## Optional review

Only after the task loop has no `[ ]` checkboxes left, ask once before finalize:

```json
{
  "questions": [{
    "question": "Run an automated review of the whole branch before finalize?",
    "header": "Review",
    "options": [
      {"label": "No review (Recommended)", "description": "Go straight to rebase, fixup folding, validation, and the plan move."},
      {"label": "Comprehensive (5 agents, one pass)", "description": "Parallel quality, implementation, testing, simplification, documentation reviewers. You fix confirmed findings yourself, then finalize. One pass only."},
      {"label": "Critical only (2 agents)", "description": "Parallel quality and implementation reviewers restricted to critical and major issues."}
    ],
    "multiple": false
  }]
}
```

**No review** → go to Finalize.

**Review** → run exactly one pass, after all tasks and before finalize:

1. Resolve the playbook and specialist prompts through the exec override chain:

```bash
bash ~/.config/opencode/skills/exec/scripts/resolve-file.sh prompts/review.md ~/.config/opencode/exec-plan
bash ~/.config/opencode/skills/exec/scripts/resolve-file.sh agents/quality.txt ~/.config/opencode/exec-plan
```

Follow the playbook from this session with these overrides:

- `REVIEW_PHASE`: `comprehensive` for 5 agents, `critical` for 2
- `DEFAULT_BRANCH`: the detected default branch
- `PLAN_FILE_PATH`: the plan path
- there is no progress file: omit `PROGRESS_FILE_PATH` and the paragraph telling reviewers to read it
- **you are the fixer**: do not spawn an implementer; verify and fix confirmed findings yourself

2. Launch all reviewer calls in one response so they run in parallel. Every call uses `agent: "reviewer"`.
3. Collect every finding verbatim. Verify each one against the code at the cited location and mark it confirmed or false positive with a reason. Fix the confirmed issues, run the plan's validation commands, and commit as `fix: address review findings`.
4. Report the findings and what you fixed. This is a single pass: do not launch a second review, and do not loop.

You wrote this code; judge each finding on the code, not on the fact that you wrote it.

## Finalize

1. Determine `<base>`: `origin/<default-branch>` when `git rev-parse --verify origin/<default-branch>` succeeds, otherwise the local `<default-branch>`. When origin exists, run `git fetch origin` first; a failed fetch warns and continues best-effort.
2. `git rebase <base>`. Resolve conflicts yourself when the resolution follows the plan, `AGENTS.md`, or the surrounding code unambiguously. If a conflict is not safe to resolve, run `git rebase --abort`, report, and stop with the branch untouched. Do not ask.
3. Fold fixup commits automatically:

```bash
GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>
```

If conflicts arise, apply the same rule as step 2.

4. Run the plan's validation commands against the final history. Failure → report and stop; do not attempt rollback.
5. Move the plan:

```bash
bash ~/.config/opencode/skills/exec/scripts/move-plan.sh <plan-file-path>
```

The script commits internally; do not commit again. A non-zero exit is reported but does not block completion.

6. Report: tasks completed, commit count and subjects, branch, worktree path if any, validation results, every judgment call or deviation made without asking, the review outcome (skipped, or findings/fixed/false-positive counts), and that fixups were folded. No push, no stats, no progress file. If the user prefers all commits kept or a single squashed commit, say they can request that after the run.

## Key rules

- Never pause between tasks; one progress block per task.
- The plan file is the only progress state; mark checkboxes immediately.
- You implement, validate, and commit yourself.
- No subagents except the read-only reviewers in the single optional review pass.
- Ask only when blocked; decide and log everything else.
- In worktree mode the main working directory is never touched: no branch is created or checked out there, and no changes land there.
