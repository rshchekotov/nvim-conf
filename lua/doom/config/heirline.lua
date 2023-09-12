local conditions = require('heirline.conditions')
local utils = require('heirline.utils')
local colors = require("tokyonight.colors").setup({
  style = 'moon'
})

-- Components
local Align = { provider = "%=" }
local Space = { provider = " " }
local LeftDiv = { provider = "  " }
local RightDiv = { provider = "  " }
local LeftPixels = { provider = "" }
local Block = { provider = '█' }

local ViMode = {
  init = function(self)
      self.mode = vim.fn.mode(1)
  end,
  static = {
    mode_names = {
      n = "N",
      no = "N?",
      nov = "N?",
      noV = "N?",
      ["no\22"] = "N?",
      niI = "Ni",
      niR = "Nr",
      niV = "Nv",
      nt = "Nt",
      v = "V",
      vs = "Vs",
      V = "V_",
      Vs = "Vs",
      ["\22"] = "^V",
      ["\22s"] = "^V",
      s = "S",
      S = "S_",
      ["\19"] = "^S",
      i = "I",
      ic = "Ic",
      ix = "Ix",
      R = "R",
      Rc = "Rc",
      Rx = "Rx",
      Rv = "Rv",
      Rvc = "Rv",
      Rvx = "Rv",
      c = "C",
      cv = "Ex",
      r = "...",
      rm = "M",
      ["r?"] = "?",
      ["!"] = "!",
      t = "T",
    },
    mode_colors = {
      n = "red" ,
      i = "green",
      v = "cyan",
      V =  "cyan",
      ["\22"] =  "cyan",
      c =  "orange",
      s =  "purple",
      S =  "purple",
      ["\19"] =  "purple",
      R =  "orange",
      r =  "orange",
      ["!"] =  "red",
      t =  "red",
    }
  },
  provider = function(self)
    return Block.provider .. "  %2("..self.mode_names[self.mode].."%) " .. LeftPixels.provider .. ' '
  end,
  hl = function(self)
    local mode = self.mode:sub(1, 1)
    return { fg = self.mode_colors[mode], bold = true, }
  end,
  update = {
    "ModeChanged",
    pattern = "*:*",
    callback = vim.schedule_wrap(function()
      vim.cmd("redrawstatus")
    end),
  },
}

local FileNameBlock = {
  init = function(self)
    self.filename = vim.api.nvim_buf_get_name(0)
  end,
}

local FileIcon = {
  init = function(self)
    local filename = self.filename
    local extension = vim.fn.fnamemodify(filename, ":e")
    self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
  end,
  provider = function(self)
    return self.icon and (self.icon .. " ")
  end,
  hl = function(self)
    return { fg = self.icon_color }
  end
}

