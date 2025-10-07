local M = {}

local database = require "marx.database"

---@class marx.SnacksItem: snacks.picker.finder.Item
---@field marx_id number

---@module "snacks"
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
        ---@type marx.SnacksItem
        local item = {
          text = table.concat({ title, filename, path }, " "),
          label = title,
          file = mark.path,
          pos = { mark.row + 1, 0 },
          marx_id = mark.id,
        }
        return item
      end,
      marks
    )
    return items
  end,
  format = "file",
  actions = {
    remove_marx = function(picker)
      picker.preview:reset()
      for _, item in ipairs(picker:selected { fallback = true }) do
        if item.marx_id then
          database.remove_mark(item.marx_id)
        end
      end
      picker.list:set_selected()
      picker.list:set_target()
      picker:find()
    end,
  },
  win = {
    input = {
      keys = {
        ["<c-x>"] = { "remove_marx", mode = { "n", "i" } },
      },
    },
    list = { keys = { ["dd"] = "remove_marx" } },
  },
}

return M
