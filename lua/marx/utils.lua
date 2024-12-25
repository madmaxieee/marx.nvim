local M = {}

local next_mark_id = 0

M.group = "MarxGroup"

---@class marx.AddSignOpts
---@field bufnr number
---@field lnum number
---@field text string
---@field priority number?

---@param opts marx.AddSignOpts
---@return number: sign id of the added sign
M.add_sign = function(opts)
  opts.priority = opts.priority or 10
  local placed_id = M.get_sign_id(opts.bufnr, opts.lnum)
  if placed_id then
    return placed_id
  end
  return M._add_sign(opts)
end

---@param opts marx.AddSignOpts
---@return number: sign id of the added sign
M._add_sign = function(opts)
  next_mark_id = next_mark_id + 1
  local sign_id = next_mark_id
  local sign_name = "Marx_" .. sign_id
  vim.fn.sign_define(sign_name, {
    text = opts.text,
    texthl = "MarxSignHL",
    numhl = "MarxSignNumHL",
  })
  vim.fn.sign_place(sign_id, M.group, sign_name, opts.bufnr, {
    lnum = opts.lnum,
    priority = opts.priority,
  })
  return sign_id
end

---@class marx.RemoveSignOpts
---@field bufnr number
---@field lnum number

---@param opts marx.RemoveSignOpts
M.remove_sign = function(opts)
  local placed = vim.fn.sign_getplaced(opts.bufnr, { group = M.group })
  local signs = placed[1] and placed[1].signs or {}
  local to_remove = nil
  for _, sign in ipairs(signs) do
    if sign.lnum == opts.lnum then
      to_remove = sign.id
    end
  end
  if to_remove == nil then
    return
  end
  vim.fn.sign_unplace(M.group, { id = to_remove, buffer = opts.bufnr })
end

---get sign id placed on a line
---@param bufnr number
---@param lnum number
---@return number?: the id of the sign placed on the line or nil if no sign is placed
M.get_sign_id = function(bufnr, lnum)
  local placed = vim.fn.sign_getplaced(bufnr, { group = M.group })
  local signs = placed[1] and placed[1].signs or {}
  for _, sign in ipairs(signs) do
    if sign.lnum == lnum then
      return sign.id
    end
  end
  return nil
end

return M
