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
bash ~/.config/opencode/skills/exec/scripts/resolve-file.sh prompts/task.md ~/.config/opencode
bash ~/.config/opencode/skills/exec/scripts/resolve-file.sh agents/quality.txt ~/.config/opencode
```
The script checks project overrides, user overrides, and bundled defaults automatically.

### Placeholder Substitution

After reading a prompt file, replace ALL placeholders with actual values before passing to a subagent. Subagents run in fresh contexts without plugin env vars.

Always substitute: `PLAN_FILE_PATH`, `PROGRESS_FILE_PATH`, `DEFAULT_BRANCH`, `SKILL_ROOT` (`~/.config/opencode/skills/exec`), `RESOLVE_SCRIPT` (absolute path to `~/.config/opencode/skills/exec/scripts/resolve-file.sh`), `PLUGIN_DATA_DIR` (`~/.config/opencode`, passed as the second argument to resolve-file.sh so it can find user overrides), `USER_RULES` (resolved custom rules content from the rules loading step, or an empty string if no rules found), and phase-specific values (`FINDINGS_LIST`, `REVIEW_PHASE`, `DIFF_COMMAND`).

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

Note: in `hg` repos, detect-branch.sh returns `remote/<name>` (checking `master`, `main`, `trunk` in that order) in modern-Mercurial repos that expose upstream default via `remote/<name>` refs, and falls back to `default` in repos that use the traditional named-branch convention instead. The external-review prompt (`prompts/codex-review.md`) and the finalize prompt (`prompts/finalizer.md`) use git-specific commands and are not VCS-translated upstream. Both phases will be skipped (see step 9 and step 11, which re-detect VCS locally). Users who want hg-native review/finalize can override via `.opencode/exec-plan/prompts/codex-review.md` and `.opencode/exec-plan/prompts/finalizer.md` — any `git rebase origin/DEFAULT_BRANCH` in the bundled template must be replaced with the hg equivalent in the override, e.g. `hg rebase -d remote/master` when the repo exposes remote-tracking refs, or `hg rebase -d default` when it uses the traditional named-branch convention.

### Step 2. Ask about worktree isolation

**hg skip**: Detect VCS with `vcs=$(bash ~/.config/opencode/skills/exec/scripts/detect-vcs.sh)`. If `vcs` is `hg`, skip the worktree question and proceed in the current directory. The native worktree tools are git-only; hg users can use `hg share` manually before invoking `/planning/exec`.

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
   - `agent: "general"`
   - The task prompt from `prompts/task.md`, with all placeholders substituted as described in the Placeholder Substitution section above (including `USER_RULES`)
6. **After subagent returns**, re-read the plan file and check if that task's checkboxes are now `[x]`
   - If yes — task succeeded, continue loop
   - If no — **retry** with a fresh subagent for the same task up to 1 time. If the retry fails, stop and report failure to user
7. **Report to user**: "Task N completed" (one line). The task subagent logs details to the progress file.

CRITICAL: Spawn exactly ONE task subagent per iteration and WAIT for it to return before starting the next. NEVER batch-spawn multiple task subagents in a single message. Plan tasks are ordered and interdependent — later tasks build on the files earlier tasks create, and every task subagent edits the same plan-file checkboxes and overlapping source files, so running them in parallel corrupts the plan and the working tree. The "launch in a single message for parallel execution" instruction applies ONLY to the review phases (steps 7 and 10), never to this task loop.

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

4. **Spawn a fixer agent** — resolve `prompts/fixer.md` through the override chain. Launch with `agent: "general"`. Pass the FULL unedited review output as FINDINGS_LIST — the fixer decides what's real, not you.

5. **After fixer returns** → show the "FIXES:" section to the user. Report "Review phase 1: iteration N fixes applied". Check for uncommitted changes: detect VCS with `vcs=$(bash ~/.config/opencode/skills/exec/scripts/detect-vcs.sh)`, then run `git status --porcelain` for `git` or `hg status` for `hg`. If output is non-empty, show every reported path and warn that these uncommitted changes are absent from the committed branch diff used by the next review. This is report-only: do not retry, abort, or commit leftovers because of this check. Loop back to step 1.

If 5 iterations are reached with issues still found, report "Review phase 1: max iterations reached, moving on" and continue.

### Step 8. Review phase 2 — code smells

Report to user: "--- Review phase 2: code smells analysis ---"

Run once (no loop):

1. **Spawn a smells agent** — resolve `agents/smells.txt` through the override chain. Launch one `subagent` call with `agent: "reviewer"` and the resolved agent prompt.

2. **Collect findings** — after the agent returns, report to user with a compact list of findings (one line per finding). Log findings to progress file:
   `bash ~/.config/opencode/skills/exec/scripts/append-progress.sh <progress-file> "review phase 2: findings"`
   Then pipe the findings: `echo "<findings>" | bash ~/.config/opencode/skills/exec/scripts/append-progress.sh <progress-file>`

3. **If no issues found** → report "Smells analysis: clean" and proceed to the next phase.

4. **Spawn a fixer agent** — resolve `prompts/fixer.md` through the override chain. Launch with `agent: "general"`. Pass the FULL smells output as FINDINGS_LIST.

5. **After fixer returns** → report fixes to user. Check for uncommitted changes: detect VCS with `vcs=$(bash ~/.config/opencode/skills/exec/scripts/detect-vcs.sh)`, then run `git status --porcelain` for `git` or `hg status` for `hg`. If output is non-empty, show every reported path and warn that these uncommitted changes are absent from the committed branch diff used by the next review. This is report-only: do not retry, abort, or commit leftovers because of this check. Proceed to the next phase.

### Step 9. Review phase 3 — external review

**hg skip**: Detect VCS with `vcs=$(bash ~/.config/opencode/skills/exec/scripts/detect-vcs.sh)`. If `vcs` is `hg`, skip this entire step. Report to user: "hg detected — skipping external review (git-only). Override `prompts/codex-review.md` via `.opencode/exec-plan/` to enable hg-native review." Proceed directly to step 10.

Report to user: "--- Review phase 3: external review ---"

Adversarial loop: the external reviewer reviews the code, fixer evaluates and fixes, the reviewer re-reviews. The loop exits early once an iteration produces no `CRITICAL` or `MAJOR` findings — minor-only iterations still get fixed by the fixer, but no further round-trip happens. Subsequent phases (smells, critical-only) act as the final safety net.

All invocations go through `run-external-review.sh`. This port passes an empty first argument, so the script falls back to codex. Codex is not installed here, so the phase will normally report a skip. If you install a reviewer later, set the first argument to its command. Do NOT call `run-codex.sh` directly — it cannot honor a configured command. Older `codex-review.md` overrides may carry launcher or availability instructions before `## Prompt`; ignore those operational lines. Step 9 alone controls reviewer invocation and skip/failure handling.

