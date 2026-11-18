---
name: exec
description: "Execute plan tasks sequentially using subagents. Use when user says 'exec', 'execute plan', 'run plan', or wants to implement a plan file task by task with isolated subagents."
---

# exec

Execute plan file tasks sequentially, each in an isolated subagent.

## Arguments

- `$ARGUMENTS` — path to the plan file, supplied by the `/planning/exec` command. If it is missing, ask the user to pick from `docs/plans/` (excluding `completed/`).

## File Resolution

ALWAYS use the resolve script to read prompt and agent files. NEVER construct the override chain manually:
```
bash ~/.config/opencode/skills/exec/scripts/resolve-file.sh prompts/task.md ~/.config/opencode/exec-plan
bash ~/.config/opencode/skills/exec/scripts/resolve-file.sh agents/quality.txt ~/.config/opencode/exec-plan
```
The script checks three layers, first match wins:
1. Project override: `.opencode/exec-plan/<path>`
2. User override: `~/.config/opencode/exec-plan/<path>`
3. Bundled default: `~/.config/opencode/skills/exec/references/<path>`

To customize a bundled prompt or agent file, copy it to an override path with the helper, then edit the copy:
```
bash ~/.config/opencode/skills/exec/scripts/customize-file.sh prompts/review.md
bash ~/.config/opencode/skills/exec/scripts/customize-file.sh prompts/review.md ~/.config/opencode/exec-plan
```
The first form writes a project override, the second a user override. An override shadows the bundled file permanently and stops tracking changes to it; delete it to fall back.

### Placeholder Substitution

After reading a prompt file, replace ALL placeholders with actual values before passing to a subagent. Subagents run in fresh contexts without plugin env vars.

Always substitute: `PLAN_FILE_PATH`, `PROGRESS_FILE_PATH`, `DEFAULT_BRANCH`, `RESOLVE_SCRIPT` (absolute path to `~/.config/opencode/skills/exec/scripts/resolve-file.sh`), `PLUGIN_DATA_DIR` (`~/.config/opencode/exec-plan`, passed as the second argument to resolve-file.sh so it can find user overrides), `USER_RULES` (resolved custom rules content from the rules loading step, or an empty string if no rules found), and the phase-specific values (`FINDINGS_LIST`, `REVIEW_PHASE`).

## Custom Rules Loading

Before starting execution, run this command via Bash tool to check for user-provided custom rules:

```bash
bash ~/.config/opencode/scripts/resolve-rules.sh planning-rules.md ~/.config/opencode
```

If the output is non-empty, store it as the resolved custom rules content. When substituting `USER_RULES` in task prompts, wrap the content with a label so the subagent understands it: use "ADDITIONAL CUSTOM RULES:\n<content>" as the substitution. If the output is empty, substitute an empty string for `USER_RULES`. See `~/.config/opencode/skills/exec/references/custom-rules.md` for full documentation on the rules mechanism.

## Process

### Step 1. Resolve plan file

If `$ARGUMENTS` contains a file path, use it. Otherwise, list `.md` files in `docs/plans/`, excluding `completed/`. If exactly one plan found, use it automatically. If multiple found, ask the user to pick one with the `question` tool.

Read the plan file. Count total Task sections (`### Task N:` or `### Iteration N:`) to know the scope.

Determine the default branch: `bash ~/.config/opencode/skills/exec/scripts/detect-branch.sh`

### Step 2. Ask about worktree isolation

First detect the current branch state — run `git branch --show-current` and compare with the default branch detected earlier (from `detect-branch.sh`). Two cases:

**Case A — currently on the default branch (master/main/trunk).** Step 4 will create a new feature branch. Ask the user where it should live. Invoke the **`question`** tool with this payload:

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

**Case B — currently on a feature branch.** Step 4 will keep using this branch. Ask whether to move it to an isolated worktree or stay here. Invoke the **`question`** tool with this payload:

```json
{
  "questions": [{
    "question": "You're already on a feature branch. Run the plan here, or in an isolated worktree?",
    "header": "Isolation",
    "options": [
      {"label": "Stay here", "description": "Run the plan in this working directory, on the existing feature branch."},
      {"label": "Move to worktree", "description": "Copy this branch into a new isolated git worktree under the configured worktree.directory. Main directory stays untouched."}
    ],
    "multiple": false
  }]
}
```

In BOTH cases: invoke the `question` tool **now**, do not generate text first, do not skip, do not assume. The choice affects the user's working directory and the orchestrator cannot decide on their behalf.

**If the user picks "Worktree (isolated)" or "Move to worktree"** — the main working directory MUST NOT be touched at all: no branch is created or checked out there, and no file changes land there. That isolation is the entire point of this mode. Set `worktree_mode = true` and do this:

