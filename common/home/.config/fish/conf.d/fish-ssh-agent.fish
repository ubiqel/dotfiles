# TODO: for some reason doesn't work from conf.d
# but from config works...
if test -z "$SSH_ENV"
    set -xg SSH_ENV $HOME/.ssh/environment
end


if not __ssh_agent_is_started
    __ssh_agent_start
end

__ssh_agent_start
