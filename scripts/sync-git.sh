#!/bin/bash

set -e

echo "CRON RUN >>> $(date)" >> /tmp/git_sync_cron_debug.log
echo "Remote URL: $(git -C $1 remote get-url origin)" >> /tmp/git_sync_cron_debug.log
env >> /tmp/git_sync_cron_debug.log
cat /tmp/git_sync_cron_debug.log

cd $1

# Check for local changes (unstaged, staged, untracked)
HAS_CHANGES=false
if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    HAS_CHANGES=true
fi

# Check for unpushed commits
UPSTREAM_STATUS=$(git rev-list --left-right --count HEAD...@{u} || echo "0	0")
AHEAD_COUNT=$(echo "$UPSTREAM_STATUS" | awk '{print $1}')
BEHIND_COUNT=$(echo "$UPSTREAM_STATUS" | awk '{print $2}')

if [ "$HAS_CHANGES" = true ]; then
    git add -A
    NOW=$(date '+%Y-%m-%d %H:%M')
    git commit -m "Sync $NOW"
fi

# Always pull (rebasing)
echo "Pulling latest from origin..."
git pull origin master --rebase -vvv

# Push only if there are committed local changes (either just now or earlier)
if [ "$HAS_CHANGES" = true ] || [ "$AHEAD_COUNT" -gt 0 ]; then
    echo "Pushing local commits to origin..."
    git push origin master -vvv
else
    echo "No changes to push."
fi
