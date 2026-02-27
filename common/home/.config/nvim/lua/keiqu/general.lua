local options = {
  termguicolors = true,
  undofile = true,
  undolevels = 10000,
  history = 1000,
  number = true,
  relativenumber = true,
  cursorline = true,
  list = true,
  listchars = { eol = "↵", tab = "▸·", space = "·", extends = "▶", precedes = "◀", nbsp = "␣" },
  tabstop = 4,
  shiftwidth = 4,
  expandtab = true,
  wrap = false,
  wildmode = { "longest", "full" },
  wildignore = {
    "*.docx",
    "*.jpg",
    "*.png",
    "*.gif",
    "*.pdf",
    "*.exe",
    "*.flv",
    "*.img",
    "*.xlsx",
    "*.o",
    "*.pyc",
    "**/.git/*",
  },
  scrolloff = 7,
  ignorecase = true,
  smartcase = true,
  smartindent = true,
  completeopt = { "menu", "menuone", "noselect" }, -- for nvim-cmp
  sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions",
  autowriteall = true,
  laststatus = 3,
  textwidth = 0,
  shell = "/usr/bin/fish",
}

for k, v in pairs(options) do
  vim.opt[k] = v
end

-- config netrw
vim.g.netrw_winsize = 20
vim.g.netrw_keepdir = 0
vim.g.netrw_banner = 0
vim.g.netrw_localcopydircmd = "cp -r"

----------------------------------------------------
--                    KEYMAPS
----------------------------------------------------
local nmap = require("keiqu.keymaps").nmap
local imap = require("keiqu.keymaps").imap
local vmap = require("keiqu.keymaps").vmap
local xmap = require("keiqu.keymaps").xmap
local nvmap = require("keiqu.keymaps").nvmap

-- our leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- save
nmap("<leader>w", ":w<cr>")

-- yanking and pasting to/from "system" register
nvmap("<leader>y", '"+y')
nvmap("<leader>p", '"+gp')
nmap("<leader>Y", "+Y") -- TODO: wtf does this do?
nmap("<leader>P", '"+gP')

-- window navigation
nmap("<C-h>", "<C-w>h")
nmap("<C-j>", "<C-w>j")
nmap("<C-k>", "<C-w>k")
nmap("<C-l>", "<C-w>l")

-- tab navigation
vim.keymap.set("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Tab: keep only current" })
vim.keymap.set("n", "<leader><tab>c", "<cmd>tabclose<cr>", { desc = "Tab: close" })
vim.keymap.set("n", "<leader><tab>r", "<cmd>tabprevious | tabclose#<cr>", { desc = "Tab: close current, return" })

-- remove search highlight
nmap("<leader>/", "<cmd>noh<cr><esc>")

-- resize windows
nmap("<A-k>", ":resize -2<cr>")
nmap("<A-j>", ":resize +2<cr>")
nmap("<A-h>", ":vertical resize -2<cr>")
nmap("<A-l>", ":vertical resize +2<cr>")

-- Telescope
nmap(
  "<leader>ff",
  ':Telescope find_files workspace=CWD theme=dropdown previewer=false path_display={"filename_first"}<cr>'
)
nmap("<leader>fg", ":Telescope live_grep<cr>")
nmap("<leader>fb", ":Telescope buffers<cr>")
nmap("<leader>fh", ":Telescope help_tags<cr>")
nmap("<leader>fs", ":lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<cr>")
nmap("<leader>gs", ":Telescope git_status<cr>")
nmap("<leader>gb", ":Telescope git_branches<cr>")

-- nvim tree
nmap("<leader>e", ":NvimTreeToggle<cr>")
nmap("<leader>E", ":NvimTreeFindFile<cr>")

-- don't loose contents of register after pasting in visual mode (substitution)
vmap("p", '"_dP')