If the script exits 127 AND the `.err` file from item 2 carries the `run-external-review:` marker, no external tool is available: report `External review: skipped — <that marker line>`, quoting the reason verbatim (it distinguishes a configured command missing from `PATH` from codex missing with no command set), and proceed to step 10. A 127 without that marker came from the reviewer itself — typically a wrapper script whose own inner tool is missing — and is a reviewer failure, not a skip.

Any other non-zero exit is a reviewer failure too, not a clean review: report `External review: reviewer failed (exit <code>) — <last line of the .err file>` and proceed to step 10. So is an exit 0 with empty stdout: report `External review: reviewer failed (no output)`, adding the last line of the `.err` file when it has one. Never treat empty output as "no findings" — the severity scan in item 4 would find nothing and the phase would report success without a review having run. Findings and the clean marker are judged on stdout only: codex echoes the whole prompt on stderr, severity definitions included, so a scan over stderr would read every clean review as blocking findings. A reviewer whose only output is on stderr, with no findings and no `NO ISSUES FOUND` marker on stdout, is a reviewer failure as well.

Loop up to 10 times:

1. **Resolve the review prompt** — read `prompts/codex-review.md` through the override chain. Replace `DIFF_COMMAND` using `vcs=$(bash ~/.config/opencode/skills/exec/scripts/detect-vcs.sh)`: for `git`, every iteration uses `git diff DEFAULT_BRANCH...HEAD`; for `hg`, every iteration uses `hg diff -r 'ancestor(., DEFAULT_BRANCH)'`. Fixers commit their changes, so later reviews must include the committed branch diff. Also replace `PLAN_FILE_PATH` (so the reviewer can read the plan for intent) and `PROGRESS_FILE_PATH` (so the reviewer can read prior review iterations and fixer responses and avoid re-reporting fixed issues).

