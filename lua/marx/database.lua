local has_sqlite, sqlite = pcall(require, "sqlite")
if not has_sqlite then
  error "This plugin requires sqlite.lua (https://github.com/kkharji/sqlite.lua)"
end

local M = {}

local tbl = require "sqlite.tbl"

local marks_tbl = tbl("marks", {
  id = true,
  file = { "text", required = true },
  row = { "integer", required = true },
  title = { "text", required = true },
  code = { "text", required = true },
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
  local rows = marks_tbl:get {}
  for _, row in ipairs(rows) do
    -- PERF: huge waste if we have a lot of marks, try to make string like work
    if vim.startswith(row.file, opts.root_path) then
      M.marks[row.id] = {
        id = row.id,
        file = row.file,
        row = row.row,
        title = row.title,
        code = row.code,
      }
      M.file_marks[row.file] = M.file_marks[row.file] or {}
      M.file_marks[row.file][row.id] = M.marks[row.id]
    end
  end
end

---@param mark marx.MarkData
function M.insert_mark(mark)
  mark.id = marks_tbl:insert {
    file = mark.file,
    row = mark.row,
    title = mark.title,
    code = mark.code,
  }
  M.marks[mark.id] = mark
  M.file_marks[mark.file] = M.file_marks[mark.file] or {}
  M.file_marks[mark.file][mark.id] = mark
  return mark.id
end

---@param mark marx.MarkData
function M.update_mark(mark)
  marks_tbl:update {
    where = { id = mark.id },
    set = {
      file = mark.file,
      row = mark.row,
      title = mark.title,
      code = mark.code,
    },
  }
end

---@param id number
function M.remove_mark(id)
  marks_tbl:remove { where = { id = id } }
  M.file_marks[M.marks[id].file][id] = nil
  M.marks[id] = nil
end

return M
