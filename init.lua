local set = vim.opt
local indent = 2

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

set.number = true
set.wrap = false
set.tabstop = indent
set.shiftwidth = indent
set.softtabstop = indent
set.expandtab = true

set.hlsearch = true
set.incsearch = true
set.ignorecase = true
set.smartcase = true

vim.cmd('syntax enable')

set.list = true
set.listchars = { tab = '▸ ', trail = '·' }
set.termguicolors = true

require('doom.plugin')
require('doom.config')
require('doom.key')
