local M = {}

local database = require "marx.database"

---@type snacks.picker.Config
M.source = {
  title = "marx",
  finder = function()
    ---@type marx.MarkData
    local marks = vim.tbl_values(database.marks)
    local items = vim.tbl_map(
      ---@param mark marx.MarkData
      function(mark)
        local title = mark.title
        local filename = vim.fn.fnamemodify(mark.path, ":t")
        local path = mark.path
        if #title < 40 then
          title = title .. string.rep(" ", 40 - #title)
        end
        ---@type snacks.picker.finder.Item
        local item = {
          text = table.concat({ title, filename, path }, " "),
          label = title,
          file = mark.path,
          pos = { mark.row + 1, 0 },
        }
        return item
      end,
      marks
    )
    return items
  end,
  format = "file",
}

return M
