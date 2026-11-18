# Polish opencode agent workflow (cc-thingz port)

## Overview

- Ported cc-thingz planning/brainstorm/exec workflow needs polish after real usage: models must be pinned per agent (subagents currently inherit the session model), finalize asks an unnecessary question, the external review phase is dead weight (codex unavailable, port passes empty command), brainstorm should be its own agent, and the stats summary phase (dropped in the port) is worth adding — OpenCode's API makes it a single script, not a model job.
- Worktree question behavior stays as-is (deliberate decision after discussion).
- All Mercurial support is removed: user never uses hg, git-only everywhere. This kills `detect-vcs.sh` (its only purpose was git/hg dispatch) and the hg branches of detect-branch/create-branch/stage-and-commit/move-plan scripts.

## Context (from discovery)

- Files live in `common/home/.config/opencode/` (dotfiles repo, symlinked from `~/.config/opencode/`). All edits go to the dotfiles repo paths.
- Model IDs verified on the `opencode-go` gateway: `opencode-go/deepseek-v4.1-flash` (effort variants low/high/max), `opencode-go/glm-5.3` (low/high/max). Frontmatter syntax `model: provider/model#variant` is documented V2 agent config.
- Key mechanics: agent frontmatter `model:` pins only that agent. Subagents spawned as `general` inherit the *session's* model, not the parent agent's — so `general` needs a config-level pin and the exec workflow gets a dedicated `implementer` agent.
- Stats data source verified live: `GET /api/session?parentID=<id>&limit=100` returns per-subagent agent/title/model/tokens/duration; cursor-paginated. `opencode api get` handles auth. Orchestrator session id available via `OPENCODE_SESSION_ID` env in the shell tool. Working prototype at `/tmp/opencode/stats-proto.py` (validated against a real 38-subagent executor run).
- Upstream reference (cc-thingz 3.12.0) cloned at `/tmp/opencode/cc-thingz`.
- Progress file: keep as-is. It is the cross-iteration memory for fixer/reviewers and the only channel for the `[decision]`/`[deviation]` completion report (subagent contexts die on return; orchestrator is edit-denied outside `docs/plans/`).

## Development Approach

- Config/markdown edits + one new python script. No unit test framework in dotfiles — verification via `opencode` reload, agent/model listings, a live smoke run of the stats script, and a dangling-reference sweep.
- Complete each task fully before moving to the next.

## Implementation Steps

### Task 1: Pin models on all agents

**Files:**
- Modify: `common/home/.config/opencode/agents/planner.md`
- Modify: `common/home/.config/opencode/agents/executor.md`
- Modify: `common/home/.config/opencode/agents/reviewer.md`
- Modify: `common/home/.config/opencode/agents/plan-review.md`
- Modify: `common/home/.config/opencode/opencode.json`

- [x] planner.md frontmatter: `model: opencode-go/deepseek-v4.1-flash#max`
- [x] executor.md frontmatter: `model: opencode-go/deepseek-v4.1-flash#high`
- [x] reviewer.md frontmatter: `model: opencode-go/glm-5.3#high`
- [x] plan-review.md frontmatter: `model: opencode-go/glm-5.3#high`
- [x] opencode.json: add `agents.general.model` = `opencode-go/deepseek-v4.1-flash#high` (built-in override; general subagents in all sessions get flash-high)
- [x] verify config parses: `opencode api get /api/info` clean, no config errors in log

### Task 2: brainstorm agent split + implementer agent

**Files:**
- Create: `common/home/.config/opencode/agents/brainstorm.md`
- Create: `common/home/.config/opencode/agents/implementer.md`
- Modify: `common/home/.config/opencode/commands/brainstorm.md`
- Modify: `common/home/.config/opencode/agents/planner.md`

- [x] brainstorm.md: primary, `model: opencode-go/deepseek-v4.1-flash#max`, read-only perms (edit deny all, shell ask — mirror planner), body: run the brainstorm skill dialogue, never write code or plan files, on settled design tell user to run `/planning/make` (same session keeps context)
- [x] implementer.md: subagent, `model: opencode-go/deepseek-v4.1-flash#high`, permissions: edit allow, shell allow with `git push *` / `git reset --hard *` / `rm -rf *` ask (mirror executor guards)
- [x] commands/brainstorm.md: `agent: planner` → `agent: brainstorm`
- [x] planner.md workflow: replace "load the brainstorm skill" with "tell the user to switch to the brainstorm agent" (planner no longer loads the skill)
- [x] verify agents listed: `opencode api get /api/agent` shows brainstorm (primary) and implementer (subagent) with correct models

