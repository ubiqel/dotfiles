return {
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    cmd = "Copilot",
    opts = {
      filetypes = {
        go = true,
        lua = true,
        python = true,
        ["*"] = false,
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = "<M-l>",
        },
      },
      panel = {
        enabled = true,
        auto_refresh = true,
        keymap = {
          jump_prev = "[[",
          jump_next = "]]",
          accept = "<CR>",
          refresh = "gr",
          open = "<M-CR>",
        },
      },
    },
    keys = {
      { "<leader>cp", ":Copilot! attach<CR>", desc = "Attach Copilot" },
    },
    init = function()
      local proxy = nil
      if os.getenv("COPILOT_PROXY_URL") then
        proxy = os.getenv("COPILOT_PROXY_URL")
      end

      vim.g.copilot_proxy = proxy
    end,
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken", -- Only on MacOS or Linux
    config = function()
      local chat = require("CopilotChat")
      local prompts = require("CopilotChat.config.prompts")
      local select = require("CopilotChat.select")
      local cutils = require("CopilotChat.utils")

      local COPILOT_PLAN = [[
You are a software architect and technical planner focused on clear, actionable development plans.
]] .. prompts.COPILOT_BASE.system_prompt .. [[

When creating development plans:
- Start with a high-level overview
- Break down into concrete implementation steps
- Identify potential challenges and their solutions
- Consider architectural impacts
- Note required dependencies or prerequisites
- Estimate complexity and effort levels
- Track confidence percentage (0-100%)
- Format in markdown with clear sections

Always end with:
"Current Confidence Level: X%"
"Would you like to proceed with implementation?" (only if confidence >= 90%)
]]

      local proxy = nil
      if os.getenv("COPILOT_PROXY_URL") then
        proxy = os.getenv("COPILOT_PROXY_URL")
      end

      chat.setup({
        model = "claude-3.7-sonnet",
        temperature = 0.3,
        -- question_header = " " .. icons.ui.User .. " ",
        -- answer_header = " " .. icons.ui.Bot .. " ",
        -- error_header = "> " .. icons.diagnostics.Warn .. " ",
        sticky = { "#buffers", "#filenames" },
        proxy = proxy,

        mappings = {
          reset = false,
          show_diff = {
            full_diff = false,
          },
          complete = {
            insert = "<M-l>",
          },
        },

        prompts = {
          Explain = {
            mapping = "<leader>ae",
            description = "AI Explain",
          },
          Review = {
            mapping = "<leader>ar",
            description = "AI Review",
          },
          Tests = {
            mapping = "<leader>at",
            description = "AI Tests",
          },
          Fix = {
            mapping = "<leader>af",
            description = "AI Fix",
          },
          Optimize = {
            mapping = "<leader>ao",
            description = "AI Optimize",
          },
          Docs = {
            mapping = "<leader>ad",
            description = "AI Documentation",
          },
          Commit = {
            mapping = "<leader>ac",
            description = "AI Generate Commit",
            -- selection = select.buffer,
          },
          Plan = {
            prompt = "Create or update the development plan for the selected code. Focus on architecture, implementation steps, and potential challenges.",
            system_prompt = COPILOT_PLAN,
            context = "file:.copilot/plan.md",
            progress = function() return false end,
            callback = function(response, source)
              chat.chat:append("Plan updated successfully!", source.winnr)
              local plan_file = source.cwd() .. "/.copilot/plan.md"
              local dir = vim.fn.fnamemodify(plan_file, ":h")
              vim.fn.mkdir(dir, "p")
              local file = io.open(plan_file, "w")
              if file then
                file:write(response)
                file:close()
              end
            end,
          },
        },

        contexts = {
          lsp_diagnostics = {
            resolve = function()
              local diagnostics = vim.diagnostic.get(nil, { severity = nil })
              if vim.tbl_isempty(diagnostics) then
                return { { content = "Without diagnostics.", filetype = "text" } }
              end

              local lines = {}
              for _, d in ipairs(diagnostics) do
                table.insert(
                  lines,
                  string.format(
                    "[%s] %s:%d:%d - %s",
                    vim.diagnostic.severity[d.severity],
                    vim.fn.bufname(d.bufnr),
                    d.lnum + 1,
                    d.col + 1,
                    d.message
                  )
                )
              end

              return {
                {
                  content = table.concat(lines, "\n"),
                  filename = "lsp_diagnostics.txt",
                  filetype = "text",
                },
              }
            end,
          },

          vectorspace = {
            description = "Semantic search through workspace using vector embeddings. Find relevant code with natural language queries.",

            schema = {
              type = "object",
              required = { "query" },
              properties = {
                query = {
                  type = "string",
                  description = "Natural language query to find relevant code.",
                },
                max = {
                  type = "integer",
                  description = "Maximum number of results to return.",
                  default = 10,
                },
              },
            },

            resolve = function(input, source, prompt)
              local inputstr = prompt
              local inputMax
              if input then
                inputstr = input.query
                inputMax = input.max
              end

              local embeddings = cutils.curl_post("http://localhost:8000/query", {
                json_request = true,
                json_response = true,
                body = {
                  dir = source.cwd(),
                  text = inputstr,
                  max = inputMax,
                },
              }).body

              cutils.schedule_main()
              return vim
                .iter(embeddings)
                :map(function(embedding)
                  embedding.filetype = cutils.filetype(embedding.filename)
                  return embedding
                end)
                :filter(function(embedding) return embedding.filetype end)
                :totable()
            end,
          },
        },
      })

      vim.keymap.set({ "n" }, "<leader>aa", chat.toggle, { desc = "AI Toggle" })
      vim.keymap.set({ "v" }, "<leader>aa", chat.open, { desc = "AI Open" })
      vim.keymap.set({ "n" }, "<leader>ax", chat.reset, { desc = "AI Reset" })
      vim.keymap.set({ "n" }, "<leader>as", chat.stop, { desc = "AI Stop" })
      vim.keymap.set({ "n" }, "<leader>am", chat.select_model, { desc = "AI Models" })
      vim.keymap.set({ "n", "v" }, "<leader>ap", chat.select_prompt, { desc = "AI Prompts" })
      vim.keymap.set({ "n", "v" }, "<leader>aq", function()
        vim.ui.input({
          prompt = "AI Question> ",
        }, function(input)
          if input ~= "" then
            chat.ask(input)
          end
        end)
      end, { desc = "AI Question" })
    end,
  },
}
