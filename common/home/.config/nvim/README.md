# Neovim config

Personal Neovim configuration built on [lazy.nvim](https://github.com/folke/lazy.nvim).
It is organized by feature rather than one file per plugin, with global settings
in `lua/keiqu/`, plugin specs in `lua/keiqu/plugins/`, and native LSP server
configuration in the root `lsp/` directory.

## Layout

```text
init.lua                    leader keys and module loading order
lua/keiqu/
  options.lua               vim options and netrw settings
  keymaps.lua               global keymaps only
  autocmds.lua              FileType/Treesitter and misc autocmds
  theme.lua                 dark/light colorscheme switching
  globals.lua               small global helpers
  lazy.lua                  lazy.nvim bootstrap
  plugins/                  feature-grouped plugin specs
  lsp/                      shared LSP setup, keymaps, and server list
  snippets/                 LuaSnip snippets
lsp/                        per-server LSP configuration
after/ftplugin/             filetype-specific options
```

## Where do I add...?

| I want to add... | Put it in... |
| --- | --- |
| A new plugin | `lua/keiqu/plugins/<feature>.lua` |
| A new LSP server | `lsp/<server>.lua`, then add it to `lua/keiqu/lsp/servers.lua` |
| A new formatter | `lua/keiqu/plugins/formatting.lua` |
| A new Treesitter parser | `lua/keiqu/plugins/treesitter.lua` |
| A new Mason tool | `lua/keiqu/plugins/mason.lua` |
| A global keymap | `lua/keiqu/keymaps.lua` |
| A plugin-specific keymap | the plugin spec that owns it |
| A filetype-specific option | `after/ftplugin/<filetype>.lua` |

Plugin specs are flat on purpose: lazy.nvim imports one level from
`lua/keiqu/plugins/`, so language-specific specs use names such as
`lang_go.lua` and `lang_lua.lua` instead of nested directories.

## LSP

- `lua/keiqu/lsp/servers.lua` is the single source of truth for enabled servers
  and for the servers Mason should install.
- `lsp/<server>.lua` files are loaded automatically by Neovim 0.11+ and can
  override or extend the defaults shipped by `nvim-lspconfig`.
- Add a Mason-installed server to `servers.lua` and Mason will install it on the
  next start. Servers that are not Mason packages (for example
  `plantuml_lsp`) are excluded from the Mason list and must be installed
  separately.

## Useful commands

| Command | Purpose |
| --- | --- |
| `:Lazy` | Manage plugins |
| `:Lazy update` | Update plugins (then commit `lazy-lock.json`) |
| `:Mason` | Install or inspect LSPs, formatters, and linters |
| `:checkhealth` | Check Neovim and plugin health |
| `:TSUpdate` | Update Treesitter parsers |

The active theme follows `background`: dark uses `catppuccin-mocha`, light uses
`gruvbox`.
