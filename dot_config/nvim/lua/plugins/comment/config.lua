--- Configuration for Comment.nvim

local Config = {}

--- Configure the Comment.nvim plugin.
--- This includes setting up context-aware commenting for TypeScript React files
--- and enabling basic and extra key mappings.
function Config.setup()
  -- Disable the ts_context_commentstring module globally for compatibility.
  vim.g.skip_ts_context_commentstring_module = true

  require("Comment").setup({
    ignore = "^$", -- Ignore empty lines when commenting.
    mappings = {
      basic = true, -- Enable basic key mappings.
      extra = true, -- Enable extra key mappings.
    },

    -- Pre-hook for calculating comment strings in TypeScript React files.
    pre_hook = function(ctx)
      if vim.bo.filetype == "typescriptreact" then
        local U, location = require("Comment.utils"), nil
        if ctx.ctype == U.ctype.blockwise then
          location = require("ts_context_commentstring.utils").get_cursor_location()
        elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
          location = require("ts_context_commentstring.utils").get_visual_start_location()
        end
        return require("ts_context_commentstring.internal").calculate_commentstring({
          key = ctx.ctype == U.ctype.linewise and "__default" or "__multiline",
          location = location,
        })
      end
      return nil
    end,
  })
end

return Config
