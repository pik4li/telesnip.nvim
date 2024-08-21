-- <name>
testing
---
M.save_custom_snippet = function()
  local current_filetype = vim.bo.filetype
  local custom_snippet_path = M.snippet_path .. "custom_" .. current_filetype .. ".lua"