1. Record the main tree's path and current branch so you can verify it stayed untouched: `main_tree=$(git rev-parse --show-toplevel)` and `main_branch=$(git branch --show-current)`.
2. **Verify the plan is committed.** A worktree is a checkout from HEAD, so an uncommitted plan will not exist there. `git ls-files --error-unmatch <plan-file-path>` must succeed and `git status --porcelain <plan-file-path>` must be empty. If the plan is not committed, commit it first (the make command does this when implementation starts), then continue.
3. Derive the feature branch name with NO git side effects: `name=$(bash ~/.config/opencode/skills/exec/scripts/create-branch.sh --print-name <plan-file-path>)`.
4. Create the worktree with the native `worktree_create` tool (Code Mode namespace `opencode`), passing `<name>` as the name. It returns `{ directory }`; capture it as `worktree_path`. The destination comes from the global `worktree.directory` setting, not from this skill.
5. Create the branch inside the worktree: `git -C <worktree_path> checkout -b <name>`. `worktree_create` leaves a detached HEAD; do not commit on it.
6. Move the session into the worktree: `session_move({ directory: <worktree_path> })`. It takes effect at a safe boundary, so destination-dependent work belongs in a later step. Do not use `cd` as a substitute — tool calls, config discovery, and instruction files must resolve against the worktree.
7. **This means Step 4 (create-branch.sh) is SKIPPED** — the branch already exists inside the worktree. Running create-branch.sh here would `git checkout -b` in the main tree and break isolation.
8. **Isolation guard**: verify the main tree is untouched — `git -C "$main_tree" branch --show-current` MUST still equal `main_branch`. If it changed, STOP and report the isolation breach instead of continuing.
9. Every later step (task execution, reviews, finalize, the plan move) runs inside the worktree; use `<name>` wherever a branch name is needed. At completion, report `worktree_path` and `<name>` so the user can review and merge.

**If the user picks "In-place" or "Stay here"** — set `worktree_mode = false` and proceed normally; Step 4 creates the branch in this working directory.

### Step 3. Task list

The plan is the task list. There is no separate todo tool in this workflow.

- Each `### Task N:` section plus the review phases is tracked directly in the plan.
- Mark completed checkboxes `[x]` immediately; add newly discovered tasks with `➕`; add blockers with `⚠️`.
- Do not create a second task list that can drift from the plan. The plan checkboxes and the progress file are the only progress state.

### Step 4. Create branch

**Skip this step entirely when `worktree_mode` is true** — Step 2 already created the branch (`<name>`) inside the isolated worktree, and running this here would `git checkout -b` in the main working tree and break isolation. Carry `<name>` forward as the branch name and go to Step 5.

Otherwise (in-place mode), **MANDATORY**: run the script below. Do NOT create the branch manually — the script strips the date prefix from the plan filename (e.g., `20260329-feature-name.md` → branch `feature-name`).

```
bash ~/.config/opencode/skills/exec/scripts/create-branch.sh <plan-file-path>
```

The script creates a feature branch if currently on main/master, or stays on the current branch if already on a feature branch. Capture and use the branch name it outputs.

### Step 5. Initialize progress file

Initialize the progress file: `bash ~/.config/opencode/skills/exec/scripts/init-progress.sh /tmp/progress-<plan-name>.txt <plan-file-path> <branch-name>` (derive `<plan-name>` from the plan file stem, e.g., `fix-issues.md` → `progress-fix-issues`). The script creates the file with a header. Report the full progress file path to the user.

IMPORTANT: Always use `~/.config/opencode/skills/exec/scripts/append-progress.sh` to write to the progress file after initialization. Never write directly.

### Step 6. Task loop

Repeat until no `[ ]` checkboxes remain in any Task section:

1. **Re-read the plan file** (subagent modifies it each iteration)
2. **Find the first Task section** (`### Task N:` or `### Iteration N:`) that still has `[ ]` checkboxes
3. **If none found** — all tasks complete, go to step 7
4. **Announce the task to the user** — before spawning the subagent, output a visible summary:
   - Task number and title (from the `### Task N:` header)
   - List all `[ ]` checkbox items in that task section
   - Example output:
     ```
     --- Task 1: Fix error handling ---
     - [ ] Handle the error from os.ReadFile
     - [ ] Either log and exit or handle gracefully
     ```
5. **Spawn a subagent** using the `subagent` tool with:
   - `agent: "implementer"`
   - The task prompt from `prompts/task.md`, with all placeholders substituted as described in the Placeholder Substitution section above (including `USER_RULES`)
6. **After subagent returns**, re-read the plan file and check if that task's checkboxes are now `[x]`
   - If yes — task succeeded, continue loop
   - If no — **retry** with a fresh subagent for the same task up to 1 time. If the retry fails, stop and report failure to user
7. **Report to user**: "Task N completed" (one line). The task subagent logs details to the progress file.

