--- Utility functions for Comment.nvim

local U = {}

--- Determine if a line is commented based on the provided commentstring.
--- @param line string: The line to check.
--- @param commentstring string: The comment string to match.
--- @return boolean: True if the line is commented, false otherwise.
function U.is_commented_line(line, commentstring)
  -- Uses the Comment.nvim utility functions to check if a line is commented.
  local padding = true
  local ll, rr = require("Comment.utils").unwrap_cstr(commentstring)
  local is_commented = require("Comment.utils").is_commented(ll, rr, padding)
  return is_commented(line)
end

--- Add a comment at the end of the current line and enter insert mode after it.
--- Only reads 'commentstring', so it needs no Comment.nvim -- which is why
--- config/keymaps/vscode.lua can bind it too, where Comment.nvim is not loaded.
function U.append_eol_comment()
  local commentstring = vim.bo.commentstring:gsub("%%s", ""):gsub("%s+$", "")
  local line = vim.api.nvim_get_current_line()
  local has_comment = line:find(commentstring, 1, true)
  if not has_comment then
    local new_line = line .. " " .. commentstring .. " "
    vim.api.nvim_set_current_line(new_line)
    vim.cmd("normal! $a")
  else
    vim.cmd("normal! $a")
  end
end

return U

