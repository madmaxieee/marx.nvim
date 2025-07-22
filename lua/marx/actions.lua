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

  local cmd = opts.cmd or "edit"
  if mark.path ~= vim.fn.expand "%:p" then
    vim.cmd(cmd .. " " .. vim.fn.fnameescape(mark.path))
  end

  local max_row = vim.api.nvim_buf_line_count(0) - 1
  if mark.row > max_row then
    vim.api.nvim_win_set_cursor(0, { max_row + 1, 0 })
    vim.notify("bookmark position out of bound", vim.log.levels.WARN)
  else
    vim.api.nvim_win_set_cursor(0, { mark.row + 1, 0 })
  end
end

function M.remove(id)
  local mark = database.marks[id]
  marx.remove_mark { id = id, bufnr = vim.uri_to_bufnr(vim.uri_from_fname(mark.path)) }
  database.remove_mark(id)
end

return M
