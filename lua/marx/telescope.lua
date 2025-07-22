local M = {}

local database = require "marx.database"
local utils = require "marx.utils"

local has_telescope, _ = pcall(require, "telescope")
if not has_telescope then
  error "This picker requires telescope.nvim to be installed"
end

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local actions = require "telescope.actions"
local conf = require("telescope.config").values
local action_state = require "telescope.actions.state"
local entry_display = require "telescope.pickers.entry_display"
local transform_devicons = require("telescope.utils").transform_devicons

local marx_actions = require "marx.actions"

---@param mark marx.MarkData
local function make_ordinal(mark)
  local title = mark.title
  local filename = vim.fn.fnamemodify(mark.file, ":t")
  local path = mark.file

  if #title < 50 then
    title = title .. string.rep(" ", 50 - #title)
  end

  return string.format("%s │ %s %s", title, filename, path)
end

---@param callback fun(mark: marx.MarkData)
---@param opts? {marks?: marx.MarkData[]}
function M.pick_mark(callback, opts)
  opts = opts or {}
  if not opts.marks then
    local marks_list = {}
    for _, value in pairs(database.marks) do
      table.insert(marks_list, value)
    end
    opts.marks = marks_list
  end

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 40 },
      { width = 1 },
      { remaining = true },
      { remaining = true },
    },
  }

  ---@param entry {value:marx.MarkData}
  local make_display = function(entry)
    local path = entry.value.file
    local filename = vim.fn.fnamemodify(entry.value.file, ":t")
    local _, hl_group, icon = transform_devicons(filename, "", false)

    local cwd = vim.fn.getcwd()
    if path:sub(1, #cwd) == cwd then
      path = "." .. path:sub(#cwd + 1)
    end
    local home_dir = vim.fn.expand "~"
    if path:sub(1, #home_dir) == home_dir then
      path = "~" .. path:sub(#home_dir + 1)
    end

    return displayer {
      { entry.value.title, "TelescopeResultsIdentifier" },
      { icon, hl_group },
      vim.fn.fnamemodify(entry.value.file, ":t"),
      { path, "TelescopeResultsField" },
    }
  end

  ---@param marks marx.MarkData[]
  local function open_picker(marks)
    marks = utils.filter_list(marks, function(mark)
      if type(mark) ~= "table" then
        return false
      end
      if not mark.id or not mark.file or not mark.row or not mark.title then
        return false
      end
      if not database.marks[mark.id] then
        return false
      end
      return true
    end)

    pickers
      .new({}, {
        prompt_title = "Our Bookmarx",
        finder = finders.new_table {
          results = marks,
          ---@param mark marx.MarkData
          entry_maker = function(mark)
            return {
              value = mark,
              display = make_display,
              ordinal = make_ordinal(mark),
              filename = mark.file,
              col = 0,
              lnum = mark.row + 1,
            }
          end,
        },
        sorter = conf.generic_sorter(opts),
        previewer = conf.grep_previewer(opts),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selected = action_state.get_selected_entry()
            if selected == nil then
              return
            end
            callback(selected.value)
          end)

          map("i", "<C-d>", function()
            local selected = action_state.get_selected_entry()
            if selected == nil then
              return
            end
            marx_actions.remove(selected.value.id)
            open_picker(marks)
          end)

          map("n", "x", function()
            local selected = action_state.get_selected_entry()
            if selected == nil then
              return
            end
            marx_actions.remove(selected.value.id)
            open_picker(marks)
          end)

          return true
        end,
      })
      :find()
  end

  open_picker(opts.marks)
end

return M
