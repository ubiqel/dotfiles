local function map(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("force", { silent = true }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- save
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save buffer" })

-- yanking and pasting to/from the system clipboard
map({ "n", "x" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map({ "n", "x" }, "<leader>p", '"+gp', { desc = "Paste from system clipboard" })
map({ "n", "x" }, "<leader>P", '"+gP', { desc = "Paste from system clipboard before cursor" })

-- tab navigation
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Tab: keep only current" })
map("n", "<leader><tab>c", "<cmd>tabclose<cr>", { desc = "Tab: close" })
map("n", "<leader><tab>r", "<cmd>tabprevious | tabclose#<cr>", { desc = "Tab: close current, return" })

-- remove search highlight
map("n", "<leader>/", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- resize windows
map("n", "<A-k>", "<cmd>resize -2<cr>", { desc = "Resize window up" })
map("n", "<A-j>", "<cmd>resize +2<cr>", { desc = "Resize window down" })
map("n", "<A-h>", "<cmd>vertical resize -2<cr>", { desc = "Resize window left" })
map("n", "<A-l>", "<cmd>vertical resize +2<cr>", { desc = "Resize window right" })

-- move lines up/down
map("n", "<C-A-k>", "<cmd>move .-2<cr>==", { desc = "Move line up" })
map("n", "<C-A-j>", "<cmd>move .+1<cr>==", { desc = "Move line down" })
map("x", "<C-A-k>", "<cmd>move '<-2<cr>gv=gv", { desc = "Move selection up" })
map("x", "<C-A-j>", "<cmd>move '>+1<cr>gv=gv", { desc = "Move selection down" })

-- don't lose the register after pasting in visual mode
map({ "x", "s" }, "p", '"_dP', { desc = "Paste without yanking" })