### Task 3: exec SKILL.md overhaul

**Files:**
- Modify: `common/home/.config/opencode/skills/exec/SKILL.md`

- [x] all `agent: "general"` spawns (task loop step 6, fixer in steps 7/8/9, finalizer) → `agent: "implementer"`
- [x] remove external review phase (current step 9) entirely: shell plumbing, `/tmp/external-review-*` write, run-external-review.sh invocation, exit-127/marker/stderr contract, hg-skip note
- [x] renumber: old 10 → 9 (critical-only), old 11 → 10 (finalize), new 11 = stats (task 5), old 12 → 12 (completion)
- [x] finalize step: delete the "Run finalize (rebase + squash)?" question — always run, no hg-skip
- [x] strip ALL hg/Mercurial text: step 1 hg note about detect-branch.sh `remote/<name>` fallback (delete), step 2 hg-skip paragraph (delete), uncommitted-changes checks in steps 7/8 drop "detect VCS with detect-vcs.sh, then git status or hg status" → plain `git status --porcelain`, finalize hg-skip paragraph (delete), completion text "finalize is skipped on hg or when the user declines" → finalize always runs, move-plan description "VCS-aware (git/hg)" → git
- [x] fix cross-references: step 6 "steps 7 and 10" → "steps 7 and 9", "proceed to step 12" in old step 11 → "step 11", move-plan exception "step 12" reference stays correct
- [x] step 2 (worktree question) unchanged
- [x] verify: grep SKILL.md for "codex", "external", "run-external-review", "hg", "mercurial", "detect-vcs" → zero hits; step numbers sequential with no gaps

### Task 4: executor.md finalize policy

**Files:**
- Modify: `common/home/.config/opencode/agents/executor.md`

- [x] boundaries: "Do not push, deploy, rebase, or squash without explicit confirmation" → push/deploy still require confirmation; rebase/squash are part of finalize and run without asking
- [x] stop conditions: drop "Finalize needs confirmation"
- [x] verify no other references to finalize confirmation remain

### Task 5: Stats summary phase (script, no subagent)

**Files:**
- Create: `common/home/.config/opencode/skills/exec/scripts/stats.py`
- Modify: `common/home/.config/opencode/skills/exec/SKILL.md`

- [x] stats.py (start from `/tmp/opencode/stats-proto.py`): args SESSION_ID, DEFAULT_BRANCH, PROGRESS_FILE_PATH
- [x] page `opencode api get /api/session?parentID=<id>&limit=100` via cursor until exhausted
- [x] classify by title keywords: `task` → task loop, `fix` → fixer, `smell` → smells, `critical` → critical re-check, `review` → review, `rebase|finalize|squash` → finalize; unknown → `other` bucket (never misfile)
- [x] emit markdown: per-phase table (count, summed wall, tok in/out/reasoning/cache-read), grand total row, wall-clock span of whole run (parallel phases overlap), per-model split
- [x] best-effort extras (skip section on failure, never exit non-zero): `/api/experimental/session/stats?project=<id>&tools=summary` aggregate + tool reliability; `git diff --shortstat DEFAULT_BRANCH...HEAD`; progress-file `[task]`/`[decision]`/`[deviation]` counts and the full decisions list
- [x] SKILL.md new step 11 (after finalize, before completion): orchestrator runs `python3 ~/.config/opencode/skills/exec/scripts/stats.py "$OPENCODE_SESSION_ID" <default-branch> <progress-file>` directly, shows output verbatim, best-effort/non-blocking
- [x] smoke test: run stats.py against a real past executor session id (e.g. `ses_e11e1b29effe5EVC6GR0v2gBYd`), confirm 38 subagents and sensible per-phase rows

### Task 6: Strip Mercurial from scripts + delete dead machinery

