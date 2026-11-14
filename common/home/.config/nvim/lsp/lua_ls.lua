return {
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
      },
      diagnostics = {
        globals = { "vim" },
      },
      hint = {
        enable = true,
        arrayIndex = "Disable",
      },
      workspace = {
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
}
