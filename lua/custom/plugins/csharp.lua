-- lazy.nvim
return {
  {
    'seblj/roslyn.nvim',
    ft = 'cs',
    opts = {
      -- your configuration comes here; leave empty for default settings
    },
  },
  {
    'GustavEikaas/easy-dotnet.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim', 'stevearc/overseer.nvim', 'akinsho/toggleterm.nvim' },
    config = function()
      require('overseer').setup()
      local logPath = vim.fn.stdpath 'data' .. '/easy-dotnet/build.log'
      local dotnet = require 'easy-dotnet'

      dotnet.setup {
        terminal = function(path, action)
          local commands = {
            run = function()
              return 'dotnet run --project ' .. path
            end,
            test = function()
              return 'dotnet test ' .. path
            end,
            restore = function()
              return 'dotnet restore ' .. path
            end,
            build = function()
              return 'dotnet build  ' .. path .. ' /flp:v=q /flp:logfile=' .. logPath
            end,
          }

          local function filter_warnings(line)
            if not line:find 'warning' then
              return line:match '^(.+)%((%d+),(%d+)%)%: (.+)$'
            end
          end

          local overseer_components = {
            { 'on_complete_dispose', timeout = 30 },
            'default',
            { 'unique', replace = true },
            {
              'on_output_parse',
              parser = {
                diagnostics = {
                  { 'extract', filter_warnings, 'filename', 'lnum', 'col', 'text' },
                },
              },
            },
            {
              'on_result_diagnostics_quickfix',
              open = true,
              close = true,
            },
          }

          local function get_git_root()
            local git_root = vim.fn.systemlist('git rev-parse --show-toplevel')[1]
            if vim.v.shell_error ~= 0 then
              return nil -- Not in a Git repo
            end
            return git_root
          end

          if action == 'run' or action == 'test' then
            table.insert(overseer_components, { 'restart_on_save', paths = { get_git_root() } })
          end

          local command = commands[action]()
          local task = require('overseer').new_task {
            strategy = {
              'toggleterm',
              use_shell = false,
              direction = 'float',
              open_on_start = true,
            },
            name = action,
            cmd = command,
            cwd = get_git_root(),
            components = overseer_components,
          }
          task:start()
        end,

        testrunner = {
          viewmode = 'float',
        },
      }

      vim.keymap.set('n', '<leader>ct', dotnet.testrunner, { desc = 'Testrunner' })
      vim.keymap.set('n', '<leader>cr', dotnet.testrunner, { desc = 'Testrunner refresh' })
    end,
  },
}
