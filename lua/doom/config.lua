vim.cmd('colorscheme tokyonight-moon')
vim.notify = require('notify')

require('nvim-tree').setup({
  sort_by = "case_sensitive",
  view = {
    adaptive_size = true,
  },
  renderer = {
    group_empty = true,
    indent_markers = {
      enable = true
    },
    icons = {
      show = {
        file = true,
        folder = true,
        folder_arrow = true,
        git = true
      }
    }
  },
  filters = {
    dotfiles = true,
  }
})

local telescope = require('telescope')
telescope.load_extension('lsp_handlers')

require('todo-comments').setup({
  keywords = {
    FIX = {
      icon = ' ',
      color = 'error',
      alt = { 'FIXME', 'BUG', 'FIXIT', 'ISSUE' },
    },
    TODO = { icon = ' ', color = 'info' },
    HACK = { icon = ' ', color = 'warning' },
    WARN = {
      icon = ' ',
      color = 'warning',
      alt = { 'WARNING', 'XXX' }
    },
    PERF = {
      icon = '⚡️',
      alt = { 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' }
    },
    NOTE = {
      icon = '📝', color = 'hint', alt = { 'INFO' }
    },
    TEST = {
      icon = '⏲ ',
      color = 'test',
      alt = { 'TESTING', 'PASSED', 'FAILED' }
    },
  }
})

require('nvim-autopairs').setup({})
require('fidget').setup({})
require('gitsigns').setup({})
require('dressing').setup({
  select = {
    backend = { 'telescope' }
  }
})

require('toggleterm').setup()
require('crates').setup()

require('nvim-treesitter.configs').setup({
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false
  },
  sync_install = false,
  ignore_install = {},
  modules = {},
  -- Just install them all... In favor of NixOS
  -- not b*tching around, I wiped 'ensure_installed'
  ensure_installed = {},
  auto_install = false
})

vim.o.completeopt = 'menuone,noinsert,noselect'

local cmp = require('cmp')
cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'nvim_lsp_signature_help' },
    { name = 'luasnip' },
    { name = 'path' },
    { name = 'crates' }
  }, {}),
  formatting = {
    fields = {'menu', 'abbr', 'kind'},
    format = function(entry, item)
      local menu_icon ={
        nvim_lsp = 'λ',
        luasnip = '⋗',
        buffer = 'Ω',
        path = '🖫',
      }
      item.menu = menu_icon[entry.source.name]
      return item
    end,
  }
})

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline(),
  sources = cmp.config.sources({
    { name = 'path' }
  }, {
    { name = 'cmdline' }
  })
})

-- LSP Servers
local navic = require('nvim-navic')
local lsp_attach_func = function(client, bufnr)
  if client.server_capabilities.documentSymbolProvider then
    navic.attach(client, bufnr)
  end
end
local lsp = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()
lsp['lua_ls'].setup({
  on_attach = lsp_attach_func,
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT'
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
      },
      telemetry = {
        enable = false
      },
      diagnostics = {
        globals = {
          "vim"
        }
      },
    }
  }
})
lsp['nixd'].setup({
  on_attach = lsp_attach_func,
  capabilities = capabilities
})

local on_attach = function(client, bufnr)
  lsp_attach_func(client, bufnr)

  vim.keymap.set("n", "<c-space>", require("rust-tools.hover_actions").hover_actions, { buffer = bufnr })

  vim.keymap.set("n", "<leader>a", require("rust-tools.code_action_group").code_action_group, { buffer = bufnr })
end

require("rust-tools").setup({
  tools = {
    runnables = {
      use_telescope = true,
    },
    inlay_hints = {
      auto = true,
      show_parameter_hints = false,
      parameter_hints_prefix = '',
      other_hints_prefix = ''
    },
  },
  server = {
    settings = {
      ['rust-analyzer'] = {
        checkOnSave = {
          enable = true,
          command = 'clippy'
        },
        imports = {
          granularity = {
            group = 'module'
          },
          prefix = 'self'
        },
        cargo = {
          loadOutDirsFromCheck = true,
        },
        procMacro = {
          enable = true
        },
      }
    },
    on_attach = on_attach,
    capabilities = capabilities -- Assuming capabilities is defined somewhere else in your config
  },
})

local dap = require('dap')
dap.adapters.lldb = {
  type = 'executable',
  command = vim.fn.system('which lldb'),
  name = 'lldb'
}

dap.configurations.c = {
  {
    name = 'launch',
    type = 'lldb',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
  }
}

dap.configurations.rust = {
  {
    name = 'launch',
    type = 'lldb',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
    initCommands = function()
      -- Find out where to look for the pretty printer Python module
      local rustc_sysroot = vim.fn.trim(vim.fn.system('rustc --print sysroot'))

      local script_import = 'command script import "' .. rustc_sysroot .. '/lib/rustlib/etc/lldb_lookup.py"'
      local commands_file = rustc_sysroot .. '/lib/rustlib/etc/lldb_commands'

      local commands = {}
      local file = io.open(commands_file, 'r')
      if file then
        for line in file:lines() do
          table.insert(commands, line)
        end
        file:close()
      end
      table.insert(commands, 1, script_import)

      return commands
    end,
    env = function()
      local variables = {}
      for k, v in pairs(vim.fn.environ()) do
        table.insert(variables, string.format("%s=%s", k, v))
      end
      return variables
    end,
  }
}

vim.g['vimtex_view_method'] = 'zathura'
vim.g['vimtex_compiler_method'] = 'arara'

require('doom.config.heirline')
