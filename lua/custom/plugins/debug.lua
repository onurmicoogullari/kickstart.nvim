-- extended-dap-config.lua
local dap_config = require 'kickstart.plugins.debug'

-- Extend the existing configuration function
local original_config = dap_config.config

dap_config.config = function()
  -- Call the original configuration function
  original_config()

  -- Add new adapter setup here

  local dap = require 'dap'

  -- CSharp setup
  vim.g.dotnet_build_project = function()
    local default_path = vim.fn.getcwd() .. '/'
    if vim.g['dotnet_last_proj_path'] ~= nil then
      default_path = vim.g['dotnet_last_proj_path']
    end
    local path = vim.fn.input('Path to your *proj file', default_path, 'file')
    vim.g['dotnet_last_proj_path'] = path
    local cmd = 'dotnet build -c Debug ' .. path .. ' > /dev/null'
    print ''
    print('Cmd to execute: ' .. cmd)
    local f = os.execute(cmd)
    if f == 0 then
      print '\nBuild: ✔️ '
    else
      print('\nBuild: ❌ (code: ' .. f .. ')')
    end
  end

  vim.g.dotnet_get_dll_path = function()
    local request = function()
      return vim.fn.input('Path to dll', vim.fn.getcwd() .. '/bin/Debug/', 'file')
    end

    if vim.g['dotnet_last_dll_path'] == nil then
      vim.g['dotnet_last_dll_path'] = request()
    else
      if vim.fn.confirm('Do you want to change the path to dll?\n' .. vim.g['dotnet_last_dll_path'], '&yes\n&no', 2) == 1 then
        vim.g['dotnet_last_dll_path'] = request()
      end
    end

    return vim.g['dotnet_last_dll_path']
  end

  dap.adapters.coreclr = {
    type = 'executable',
    command = '/usr/local/bin/netcoredbg/netcoredbg',
    args = { '--interpreter=vscode' },
  }

  local config = {
    {
      type = 'coreclr',
      name = 'launch - netcoredbg',
      request = 'launch',
      program = function()
        if vim.fn.confirm('Should I recompile first?', '&yes\n&no', 2) == 1 then
          vim.g.dotnet_build_project()
        end
        return vim.g.dotnet_get_dll_path()
      end,
    },
  }

  dap.configurations.cs = config
  dap.configurations.fsharp = config

  vim.api.nvim_set_keymap('n', '<C-b>', ':lua vim.g.dotnet_build_project()<CR>', { noremap = true, silent = true })
end

return dap_config
