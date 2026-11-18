#!/bin/bash
# resolve a file through the three-layer override chain
# usage: resolve-file.sh <relative-path> [data-dir]
# e.g.: resolve-file.sh prompts/task.md "$HOME/.config/opencode/exec-plan"
# e.g.: resolve-file.sh agents/quality.txt "$HOME/.config/opencode/exec-plan"
#
# data-dir: user-level override directory (normally ~/.config/opencode/exec-plan).
# defaults to $HOME/.config/opencode/exec-plan when not provided as an argument.
#
# checks in order:
#   1. .opencode/exec-plan/<path> (project override)
#   2. <data-dir>/<path> (user override)
#   3. bundled default (derived from script location)
#
# outputs the file content to stdout

set -e

path="$1"
if [ -z "$path" ]; then
    echo "error: usage: resolve-file.sh <relative-path> [data-dir]" >&2
    exit 1
fi

# use argument if provided, fall back to env var
data_dir="${2:-$HOME/.config/opencode/exec-plan}"

# derive skill root from script location
# script is at <skill-root>/scripts/resolve-file.sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -f ".opencode/exec-plan/$path" ]; then
    cat ".opencode/exec-plan/$path"
elif [ -n "$data_dir" ] && [ -f "$data_dir/$path" ]; then
    cat "$data_dir/$path"
elif [ -f "$SKILL_ROOT/references/$path" ]; then
    cat "$SKILL_ROOT/references/$path"
else
    echo "error: file not found in override chain: $path" >&2
    exit 1
fi
