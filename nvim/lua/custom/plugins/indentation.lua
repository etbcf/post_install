return {
  {
    -- Dummy plugin to anchor the config block
    'nvim-treesitter/nvim-treesitter',
    config = function()
      vim.opt.tabstop = 4 -- number of visual spaces per TAB
      vim.opt.shiftwidth = 4 -- number of spaces to use for autoindent
      vim.opt.expandtab = true -- expand TABs to spaces

      -- Optional: Python-specific settings
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'python' },
        callback = function()
          vim.bo.tabstop = 4
          vim.bo.shiftwidth = 4
        end,
      })
    end,
  },
}