2. **Run the external reviewer** — first write the resolved prompt to `/tmp/external-review-<plan-name>.txt` with the Write tool (same `<plan-name>` as the progress file, overwrite it each iteration), then run `bash ~/.config/opencode/skills/exec/scripts/run-external-review.sh '' "$(cat /tmp/external-review-<plan-name>.txt)" 2>/tmp/external-review-<plan-name>.err` with the shell tool's `background: true`, so the task output holds the reviewer's stdout alone. Do NOT paste the prompt text inline: it contains backticks and may contain `$` (the bundled prompt asks for findings formatted as `` `SEVERITY: file:line - description` ``), and the shell would run those as command substitutions before the reviewer saw the prompt. Write the file with the Write tool for that same reason — `echo "…" >` or a heredoc with an unquoted delimiter expands the backticks and `$` at write time, so the file the reviewer reads already has the format instruction blanked out. You will be notified when done — do NOT poll or sleep.

3. **Check the output** — the `NO ISSUES FOUND` marker counts as clean only when item 4's severity scan also comes back empty, so run that scan first. Marker present and no `CRITICAL` or `MAJOR` found → phase is done, proceed to step 10. That marker is the only clean result — the contract makes it mandatory — so never infer "clean" from output that lacks it. But the marker alone does not make a review clean either: a reviewer that echoes the phrase while still reporting a blocking finding is treated like any other finding output, and the findings win. Non-empty output without the marker must carry at least one `CRITICAL`, `MAJOR` or `MINOR` tag somewhere in stdout — a tag is what makes the output a review rather than a message. Output with neither the marker nor any tag is a reviewer failure: report `External review: reviewer failed (no findings and no clean marker)`, quoting the reviewer's first output line, and proceed to step 10. This is a whole-output check, not a per-line one — do not require every line to be tagged, or wrapped descriptions and blank separators would fail a real review. Output that clears this gate falls through to item 4 for severity classification.

4. **Classify severity** — scan the reviewer's stdout for `CRITICAL` or `MAJOR` markers (case-insensitive whole-word match). Set `has_blocking = true` if either is present, otherwise `has_blocking = false`. Findings without an explicit severity tag are treated as MINOR — `has_blocking` stays false in that case. That default applies to untagged lines sitting alongside at least one tagged line; item 3 has already rejected output carrying no tag at all, so it can never make an untagged non-review read as minor findings.

5. **Report findings to user** — show a compact list (one line per finding).

6. **Spawn a fixer agent** — same as other review phases, with the resolved `prompts/fixer.md` and the reviewer's stdout as FINDINGS_LIST. Fixer verifies, fixes, commits, reports FIXES.

7. **Report fixer results to user** - show FIXES section. Log to progress file. Check for uncommitted changes: detect VCS with `vcs=$(bash ~/.config/opencode/skills/exec/scripts/detect-vcs.sh)`, then run `git status --porcelain` for `git` or `hg status` for `hg`. If output is non-empty, show every reported path and warn that these uncommitted changes are absent from the committed branch diff used by the next review. This is report-only: do not retry, abort, or commit leftovers because of this check.

8. **Decide whether to loop**:
   - If `has_blocking` is false → report "External review: only minor findings — fixes applied, stopping loop" and proceed to step 10.
   - Otherwise → loop back to step 1.

If 10 iterations are reached with critical/major issues still found, report "External review: max iterations reached, moving on" and continue.

### Step 10. Review phase 4 — critical only

Report to user: "--- Review phase 4: critical/major only (single pass) ---"

Same structure as step 7 but with `REVIEW_PHASE` set to `critical`. Resolve `prompts/review.md` and follow its playbook FROM THIS MAIN SESSION — launch 2 parallel `reviewer` subagents (quality, implementation) focusing on critical/major issues only. Subagents cannot launch more subagents, so the fanout MUST be initiated from the main orchestrator. Same fixer flow — pass findings to fixer, show FIXES to user.

### Step 11. Finalize