CRITICAL: Spawn exactly ONE task subagent per iteration and WAIT for it to return before starting the next. NEVER batch-spawn multiple task subagents in a single message. Plan tasks are ordered and interdependent — later tasks build on the files earlier tasks create, and every task subagent edits the same plan-file checkboxes and overlapping source files, so running them in parallel corrupts the plan and the working tree. The "launch in a single message for parallel execution" instruction applies ONLY to the review phases (steps 7 and 9), never to this task loop.

CRITICAL: Do NOT stop the loop based on subagent return text. The ONLY condition to stop is: no `[ ]` checkboxes remain in any Task section (`### Task N:` or `### Iteration N:`). Always re-read the plan file to check.

CRITICAL: You are the ORCHESTRATOR. Never read code, debug errors, investigate diagnostics, or fix issues yourself. If a subagent leaves problems (compiler errors, test failures, lint issues), retry with a fresh subagent — pass the error details in the prompt so it can fix them. All code work happens inside subagents, not in the orchestrator.

Maximum iterations safety limit: 50. If reached, stop and report to user.

### Step 7. Review phase 1 — comprehensive then critical re-check

After all tasks complete, run a comprehensive code review on iteration 1, then narrow to critical-only re-checks on subsequent iterations to verify the fixer's work without re-running the full heavy sweep.

Report to user: "--- Review phase 1: comprehensive ---"

Loop up to 5 times. Track the current iteration number:

1. **Read review.md as a playbook (NOT as a subagent prompt)** — resolve `prompts/review.md` through the override chain and read it from this main session. It tells YOU (the orchestrator) which specialist agents to fan out for the current `REVIEW_PHASE`. Substitute `DEFAULT_BRANCH`, `PLAN_FILE_PATH`, `PROGRESS_FILE_PATH`, `~/.config/opencode`, and `REVIEW_PHASE` in the resolved content. Then follow the playbook FROM THIS SESSION: launch the specified `subagent` calls in a single message for parallel execution. Subagents cannot launch more subagents, so the fanout MUST be initiated from the main orchestrator.
   - **Iteration 1**: set `REVIEW_PHASE` to `comprehensive`. Per the playbook, launch 5 parallel review agents (quality, implementation, testing, simplification, documentation).
   - **Iteration 2 and later**: set `REVIEW_PHASE` to `critical`. Per the playbook, launch 2 parallel review agents (quality, implementation) focused on critical/major issues only. Before this iteration, report to user: "--- Review phase 1: critical re-check (iteration N) ---"

2. **Collect findings** — collect findings from ALL launched review agents. Pass the COMPLETE output (not a summary) to the fixer. Do NOT summarize, filter, or dismiss any findings. ALL findings are actionable. Report to user with a short list of findings. Log to progress file:
   `bash ~/.config/opencode/skills/exec/scripts/append-progress.sh <progress-file> "review phase 1: findings"`
   Then pipe: `echo "<findings>" | bash ~/.config/opencode/skills/exec/scripts/append-progress.sh <progress-file>`

3. **If ALL agents reported zero issues** → report "Review phase 1: clean" and proceed to the next phase.

4. **Spawn a fixer agent** — resolve `prompts/fixer.md` through the override chain. Launch with `agent: "implementer"`. Pass the FULL unedited review output as FINDINGS_LIST — the fixer decides what's real, not you.

5. **After fixer returns** → show the "FIXES:" section to the user. Report "Review phase 1: iteration N fixes applied". Check for uncommitted changes: `git status --porcelain`. If output is non-empty, show every reported path and warn that these uncommitted changes are absent from the committed branch diff used by the next review. This is report-only: do not retry, abort, or commit leftovers because of this check. Loop back to step 1.

If 5 iterations are reached with issues still found, report "Review phase 1: max iterations reached, moving on" and continue.

### Step 8. Review phase 2 — code smells

Report to user: "--- Review phase 2: code smells analysis ---"

Run once (no loop):

1. **Spawn a smells agent** — resolve `agents/smells.txt` through the override chain. Launch one `subagent` call with `agent: "reviewer"` and the resolved agent prompt.

2. **Collect findings** — after the agent returns, report to user with a compact list of findings (one line per finding). Log findings to progress file:
   `bash ~/.config/opencode/skills/exec/scripts/append-progress.sh <progress-file> "review phase 2: findings"`
   Then pipe the findings: `echo "<findings>" | bash ~/.config/opencode/skills/exec/scripts/append-progress.sh <progress-file>`

3. **If no issues found** → report "Smells analysis: clean" and proceed to the next phase.

4. **Spawn a fixer agent** — resolve `prompts/fixer.md` through the override chain. Launch with `agent: "implementer"`. Pass the FULL smells output as FINDINGS_LIST.

