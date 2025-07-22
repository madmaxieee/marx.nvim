local M = {}

local highlight = require "marx.highlight"
local database = require "marx.database"

M.group = "MarxGroup"
M.ns_id = vim.api.nvim_create_namespace(M.group)

---@class marx.RemoveMarkOpts
---@field id number? -- if nil, the mark at the given row will be removed
---@field bufnr number
---@field row number?

---@param opts marx.RemoveMarkOpts
function M.remove_mark(opts)
  if opts.id then
    vim.api.nvim_buf_del_extmark(opts.bufnr, M.ns_id, opts.id)
    return
  end

  local to_remove_id = M.get_mark_id(opts.bufnr, opts.row)
  if not to_remove_id then
    return
  end
  vim.api.nvim_buf_del_extmark(opts.bufnr, M.ns_id, to_remove_id)
end

function M.get_mark_id(bufnr, row)
  local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, M.ns_id, { row, 0 }, { row + 1, 0 }, { limit = 1 })
  if #extmarks == 0 then
    return nil
  end
  return extmarks[1][1]
end

function M.get_mark(bufnr, row)
  local extmarks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    M.ns_id,
    { row, 0 },
    { row + 1, 0 },
    { limit = 1, details = true }
  )
  if #extmarks == 0 then
    return nil
  end
  return extmarks[1]
end

function M.get_mark_by_id(bufnr, id)
  local mark = vim.api.nvim_buf_get_extmark_by_id(bufnr, M.ns_id, id, { details = true })
  return mark
end

---@class marx.SetMarkOpts
---@field id number
---@field text string|table
---@field bufnr number
---@field row number

---@param opts marx.SetMarkOpts
local function _set_extmark(opts)
  local text = opts.text
  if type(text) == "string" then
    text = { { text, highlight.virt_text_hl } }
  end

  local function set_mark()
    local line = vim.api.nvim_buf_get_lines(opts.bufnr, opts.row, opts.row + 1, false)[1] or ""
    local line_length = #line
    vim.api.nvim_buf_set_extmark(opts.bufnr, M.ns_id, opts.row, 0, {
      id = opts.id,
      hl_group = highlight.code_hl,
      end_row = opts.row,
      end_col = line_length,
      virt_text = text,
      virt_text_pos = "eol",
      priority = 10,
      sign_text = "",

      sign_hl_group = highlight.sign_hl,
    })
  end

  if vim.api.nvim_buf_is_loaded(opts.bufnr) then
    set_mark()
  else
    vim.api.nvim_create_autocmd("BufRead", {
      pattern = ("<buffer=%d>"):format(opts.bufnr),
      once = true,
      callback = set_mark,
    })
  end
end

---@param opts marx.SetMarkOpts
function M.set_extmark(opts)
  pcall(_set_extmark, opts)
end

---@param id number
---@param buf_content? string[]
function M.calibrate_mark(id, buf_content)
  local mark = database.marks[id]
  local bufnr = vim.uri_to_bufnr(vim.uri_from_fname(mark.file))
  buf_content = buf_content or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local extmark_pos = vim.api.nvim_buf_get_extmark_by_id(bufnr, M.ns_id, id, {})
  if #extmark_pos ~= 0 then
    local new_row = extmark_pos[1]
    mark.row = new_row
    mark.code = buf_content[new_row + 1]
    database.update_mark(mark)
    return
  end

  if buf_content[mark.row + 1] == mark.code then
    return
  end

  for i = 1, #buf_content do
    if mark.row + 1 + i <= #buf_content and buf_content[mark.row + 1 + i] == mark.code then
      mark.row = mark.row + i
      break
    end
    if mark.row + 1 - i >= 1 and buf_content[mark.row + 1 - i] == mark.code then
      mark.row = mark.row - i
      break
    end
  end

  M.set_extmark {
    id = id,
    text = mark.title,
    bufnr = bufnr,
    row = mark.row,
  }
  database.update_mark(mark)
end

---@param bufnr number
function M.calibrate_buf(bufnr)
  local filename = vim.uri_to_fname(vim.uri_from_bufnr(bufnr))
  local buf_content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for mark_id, _ in pairs(database.file_marks[filename] or {}) do
    M.calibrate_mark(mark_id, buf_content)
  end
end

return M
