local options = {
  termguicolors = true,
  undofile = true,
  undolevels = 10000,
  history = 1000,
  confirm = true,
  mouse = "a",
  number = true,
  relativenumber = true,
  cursorline = true,
  signcolumn = "yes",
  breakindent = true,
  list = true,
  listchars = { eol = "↵", tab = "▸·", space = "·", extends = "▶", precedes = "◀", nbsp = "␣" },
  fillchars = { foldopen = "", foldclose = "", fold = " ", foldsep = " ", diff = "╱", eob = " " },
  foldlevel = 99,
  foldmethod = "indent",
  foldtext = "",
  tabstop = 4,
  shiftwidth = 4,
  shiftround = true,
  expandtab = true,
  wrap = false,
  virtualedit = "block",
  splitbelow = true,
  splitright = true,
  inccommand = "nosplit",
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
  sidescrolloff = 8,
  ignorecase = true,
  smartcase = true,
  smartindent = true,
  completeopt = { "menu", "menuone", "noinsert" }, -- for nvim-cmp
  sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions",
  autowriteall = true,
  laststatus = 3,
  textwidth = 0,
  shell = "fish",
  timeout = true,
  timeoutlen = 300,
  updatetime = 200,
}

for key, value in pairs(options) do
  vim.opt[key] = value
end

-- netrw
vim.g.netrw_winsize = 20
vim.g.netrw_keepdir = 0
vim.g.netrw_banner = 0
vim.g.netrw_localcopydircmd = "cp -r"
