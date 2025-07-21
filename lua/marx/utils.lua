local M = {}

---filters a list
---@param list any[]
---@param condition fun(item: any): boolean
---@return any[]
function M.filter_list(list, condition)
  local new_list = {}
  for _, v in ipairs(list) do
    if condition(v) then
      table.insert(new_list, v)
    end
  end
  return new_list
end

return M
