local M = {}

local highlight = require "marx.highlight"

M.group = "MarxGroup"
M.ns_id = vim.api.nvim_create_namespace(M.group)
M.next_mark_id = 1

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
---@field id number? -- if nil, a new mark will be created
---@field priority number?
---@field text string|table
---@field bufnr number
---@field row number

---@param opts marx.SetMarkOpts
function M.set_mark(opts)
  local text = opts.text
  if type(text) == "string" then
    text = { { text, highlight.virt_text_hl } }
  elseif not text then
    text = {} -- empty if nil
  end
  local id
  if opts.id then
    id = opts.id
  else
    id = M.next_mark_id
    M.next_mark_id = M.next_mark_id + 1
  end
  vim.api.nvim_buf_set_extmark(opts.bufnr, M.ns_id, opts.row, 0, {
    id = id,
    virt_text = text,
    virt_text_pos = "eol",
    hl_mode = "combine",
    priority = opts.priority or 10,
    sign_text = "",
    sign_hl_group = highlight.sign_hl,
  })
end

return M
