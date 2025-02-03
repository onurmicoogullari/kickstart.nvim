return {
  'akinsho/toggleterm.nvim',
  config = function()
    require('toggleterm').setup {
      -- Add any specific configuration options you need here
      size = 20, -- Default terminal size
      open_mapping = [[<c-\>]], -- Set keybinding to toggle terminal
      direction = 'horizontal', -- Open terminal horizontally
    }
  end,
}
