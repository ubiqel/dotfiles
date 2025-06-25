if status is-interactive
    eval "$(/opt/homebrew/bin/brew shellenv)"
end

if test -z "$SSH_ENV"
    set -xg SSH_ENV $HOME/.ssh/environment
end


if not __ssh_agent_is_started
    __ssh_agent_start
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
