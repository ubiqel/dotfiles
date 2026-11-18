#!/bin/bash
# create a feature branch from plan file name if on the default branch
# usage: create-branch.sh <plan-file-path>
# exits 0 if branch created or already on feature branch
# outputs branch name to stdout
#
# strips leading YYYYMMDD- date prefix from branch name since plan files
# use date prefixes (e.g., 20260329-feature-name.md) but branch names should not

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# derive branch name from plan file path
# e.g., docs/plans/20260329-feature-name.md -> feature-name
derive_branch_name() {
    local name
    name=$(basename "$1" .md)
    # strip leading date prefix if present (YYYYMMDD- or YYYY-MM-DD-)
    # shellcheck disable=SC2001 # regex too complex for ${var//pattern}
    name=$(echo "$name" | sed 's/^[0-9]\{4\}-\{0,1\}[0-9]\{2\}-\{0,1\}[0-9]\{2\}-//')
    echo "$name"
}

# --print-name mode: derive and print the branch name only, with NO VCS side effects.
# the exec SKILL uses this in worktree mode to name the worktree/branch without ever
# running `git checkout -b` in the main working tree (which would break isolation).
if [ "${1:-}" = "--print-name" ]; then
    if [ -z "${2:-}" ]; then
        echo "error: plan file path required" >&2
        exit 1
    fi
    derive_branch_name "$2"
    exit 0
fi

if [ -z "${1:-}" ]; then
    echo "error: plan file path required" >&2
    exit 1
fi

plan_file="$1"
current_branch=$(git branch --show-current)

# single implementation of default-branch detection lives in detect-branch.sh
default_branch=$(bash "$SCRIPT_DIR/detect-branch.sh" 2>/dev/null || true)

# if already on a feature branch (not the default and not detached), just report it
if [ -n "$current_branch" ] && [ -n "$default_branch" ] && [ "$current_branch" != "$default_branch" ]; then
    echo "$current_branch"
    exit 0
elif [ -n "$current_branch" ] && [ -z "$default_branch" ] && [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
    # no default branch detected, fall back to main/master check
    echo "$current_branch"
    exit 0
fi

branch_name=$(derive_branch_name "$plan_file")

# check if branch already exists
if git show-ref --verify --quiet "refs/heads/$branch_name" 2>/dev/null; then
    git checkout "$branch_name"
else
    git checkout -b "$branch_name"
fi

echo "$branch_name"
