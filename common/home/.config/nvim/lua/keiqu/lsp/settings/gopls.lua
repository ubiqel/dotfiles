return {
  settings = {
    gopls = {
      codelenses = {
        gc_details = false,
        generate = true,
        regenerate_cgo = true,
        vulncheck = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
        vendor = true,
      },
      hints = {
        assignVariableTypes = false,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = false,
        parameterNames = true,
        rangeVariableTypes = false,
      },
      analyses = {
        fieldalignment = false,
        nilness = true,
        unusedparams = true,
        unusedwrite = true,
        unusedvariable = true,
        useany = true,
        shadow = false,
        ST1000 = false,
        ST1001 = false, -- триггерится на dot imports
        ST1003 = false, -- тригерится на код go-jet
      },
      gofumpt = true,
      usePlaceholders = false,
      completeUnimported = true,
      staticcheck = true,
      directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules", "-.linter-cache" },
      semanticTokens = false, -- TODO: experiment with it (it seems to be broken; but lazyvim has solution in it's config)
    },
  },
}