5. **After fixer returns** → report fixes to user. Check for uncommitted changes: `git status --porcelain`. If output is non-empty, show every reported path and warn that these uncommitted changes are absent from the committed branch diff used by the next review. This is report-only: do not retry, abort, or commit leftovers because of this check. Proceed to the next phase.

### Step 9. Review phase 3 — critical only

Report to user: "--- Review phase 3: critical/major only (single pass) ---"

Same structure as step 7 but with `REVIEW_PHASE` set to `critical`. Resolve `prompts/review.md` and follow its playbook FROM THIS MAIN SESSION — launch 2 parallel `reviewer` subagents (quality, implementation) focusing on critical/major issues only. Subagents cannot launch more subagents, so the fanout MUST be initiated from the main orchestrator. Same fixer flow — pass findings to fixer, show FIXES to user.

### Step 10. Finalize

After all reviews pass, rebase and clean up commits. Finalize always runs — never ask the user whether to run it.

Report to user: "--- Finalize: rebase and clean up commits ---"

Spawn one `subagent` with `agent: "implementer"` and the prompt from `prompts/finalizer.md`. Replace `DEFAULT_BRANCH`, `PLAN_FILE_PATH`, and `PROGRESS_FILE_PATH`.

This is best-effort — if rebase fails, report the issue but don't block completion.

### Step 11. Run stats summary

Report to user: "--- Run stats ---"

Run the stats script directly from this session — it is one script, not a subagent job:

```
python3 ~/.config/opencode/skills/exec/scripts/stats.py "$OPENCODE_SESSION_ID" <default-branch> <progress-file>
```

`$OPENCODE_SESSION_ID` is this orchestrator session's id and is already set in the shell environment. Show the script's output to the user verbatim. This step is best-effort and non-blocking: if the script fails, report the failure in one line and continue to completion.

### Step 12. Completion

- **Report autonomous decisions and deviations to the user.** The run had no human to answer questions, so subagents decided judgment calls themselves and logged them. Collect every such entry from the progress file — `grep -E '^(\[[^]]*\] )?\[(decision|deviation)\]' <progress-file>` — and present them in a dedicated section titled **"Decisions made autonomously / Deviations from the plan"**, one bullet per entry with its stated reason, so the user learns every question the run answered on its own and why. If there are none, state "no autonomous decisions or deviations were logged." Do this even when finalize failed — completion is the guaranteed place the user always gets the report.
- Log completion to progress file: `bash ~/.config/opencode/skills/exec/scripts/append-progress.sh <progress-file> "completed"`
- Move the finished plan into its `completed/` subdirectory and commit it (best-effort): `bash ~/.config/opencode/skills/exec/scripts/move-plan.sh <plan-file-path>`. The script is a no-op when the plan is already under `completed/` or missing, derives the target as a `completed/` sibling of the plan's directory (so it respects worktrees), and commits the move with git. Do NOT push. If the script exits non-zero, report the failure but do not block completion.
- Report the final line "All N tasks completed, reviews passed, branch finalized". Append ", plan moved to completed/" ONLY when move-plan.sh actually moved the file (it printed `moved plan to ...`); omit the suffix when the move was a no-op (already under `completed/` or missing) or exited non-zero

## Key rules

- Each subagent gets a fresh context — no accumulated state from previous tasks
- Parent session only tracks: task number, success/failure, retry count
- Plan file is the single source of truth for progress — always re-read it
- No signals — just checkboxes in the plan for task progress
- Maintain the progress file (`/tmp/progress-<plan-name>.txt`): task and fixer subagents append task/fix entries plus `[decision]`/`[deviation]` lines; you log review findings and completion. `stats.py` parses it at the end
- Do not modify the plan file yourself during the task, review, and finalize phases — only subagents modify it. The sole exception is the terminal move in step 12 (after all phases finish), which the orchestrator performs via `move-plan.sh`
- Do not implement or fix code yourself — only subagents implement and fix
- If a subagent fails or leaves broken code, re-run the loop — do NOT investigate or fix it yourself
- NEVER dismiss findings as "pre-existing", "not from changes", or "architectural" — ALL findings are actionable
- NEVER summarize or filter agent findings — pass the full output to the fixer agent verbatim
- All prompt and agent files MUST be resolved through the three-layer override chain before use
- Review phases use the `reviewer` subagent (read-only). Task work, fixes, and finalize use the `implementer` subagent
- After reading a prompt file, substitute all placeholders before passing to subagent (see Placeholder Substitution)
- Subagents run with NO human available — they must NEVER ask the user a question (no `question` tool, no pausing for input). They decide judgment calls the plan does not settle from the project's lint rules, AGENTS.md, and code conventions, and log each as a `[decision]`/`[deviation]` line for the completion report
- In worktree mode (`worktree_mode = true`) the main working directory is never touched — no branch is created or checked out there and no changes land there; all git operations run inside the worktree, and Step 4's create-branch.sh is skipped