**Files:**
- Delete: `common/home/.config/opencode/skills/exec/scripts/detect-vcs.sh`
- Delete: `common/home/.config/opencode/skills/exec/scripts/run-external-review.sh`
- Delete: `common/home/.config/opencode/skills/exec/scripts/run-codex.sh`
- Delete: `common/home/.config/opencode/skills/exec/references/prompts/codex-review.md`
- Modify: `common/home/.config/opencode/skills/exec/scripts/detect-branch.sh`
- Modify: `common/home/.config/opencode/skills/exec/scripts/create-branch.sh`
- Modify: `common/home/.config/opencode/skills/exec/scripts/stage-and-commit.sh`
- Modify: `common/home/.config/opencode/skills/exec/scripts/move-plan.sh`

- [x] git rm the four files: detect-vcs.sh existed only for git/hg dispatch; run-external-review.sh, run-codex.sh, codex-review.md are dead after task 3
- [x] detect-branch.sh: remove do_hg branch and VCS dispatch; git-only, keep default-branch detection (master/main/trunk via origin refs)
- [x] create-branch.sh: remove do_hg and hg bookmark logic; git-only; replace its inline duplicated default-branch detection (the symbolic-ref/candidates/remote chain) with a call to detect-branch.sh — one implementation, not two
- [x] stage-and-commit.sh: remove do_hg and the VCS dispatch call; git-only, keep empty-pathspec rejection, `:(literal)` pathspec magic, and post-commit index reconciliation
- [x] move-plan.sh: drop the "git and hg each record this" comment; logic itself already goes through stage-and-commit.sh, no functional hg path
- [x] sweep whole `common/home/.config/opencode/` for dangling references: grep for `codex`, `run-external-review`, `run-codex`, `detect-vcs`, `\bhg\b`, `mercurial` — fix any remaining hits (expected: none after tasks 3 and 6)
- [x] smoke test surviving scripts: detect-branch.sh, create-branch.sh --print-name, stage-and-commit.sh in the dotfiles repo itself

### Task 7: End-to-end validation

- [x] `opencode service restart` then `opencode models` — config loads clean
- [x] agent listing shows planner/executor/brainstorm/learning (primary), reviewer/plan-review/implementer (subagent) with pinned models
- [x] dry-read `/planning/make` + `/planning/exec` flows against the edited files — no step-number gaps, no unresolved placeholders mentioned
- [x] confirm `~/.config/opencode/` symlinks still resolve (edits went through dotfiles repo)
- [x] commit (Conventional Commits), body explains: session-model inheritance gap, codex dead, hg support dropped as unused, fewer interruptions during exec runs

## Post-Completion

- Progress file machinery deliberately untouched (cross-iteration memory + decision log are load-bearing).
- Worktree question deliberately kept (user decision).
- Mercurial support deliberately removed (user never uses hg; git-only everywhere).
- Upstream drift note: cc-thingz 3.12.0 added `subagent_model` userConfig + per-spawn model passing; our frontmatter pins replace that mechanism — re-diff upstream when touching this next. Upstream also carries hg support we intentionally do not.
- Optional future: bash test suite for scripts (upstream has one), port of upstream interactive plan annotation (revdiff) — not in scope.


## Completion notes

- Worktree: `/home/salkirr/dotfiles/.lane/trees/opencode-agents-polish`, branch `opencode-agents-polish`, commit `6b43df5`.
- Task 1/7 validation: `opencode service restart` was skipped. V2 reloads configuration automatically, and a restart would kill the orchestrator session driving this run. Verified instead with `opencode debug agents`/`debug config` against a copy of the edited config dir via `XDG_CONFIG_HOME`: brainstorm/planner/executor/learning primary, reviewer/plan-review/implementer subagent, `general` pinned in config, all models resolved. `deepseek-v4.1-flash` and `glm-5.3` expose low/high/max variants (`/api/model`).
- Task 5 smoke: the reference session has 40 subagents, not 38 (it grew since the prototype). Phase rows, wall span, per-model split, project tool reliability, diffstat, and the decisions log all render; the script exits 0 with bad optional inputs.
- Task 3/4 extras: dropped the now-unused `DIFF_COMMAND` placeholder from SKILL.md and switched executor.md's workflow line from `general` to `implementer`.
- Deviation: the brainstorm agent denies all subagents rather than mirroring planner's `plan-review` allow — brainstorm never writes plans, so it has no use for plan review.
- The new global files (`agents/brainstorm.md`, `agents/implementer.md`, `skills/exec/scripts/stats.py`) need a stow run in the main tree after merge to create their `~/.config/opencode` symlinks.
- Follow-up after review: folded `skills/brainstorm/` into `agents/brainstorm.md` (commit `e957487`) because the skill had one consumer and its auto-activation description let other agents bypass the pinned read-only brainstorm agent. Tests for `stats.py` were discussed and deliberately skipped.

