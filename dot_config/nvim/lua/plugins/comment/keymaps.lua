--- Key mappings for Comment.nvim

local M = {}

--- Define the key mappings for the Comment.nvim plugin.
--- @return table: The key mappings table, including mode and description for each key mapping.
function M.get_keymaps()
  --- Helper function to enable silent mode for key mappings.
  --- @param t table: The key mapping table.
  --- @return table: The modified table with `silent` set to true.
  local silent = function(t)
    t.silent = true
    return t
  end

  return {
    -- Basic comment toggle in normal and visual modes.
    silent({ "gcc", nil, mode = "n", desc = "Comment: toggle" }),
    silent({ "gc", nil, mode = "v", desc = "Comment: toggle visual" }),

    -- Create a backup of the current line before commenting.
    silent({ "gcb", "yyPgccj", mode = "n", desc = "Comment: create backup", remap = true }),

    -- Invert comments using the custom operator function.
    silent({
      "gC",
      "<Cmd>set operatorfunc=v:lua.__flip_flop_comment<CR>g@",
      mode = { "n", "x" },
      desc = "Invert comments",
    }),

    -- Add a comment at the end of the current line.
    silent({ "gcA", function()
      require("plugins.comment.utils").append_eol_comment()
    end, mode = "n", desc = "Comment at end of line" }),
  }
end

return M

