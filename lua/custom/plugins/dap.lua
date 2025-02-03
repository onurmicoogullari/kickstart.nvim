return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_setup = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
      },
    }

    -- Basic debugging keymaps, feel free to change to your liking!
    vim.keymap.set('n', '<C-F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<C-F11>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<C-F10>', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<C-F12>', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    vim.cmd 'hi DapBreakpointColor guifg=#fa4848'
    vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'DapBreakpointColor', linehl = '', numhl = '' })

    -- Install golang specific config
    require('dap-go').setup()

    -- CSharp setup
    --
    if not dap.adapters['netcoredbg'] then
      require('dap').adapters['netcoredbg'] = {
        type = 'executable',
        command = vim.fn.exepath 'netcoredbg',
        args = { '--interpreter=vscode' },
        -- console = "internalConsole",
      }
    end

    if not dap.adapters['coreclr'] then
      require('dap').adapters['coreclr'] = {
        type = 'executable',
        command = vim.fn.exepath 'netcoredbg',
        args = { '--interpreter=vscode' },
        -- console = "internalConsole",
      }
    end

    local dotnet = require 'easy-dotnet'
    local debug_dll = nil
    local function ensure_dll()
      if debug_dll ~= nil then
        return debug_dll
      end
      local dll = dotnet.get_debug_dll()
      debug_dll = dll
      return dll
    end

    for _, lang in ipairs { 'cs', 'fsharp', 'vb' } do
      dap.configurations[lang] = {
        {
          log_level = 'DEBUG',
          type = 'netcoredbg',
          justMyCode = false,
          stopAtEntry = false,
          name = 'Default',
          request = 'launch',
          env = function()
            local dll = ensure_dll()
            local vars = dotnet.get_environment_variables(dll.project_name, dll.relative_project_path)
            return vars or nil
          end,
          program = function()
            require('overseer').enable_dap()
            local dll = ensure_dll()
            return dll.relative_dll_path
          end,
          cwd = function()
            local dll = ensure_dll()
            return dll.relative_project_path
          end,
          preLaunchTask = 'Build .NET App With Spinner',
        },
      }

      dap.listeners.before['event_terminated']['easy-dotnet'] = function()
        debug_dll = nil
      end
    end
  end,
  keys = {
    { '<leader>d', '', desc = '+debug', mode = { 'n', 'v' } },
    -- HYDRA MODE
    -- NOTE: the delay is set to prevent the which-key hints to appear
    {
      '<leader>d<space>',
      function()
        require('which-key').show { delay = 1000000000, keys = '<leader>d', loop = true }
      end,
      desc = 'DAP Hydra Mode (which-key)',
    },
    {
      '<leader>dR',
      function()
        local dap = require 'dap'
        local extension = vim.fn.expand '%:e'
        dap.run(dap.configurations[extension][1])
      end,
      desc = 'Run default configuration',
    },
    {
      '<leader>dB',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Breakpoint Condition',
    },
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Toggle Breakpoint',
    },
    {
      '<leader>dc',
      function()
        require('dap').continue()
      end,
      desc = 'Continue',
    },
    {
      '<leader>da',
      function()
        require('dap').continue { before = get_args }
      end,
      desc = 'Run with Args',
    },
    {
      '<leader>dC',
      function()
        require('dap').run_to_cursor()
      end,
      desc = 'Run to Cursor',
    },
    {
      '<leader>dg',
      function()
        require('dap').goto_()
      end,
      desc = 'Go to Line (No Execute)',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = 'Step Into',
    },
    {
      '<leader>dj',
      function()
        require('dap').down()
      end,
      desc = 'Down',
    },
    {
      '<leader>dk',
      function()
        require('dap').up()
      end,
      desc = 'Up',
    },
    {
      '<leader>dl',
      function()
        require('dap').run_last()
      end,
      desc = 'Run Last',
    },
    {
      '<leader>do',
      function()
        require('dap').step_out()
      end,
      desc = 'Step Out',
    },
    {
      '<leader>dO',
      function()
        require('dap').step_over()
      end,
      desc = 'Step Over',
    },
    {
      '<leader>dp',
      function()
        require('dap').pause()
      end,
      desc = 'Pause',
    },
    {
      '<leader>dr',
      function()
        require('dap').repl.toggle()
      end,
      desc = 'Toggle REPL',
    },
    {
      '<leader>ds',
      function()
        require('dap').session()
      end,
      desc = 'Session',
    },
    {
      '<leader>dt',
      function()
        require('dap').terminate()
      end,
      desc = 'Terminate',
    },
    {
      '<leader>dw',
      function()
        require('dap.ui.widgets').hover()
      end,
      desc = 'Widgets',
    },
  },
}
