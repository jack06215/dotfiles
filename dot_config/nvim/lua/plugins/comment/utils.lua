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

return U