**hg skip**: Detect VCS with `vcs=$(bash ~/.config/opencode/skills/exec/scripts/detect-vcs.sh)`. If `vcs` is `hg`, skip this entire step. Report to user: "hg detected — skipping finalize (git-only). Override `prompts/finalizer.md` via `.opencode/exec-plan/` to enable hg-native finalize." Note that `DEFAULT_BRANCH` substitutes as whatever detect-branch.sh returned — `remote/master` (or `remote/main`/`remote/trunk`) in modern-Mercurial repos that expose remote-tracking refs, `default` in repos that use the traditional named-branch convention — so any `git rebase origin/DEFAULT_BRANCH` in the bundled template must be replaced with the hg equivalent (e.g. `hg rebase -d remote/master`, or `hg rebase -d default` in the named-branch case) in the override. Proceed directly to step 12.

Check whether to run finalize. Ask the user with the `question` tool: "Run finalize (rebase + squash)?" Default **No**. If No, skip to step 12.

After all reviews pass, rebase and clean up commits.

Report to user: "--- Finalize: rebase and clean up commits ---"

Spawn one `subagent` with `agent: "general"` and the prompt from `prompts/finalizer.md`. Replace `DEFAULT_BRANCH`, `PLAN_FILE_PATH`, and `PROGRESS_FILE_PATH`.

This is best-effort — if rebase fails, report the issue but don't block completion.

### Step 12. Completion

- **Report autonomous decisions and deviations to the user.** The run had no human to answer questions, so subagents decided judgment calls themselves and logged them. Collect every such entry from the progress file — `grep -E '^(\[[^]]*\] )?\[(decision|deviation)\]' <progress-file>` — and present them in a dedicated section titled **"Decisions made autonomously / Deviations from the plan"**, one bullet per entry with its stated reason, so the user learns every question the run answered on its own and why. If there are none, state "no autonomous decisions or deviations were logged." Do this regardless of whether finalize ran — finalize is skipped on hg or when the user declines, so this is the guaranteed place the user always gets the report.
- Log completion to progress file: `bash ~/.config/opencode/skills/exec/scripts/append-progress.sh <progress-file> "completed"`
- Move the finished plan into its `completed/` subdirectory and commit it (best-effort): `bash ~/.config/opencode/skills/exec/scripts/move-plan.sh <plan-file-path>`. The script is a no-op when the plan is already under `completed/` or missing, derives the target as a `completed/` sibling of the plan's directory (so it respects worktrees), and commits the move VCS-aware (git/hg). Do NOT push. If the script exits non-zero, report the failure but do not block completion.
- Report the final line "All N tasks completed, reviews passed, branch finalized". Append ", plan moved to completed/" ONLY when move-plan.sh actually moved the file (it printed `moved plan to ...`); omit the suffix when the move was a no-op (already under `completed/` or missing) or exited non-zero

## Key rules

- Each subagent gets a fresh context — no accumulated state from previous tasks
- Parent session only tracks: task number, success/failure, retry count
- Plan file is the single source of truth for progress — always re-read it
- No signals — just checkboxes in the plan for task progress
- Maintain progress file (`/tmp/progress-<plan-name>.txt`) — see `prompts/progress-file.md` for format and when to write
- Do not modify the plan file yourself during the task, review, and finalize phases — only subagents modify it. The sole exception is the terminal move in step 12 (after all phases finish), which the orchestrator performs via `move-plan.sh`
- Do not implement or fix code yourself — only subagents implement and fix
- If a subagent fails or leaves broken code, re-run the loop — do NOT investigate or fix it yourself
- NEVER dismiss findings as "pre-existing", "not from changes", or "architectural" — ALL findings are actionable
- NEVER summarize or filter agent findings — pass the full output to the fixer agent verbatim
- All prompt and agent files MUST be resolved through the three-layer override chain before use
- Review phases use the `reviewer` subagent (read-only). Task work and fixes use the `general` subagent
- After reading a prompt file, substitute all placeholders before passing to subagent (see Placeholder Substitution)
- Subagents run with NO human available — they must NEVER ask the user a question (no `question` tool, no pausing for input). They decide judgment calls the plan does not settle from the project's lint rules, AGENTS.md, and code conventions, and log each as a `[decision]`/`[deviation]` line for the completion report
- In worktree mode (`worktree_mode = true`) the main working directory is never touched — no branch is created or checked out there and no changes land there; all git operations run inside the worktree, and Step 4's create-branch.sh is skipped
