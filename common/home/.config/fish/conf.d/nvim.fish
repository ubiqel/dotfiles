# Mason installs the formatters/linters (stylua, tree-sitter, goimports, ...)
# that nvim's conform and nvim-treesitter call, so this must precede /usr/bin:
# the distro ships older copies of some of them.
set -x PATH $HOME/.local/share/nvim/mason/bin $PATH
