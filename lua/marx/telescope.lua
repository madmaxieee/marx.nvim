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

local marx_actions = require "marx.actions"

---@class FormatEntryConstraints
---@field max_title number?
---@field max_filename number?
---@field max_filepath number?

---@param mark marx.MarkData
---@param constraints FormatEntryConstraints
local function format_entry(mark, constraints)
  local max_title = math.max(constraints.max_title or 15, 15)
  local max_filename = math.max(constraints.max_filename or 20, 20)
  local max_filepath = math.max(constraints.max_filepath or 30, 30)
  max_title = math.min(max_title, 30)
  max_filename = math.min(max_filename, 30)
  max_filepath = math.min(max_filepath, 40)

  local name = mark.title
  local filename = vim.fn.fnamemodify(mark.file, ":t")
  local path = vim.fn.pathshorten(mark.file)

  -- Pad or truncate name
  if #name > max_title then
    name = name:sub(1, max_title - 2) .. ".."
  else
    name = name .. string.rep(" ", max_title - #name)
  end

  -- Pad or truncate filename
  if #filename > max_filename then
    filename = filename:sub(1, max_filename - 2) .. ".."
  else
    filename = filename .. string.rep(" ", max_filename - #filename)
  end

  -- Pad or truncate path
  if #path > max_filepath then
    path = path:sub(1, max_filepath - 2) .. ".."
  else
    path = path .. string.rep(" ", max_filepath - #path)
  end

  return string.format("%s │ %s │ %s", name, filename, path)
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

    ---@type FormatEntryConstraints
    local constraints = {
      max_title = 0,
      max_filename = 0,
      max_filepath = 0,
    }

    for _, m in ipairs(marks) do
      constraints.max_title = math.max(constraints.max_title, #m.title)
      local filename = vim.fn.fnamemodify(m.file, ":t")
      local path = vim.fn.pathshorten(m.file)
      constraints.max_filename = math.max(constraints.max_filename, #filename)
      constraints.max_filepath = math.max(constraints.max_filepath, #path)
    end

    pickers
      .new({}, {
        prompt_title = "Pick Our Bookmarks",
        finder = finders.new_table {
          results = marks,
          ---@param bookmark marx.MarkData
          entry_maker = function(bookmark)
            local display = format_entry(bookmark, constraints)
            return {
              value = bookmark,
              display = display,
              ordinal = display,
              filename = bookmark.file,
              col = 0,
              lnum = bookmark.row + 1,
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
