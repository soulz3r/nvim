-- lua/soul/plugins/telescope-projects.lua
local M = {
  "nvim-telescope/telescope-project.nvim",

  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
}

function M.config()
  local telescope = require("telescope")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local builtin = require("telescope.builtin")
  local projects = require("soul.core.projects")

  telescope.setup({
    extensions = {
      project = {
        base_dirs = {
          require("soul.core.paths").projects,
        },
        ignore_missing_dirs = true,
        hidden_files = true,
        order_by = "recent",
        search_by = { "title", "path" },
        theme = "dropdown",
        on_project_selected = function(prompt_bufnr)
          require("telescope._extensions.project.actions")
            .change_working_directory(prompt_bufnr, false)
        end,
      },
    },
  })

  telescope.load_extension("project")

  local function project_picker()
    telescope.extensions.project.project({
      attach_mappings = function(prompt_bufnr, map)
        local function with_project(callback)
          local entry = action_state.get_selected_entry()

          if not entry then
            return
          end

          local path = entry.value
          if type(path) == "table" then
            path = path.path or path.cwd
          end

          if type(path) ~= "string" or path == "" then
            vim.notify("Could not determine the selected project path", vim.log.levels.WARN)
            return
          end

          actions.close(prompt_bufnr)

          vim.schedule(function()
            vim.cmd.cd(vim.fn.fnameescape(path))
            callback(path)
          end)
        end

        local mappings = {
          ["<C-r>"] = function()
            with_project(projects.run)
          end,
          ["<C-b>"] = function()
            with_project(projects.build)
          end,
          ["<C-f>"] = function()
            with_project(function(root)
              builtin.find_files({ cwd = root })
            end)
          end,
          ["<C-g>"] = function()
            with_project(function(root)
              builtin.live_grep({ cwd = root })
            end)
          end,
        }

        for key, callback in pairs(mappings) do
          map("i", key, callback)
          map("n", key, callback)
        end

        return true
      end,
    })
  end

  vim.keymap.set("n", "<leader>fp", project_picker, OPTS("Projects"))
  vim.keymap.set("n", "<leader>rr", projects.run, OPTS("Run Project"))
  vim.keymap.set("n", "<leader>rb", projects.build, OPTS("Build Project"))
  vim.keymap.set("n", "<leader>rf", projects.run_file, OPTS("Run Current File"))
end

return M
