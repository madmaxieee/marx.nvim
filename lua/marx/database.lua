local has_sqlite, sqlite = pcall(require, "sqlite")
if not has_sqlite then
  error "This plugin requires sqlite.lua (https://github.com/kkharji/sqlite.lua)"
end

local M = {}

local tbl = require "sqlite.tbl"

local marks_tbl = tbl("marks", {
  id = true,
  path = { "text", required = true },
  row = { "integer", required = true },
  title = { "text", required = true },
  content = { "text", required = true },
})

M.db = sqlite {
  uri = vim.fn.stdpath "data" .. "/marx.sqlite.db",
  marks = marks_tbl,
}

---@type table<number, marx.MarkData>
M.marks = {}

---@type table<string, table<number, marx.MarkData>>
M.file_marks = {}

---@class marx.DatabaseSetupOpts
---@field root_path string The root path for the marks, used to filter marks by file path.

---@param opts marx.DatabaseSetupOpts
function M.setup(opts)
  ---@type marx.MarkData[]
  local rows = marks_tbl:get {}
  for _, row in ipairs(rows) do
    -- PERF: huge waste if we have a lot of marks, try to make string like work
    if vim.startswith(row.path, opts.root_path) then
      M.marks[row.id] = {
        id = row.id,
        path = row.path,
        row = row.row,
        title = row.title,
        content = row.content,
      }
      M.file_marks[row.path] = M.file_marks[row.path] or {}
      M.file_marks[row.path][row.id] = M.marks[row.id]
    end
  end
end

---@param mark marx.MarkData
function M.insert_mark(mark)
  mark.id = marks_tbl:insert {
    path = mark.path,
    row = mark.row,
    title = mark.title,
    content = mark.content,
  }
  M.marks[mark.id] = mark
  M.file_marks[mark.path] = M.file_marks[mark.path] or {}
  M.file_marks[mark.path][mark.id] = mark
  return mark.id
end

---@param mark marx.MarkData
function M.update_mark(mark)
  marks_tbl:update {
    where = { id = mark.id },
    set = {
      path = mark.path,
      row = mark.row,
      title = mark.title,
      content = mark.content,
    },
  }
end

---@param id number
function M.remove_mark(id)
  marks_tbl:remove { where = { id = id } }
  M.file_marks[M.marks[id].path][id] = nil
  M.marks[id] = nil
end

return M
