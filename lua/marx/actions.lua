local M = {}

local marx = require "marx.marks"
local database = require "marx.database"

---@param id number # bookmark ID
---@param opts? {cmd?: "edit" | "tabnew" | "split" | "vsplit"}
function M.jump(id, opts)
  opts = opts or {}

  local mark = database.marks[id]
  if not mark then
    error "Bookmark not found"
  end

  -- Handle floating window case
  local cmd = opts.cmd or "edit"
  if mark.file ~= vim.fn.expand "%:p" then
    vim.cmd(cmd .. " " .. vim.fn.fnameescape(mark.file))
  end

  vim.api.nvim_win_set_cursor(0, { mark.row + 1, 0 })
end

function M.remove(id)
  local mark = database.marks[id]
  marx.remove_mark { id = id, bufnr = vim.uri_to_bufnr(vim.uri_from_fname(mark.file)) }
  database.remove_mark(id)
end

return M