## Follow-up: simplification audit (2026-11-18)

Compared the port against cc-thingz 3.12.0 (`/tmp/opencode/cc-thingz`, `68d29a4`).

**What the audit found**

- Override chain, custom rules, `customize-file.sh`, `progress-file.md`, plan-review's long description and duplicated template bullets, SKILL fixer/status-check repetition, and make.md test-rule repetition all exist upstream in the same shape. They are upstream design or upstream drift, not port errors.
- `progress-file.md` is stale upstream too: it documents `[task] Task N:` while `task.md` logs `task N: <title>`, and says review agents do not need the progress file while `review.md` tells them to read it. No prompt or script loads it; the only pointer is one SKILL key-rule line (`see prompts/progress-file.md`), and it is a relative path the agent would have to hunt for. So it is not executable, but it can be read and it then misleads.
- `customize-file.sh` is documented and tested upstream (README, `planning/references/usage.md`, `tests/test-planning-external-review.sh`). Our port dropped those docs, which orphaned the script.
- Deliberately not ported, still upstream: external review + `external-plan-review` agent, hg, `hooks/plan-review-hook.py`, `plan-annotate.py` (revdiff), `userConfig` knobs (`task_retries`, `review_iterations`, `finalize_enabled`, `subagent_model`, `plans_dir`), README/usage docs, bash test suite.
- Our own port artifacts (no upstream counterpart): `executor.md` isolation section duplicating the skill, `opencode.json` `"commands": {}`, unused `SKILL_ROOT` placeholder.
- Wart in our port: `resolve-file.sh` is invoked with data-dir `~/.config/opencode`, so user-level `agents/quality.txt` overrides would land inside the real OpenCode `agents/` directory. Project-level overrides are unaffected.

**Decisions**

- Keep the override chain and the custom-rules machinery: per-project prompt overrides are a feature we may use. Fix discoverability instead of deleting: document the three layers and the `customize-file.sh` helper in SKILL's File Resolution section.
- Move the user-level override root to `~/.config/opencode/exec-plan/` (pass that as the data-dir) so overrides stop mixing with real agent files. No existing overrides, so no migration.
- Delete `references/prompts/progress-file.md`: referenced only from that one SKILL line, never injected into a prompt; the real format lives in `task.md`/`fixer.md` (what gets appended) and `stats.py` (what gets parsed). Replace the SKILL pointer with inline text instead of a second spec.
- Remove `opencode.json` `"commands": {}` and the unused `SKILL_ROOT` placeholder.
- Adapt plan-review to OpenCode: one-sentence description, drop the duplicated template bullets, keep the pointer to `make.md`.
- Trim `executor.md` isolation to a pointer at the exec skill.
- Keep SKILL.md and make.md repetition as-is (deliberate upstream enforcement; dedupe only if we fork further).
- No tests for `stats.py` (decided: skip).
- Brainstorm skill folded into its agent earlier (commit `e957487`).

**Follow-up executed (commit `622b2c2`)**

1. plan-review description reduced to one sentence; duplicated plan-template bullets replaced by a pointer to `make.md`.
2. Deleted `progress-file.md`; removed `"commands": {}` and the unused `SKILL_ROOT` placeholder; replaced the SKILL pointer with the actual writer/parser split.
3. Documented the three override layers and `customize-file.sh` in SKILL; moved the user-level override root to `~/.config/opencode/exec-plan/` (resolve-file default follows); no existing overrides.
4. Executor isolation list replaced by a pointer to exec Step 2.

Verified: `opencode debug agents --standalone` on a copied config loads all 14 agents with pinned models; project/user/bundled resolution and `customize-file.sh` tested; `bash -n` clean; no stale references.
