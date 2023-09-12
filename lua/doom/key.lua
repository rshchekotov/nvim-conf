vim.g.mapleader = ' '
local keyset = vim.keymap.set

local sn = {
  silent = true,
  noremap = true
}

keyset('n', '<leader>.', '<cmd>NvimTreeToggle<cr>', sn)

keyset('n', '<leader>f', '<cmd>Telescope fd<cr>', sn)
keyset('n', '<leader>g', '<cmd>Telescope live_grep<cr>', sn)
keyset('n', '<leader>s', '<cmd>Telescope symbols<cr>', sn)

keyset('n', '<leader>h', '<c-w><c-h>', sn)
keyset('n', '<leader>j', '<c-w><c-j>', sn)
keyset('n', '<leader>k', '<c-w><c-k>', sn)
keyset('n', '<leader>l', '<c-w><c-l>', sn)
keyset('n', '<tab>', '<cmd>bnext<cr>')
keyset('n', '<s-tab>', '<cmd>bprev<cr>')
keyset('n', '<leader>w', '<cmd>Bdelete<cr>')
keyset('n', '<esc>>', '<cmd>resize +5<cr>', sn)
keyset('n', '<esc><', '<cmd>resize -5<cr>', sn)

local dap = require('dap')
keyset('n', '<C-F8>', dap.toggle_breakpoint)
keyset('n', '<F7>', dap.step_into)
keyset('n', '<F8>', dap.step_over)
keyset('n', '<F4>', dap.repl.open)

local Terminal = require('toggleterm.terminal').Terminal
local lazygit = Terminal:new({
  cmd = 'lazygit',
  hidden = true,
  direction = 'float',
  float_opts = {
    border = 'double'
  }
})
local function _lazygit_toggle()
  lazygit:toggle()
end
keyset('n', '<leader>gg', _lazygit_toggle, sn)
