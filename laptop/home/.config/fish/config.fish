if status is-interactive
    set -x EDITOR nvim
    set -x VISUAL nvim

    set -x GOPATH $HOME/go

    set -x PATH $GOPATH/bin $PATH
    set -x PATH $HOME/.local/bin $PATH
    set -x PATH $HOME/.cargo/bin $PATH
    set -x PATH $HOME/.local/share/nvim/mason/bin $PATH

    set -x SSH_AUTH_SOCK $XDG_RUNTIME_DIR/ssh-agent.socket
end
