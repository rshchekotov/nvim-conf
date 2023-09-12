local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  -- Self Managed
  use 'wbthomason/packer.nvim'

  -- Development: Language Support
  use 'LnL7/vim-nix'
  use 'lervag/vimtex'
  use 'simrat39/rust-tools.nvim'
  use {
    'saecki/crates.nvim',
    tag = 'v0.3.0',
    requires = 'nvim-lua/plenary.nvim'
  }

  -- Development: Grammar / Syntax
  use {
    'folke/trouble.nvim',
    requires = 'nvim-tree/nvim-web-devicons'
  }
  use {
    'nvim-treesitter/nvim-treesitter',
    run = function()
      local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
      ts_update()
    end,
  }
  use {
    'SmiteshP/nvim-navic',
    requires = 'neovim/nvim-lspconfig'
  }

  -- Development: LSP & Completion
  use 'windwp/nvim-autopairs'
  use 'neovim/nvim-lspconfig'
  use 'mfussenegger/nvim-dap'
  use {
    'hrsh7th/nvim-cmp',
    requires = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-cmdline',
      {
        'L3MON4D3/LuaSnip',
        tag = 'v2.*'
      },
      'saadparwaiz1/cmp_luasnip',
      'neovim/nvim-lspconfig'
    }
  }

  use 'direnv/direnv.vim'

  -- Note Taking
  use {
    'nvim-neorg/neorg',
    ft = 'norg',
    after = { 'nvim-treesitter', 'telescope.nvim' },
    config = function()
      require('neorg').setup({
        load = {
          ['core.defaults'] = {},
          ['core.concealer'] = {},
          ['core.dirman'] = {
            config = {
              workspaces = {
                notes = '~/notes'
              }
            }
          }
        }
      })
    end,
    requires = 'nvim-lua/plenary.nvim'
  }

  -- Files / Search
  use 'moll/vim-bbye'
  use {
    'nvim-tree/nvim-tree.lua',
    requires = 'nvim-tree/nvim-web-devicons'
  }
  use {
    'nvim-telescope/telescope.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope-symbols.nvim',
      'gbrlsnchs/telescope-lsp-handlers.nvim'
    }
  }

  -- UI Enhancements
  use 'folke/todo-comments.nvim'
  use 'rcarriga/nvim-notify'
  use 'stevearc/dressing.nvim'
  use 'lewis6991/gitsigns.nvim'
  use 'rebelot/heirline.nvim'

  use {
    'j-hui/fidget.nvim',
    tag = 'legacy'
  }

  use {
    'akinsho/toggleterm.nvim',
    tag = '*'
  }

  -- Color Schemes
  use 'folke/tokyonight.nvim'

  -- Debug & Profiling
  -- Vim StartupTime: nvim +StartupTime
  use 'dstein64/vim-startuptime'

  if packer_bootstrap then
    require('packer').sync()
  end
end)
