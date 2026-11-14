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
  shell = "fish",
  timeout = true,
  timeoutlen = 300,
}

for key, value in pairs(options) do
  vim.opt[key] = value
end

-- netrw
vim.g.netrw_winsize = 20
vim.g.netrw_keepdir = 0
vim.g.netrw_banner = 0
vim.g.netrw_localcopydircmd = "cp -r"