local FileName = {
  provider = function(self)
    local filename = vim.fn.fnamemodify(self.filename, ":.")
    if filename == "" then return "[No Name]" end
    if not conditions.width_percent_below(#filename, 0.25) then
      filename = vim.fn.pathshorten(filename)
    end
    return filename
  end,
  hl = { fg = utils.get_highlight("Directory").fg },
}

local FileFlags = {
  {
    condition = function()
      return vim.bo.modified
    end,
    provider = "[+]",
    hl = { fg = "green" },
  },
  {
    condition = function()
      return not vim.bo.modifiable or vim.bo.readonly
    end,
    provider = "",
    hl = { fg = "orange" },
  },
}

local FileNameModifer = {
  hl = function()
    if vim.bo.modified then
      return { fg = "cyan", bold = true, force = true }
    end
  end,
}

local FileSize = {
  provider = function()
    local suffix = { 'b', 'k', 'M', 'G', 'T', 'P', 'E' }
    local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
    fsize = (fsize < 0 and 0) or fsize
    if fsize < 1024 then
      return fsize..suffix[1]
    end
    local i = math.floor((math.log(fsize) / math.log(1024)))
    return string.format("%.2g%s", fsize / math.pow(1024, i), suffix[i + 1])
  end
}

FileNameBlock = utils.insert(FileNameBlock,
  FileIcon,
  utils.insert(FileNameModifer, FileName),
  Space,
  FileFlags,
  { provider = '%<' })

local FileType = {
  provider = function()
    return string.upper(vim.bo.filetype)
  end,
  hl = { fg = utils.get_highlight("Type").fg, bold = true },
}

local Ruler = {
  -- %l = current line number
  -- %L = number of lines in the buffer
  -- %c = column number
  -- %P = percentage through file of displayed window
  provider = "%7(%l/%3L%):%2c %P",
}

local ScrollBar ={
  static = {
    sbar = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' }
    -- sbar = { '🭶', '🭷', '🭸', '🭹', '🭺', '🭻' }
  },
  provider = function(self)
    local curr_line = vim.api.nvim_win_get_cursor(0)[1]
    local lines = vim.api.nvim_buf_line_count(0)
    local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
    return string.rep(self.sbar[i], 2)
  end,
  hl = { fg = "blue", bg = "bg" },
}

local LSPActive = {
  condition = conditions.lsp_attached,
  update = {'LspAttach', 'LspDetach'},
  on_click = {
    name = 'heirline_lsp',
    callback = function()
      vim.defer_fn(function()
        vim.cmd('LspInfo')
      end, 100)
    end
  },

  -- Or complicate things a bit and get the servers names
  provider  = function()
    local names = {}
    for _, server in pairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
      table.insert(names, server.name)
    end
    return " [" .. table.concat(names, " ") .. "]"
  end,
  hl = { fg = "green", bold = true },
}

-- Full nerd (with icon colors and clickable elements)!
-- works in multi window, but does not support flexible components (yet ...)
local Navic = {
  condition = function() return require("nvim-navic").is_available() end,
  static = {
    type_hl = {
      File = "Directory",
      Module = "@include",
      Namespace = "@namespace",
      Package = "@include",
      Class = "@structure",
      Method = "@method",
      Property = "@property",
      Field = "@field",
      Constructor = "@constructor",
      Enum = "@field",
      Interface = "@type",
      Function = "@function",
      Variable = "@variable",
      Constant = "@constant",
      String = "@string",
      Number = "@number",
      Boolean = "@boolean",
      Array = "@field",
      Object = "@type",
      Key = "@keyword",
      Null = "@comment",
      EnumMember = "@field",
      Struct = "@structure",
      Event = "@keyword",
      Operator = "@operator",
      TypeParameter = "@type",
    },
    -- bit operation dark magic, see below...
    enc = function(line, col, winnr)
      return bit.bor(bit.lshift(line, 16), bit.lshift(col, 6), winnr)
    end,
    -- line: 16 bit (65535); col: 10 bit (1023); winnr: 6 bit (63)
    dec = function(c)
      local line = bit.rshift(c, 16)
      local col = bit.band(bit.rshift(c, 6), 1023)
      local winnr = bit.band(c,  63)
      return line, col, winnr
    end
  },
    init = function(self)
      local data = require("nvim-navic").get_data() or {}
      local children = {}
      -- create a child for each level
      for i, d in ipairs(data) do
        -- encode line and column numbers into a single integer
        local pos = self.enc(d.scope.start.line, d.scope.start.character, self.winnr)
        local child = {
          {
            provider = d.icon,
            hl = self.type_hl[d.type],
          },
          {
            -- escape `%`s (elixir) and buggy default separators
            provider = d.name:gsub("%%", "%%%%"):gsub("%s*->%s*", ''),
            -- highlight icon only or location name as well
            -- hl = self.type_hl[d.type],

            on_click = {
              -- pass the encoded position through minwid
              minwid = pos,
              callback = function(_, minwid)
                -- decode
                local line, col, winnr = self.dec(minwid)
                vim.api.nvim_win_set_cursor(vim.fn.win_getid(winnr), {line, col})
              end,
              name = "heirline_navic",
            },
          },
        }
        -- add a separator only if needed
        if #data > 1 and i < #data then
          table.insert(child, {
            provider = " > ",
            hl = { fg = 'fg' },
          })
        end
        table.insert(children, child)
      end
      -- instantiate the new child, overwriting the previous one
      self.child = self:new(children, 1)
    end,
    -- evaluate the children containing navic components
    provider = function(self)
      return self.child:eval()
    end,
    hl = { fg = "gray" },
    update = 'CursorMoved'
}

local Diagnostics = {
  condition = conditions.has_diagnostics,
  static = {
    error_icon = 'E', -- vim.cmd('echo sign_getdefined("DiagnosticSignError")[0].text'),
    warn_icon = 'W', -- vim.cmd('echo sign_getdefined("DiagnosticSignWarn")[0].text'),
    info_icon = 'I', -- vim.cmd('echo sign_getdefined("DiagnosticSignInfo")[0].text'),
    hint_icon = 'H', -- vim.cmd('echo sign_getdefined("DiagnosticSignHint")[0].text')
  },
  init = function(self)
    self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
    self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
  end,
  update = { "DiagnosticChanged", "BufEnter" },
  on_click = {
    name = 'heirline_diagnostics',
    callback = function()
      require('trouble').toggle({ mode = 'document_diagnostics' })
    end
  },
  {
    provider = "![",
  },
  {
    provider = function(self)
      -- 0 is just another output, we can decide to print it or not!
      return self.errors > 0 and (self.error_icon .. self.errors .. " ")
    end,
    hl = { fg = "error" },
  },
  {
    provider = function(self)
      return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
    end,
    hl = { fg = "warning" },
  },
  {
    provider = function(self)
      return self.info > 0 and (self.info_icon .. self.info .. " ")
    end,
    hl = { fg = "info" },
  },
  {
    provider = function(self)
      return self.hints > 0 and (self.hint_icon .. self.hints)
    end,
    hl = { fg = "hint" },
  },
  {
    provider = "]",
  },
}

local Git = {
  condition = conditions.is_git_repo,
  init = function(self)
    self.status_dict = vim.b.gitsigns_status_dict
    self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
  end,

  hl = { fg = "orange" },

  {   -- git branch name
    provider = function(self)
      return " " .. self.status_dict.head
    end,
    hl = { bold = true }
  },
  -- You could handle delimiters, icons and counts similar to Diagnostics
  {
    condition = function(self)
      return self.has_changes
    end,
    provider = "("
  },
  {
    provider = function(self)
      local count = self.status_dict.added or 0
      return count > 0 and ("+" .. count)
    end,
    hl = { fg = colors.git.add },
  },
  {
    provider = function(self)
      local count = self.status_dict.removed or 0
      return count > 0 and ("-" .. count)
    end,
    hl = { fg = colors.git.delete },
  },
  {
    provider = function(self)
      local count = self.status_dict.changed or 0
      return count > 0 and ("~" .. count)
    end,
    hl = { fg = colors.git.change },
  },
  {
    condition = function(self)
      return self.has_changes
    end,
    provider = ")",
  },
}

local TerminalName = {
  -- we could add a condition to check that buftype == 'terminal'
  -- or we could do that later (see #conditional-statuslines below)
  provider = function()
    local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
    return " " .. tname
  end,
  hl = { fg = "blue", bold = true },
}

-- ViMode = utils.surround({ "", "" }, "bg", { ViMode })
-- ViMode = utils.surround({ Block.provider, LeftPixels.provider }, "bg", { ViMode })

local DefaultStatusline = {
  ViMode, Space, FileNameBlock, Space, Git, LeftDiv, Diagnostics, Align,
  Navic, Align,
  LSPActive, RightDiv, FileType, RightDiv, FileSize, RightDiv, Ruler, Space, ScrollBar
}

local InactiveStatusline = {
  condition = conditions.is_not_active,
  FileType, Space, FileName, Align,
}

local SpecialStatusline = {
  condition = function()
    return conditions.buffer_matches({
        buftype = { "nofile", "prompt", "help", "quickfix" },
        filetype = { "^git.*", "fugitive" },
    })
  end,
  FileType, Align
}

local TerminalStatusline = {
  condition = function()
    return conditions.buffer_matches({ buftype = { "terminal" } })
  end,
  hl = { bg = "red1" },
  -- quickly add a condition to the ViMode to only show it when buffer is active!
  { condition = conditions.is_active, ViMode, Space }, FileType, Space, TerminalName, Align,
}

local StatusLines = {
  hl = function()
    if conditions.is_active() then
      return "StatusLine"
    else
      return "StatusLineNC"
    end
  end,

  -- the first statusline with no condition, or which condition returns true is used.
  -- think of it as a switch case with breaks to stop fallthrough.
  fallthrough = false,

  SpecialStatusline, TerminalStatusline, InactiveStatusline, DefaultStatusline,
}

require('heirline').setup({
  statusline = StatusLines,
  winbar = {},
  tabline = {},
  --statuscolumn = {},
  opts = {
    colors = colors
  }
})
