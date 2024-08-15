vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("pythonformat", { clear = true }),
  pattern = "*.py",
  callback = function()
    if vim.fn.executable("isort") ~= 1 then
      vim.notify("isort binary not found", vim.log.levels.WARN)
      return
    end

    local filepath = vim.fn.expand("%:p")

    -- check if sort is needed before sorting (to avoid unnecessary writes: it blinks the screen)
    vim.api.nvim_command(string.format("silent! !isort --check-only %s", filepath))
    if vim.v.shell_error == 0 then
      return
    end

    local res = vim.fn.system(string.format("isort -dd %s", filepath))
    if vim.v.shell_error ~= 0 then
      vim.notify("isort failed with message: " .. res, vim.log.levels.ERROR)
      return
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn.split(res, "\n"))
  end,
})
