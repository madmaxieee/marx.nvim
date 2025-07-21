local M = {}

local marx = require "marx.marks"
local highlight = require "marx.highlight"
local database = require "marx.database"

function M.setup()
  highlight.setup()
  database.setup { root_path = vim.fn.getcwd() }

  for _, mark in pairs(database.marks) do
    marx.set_mark {
      id = mark.id,
      text = mark.title,
      bufnr = vim.uri_to_bufnr(vim.uri_from_fname(mark.file)),
      row = mark.row,
    }
  end
end

function M.set_bookmark()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local bufnr = vim.api.nvim_get_current_buf()

  local old_mark = marx.get_mark(bufnr, row)
  local old_text = old_mark and old_mark[4].virt_text[1][1] or nil

  vim.ui.input({ prompt = "Title: ", default = old_text }, function(input)
    local text = input and input or old_text
    local code = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    if text == "" then
      if old_mark then
        marx.remove_mark { id = old_mark[1], bufnr = bufnr }
        database.remove_mark(old_mark[1])
      end
    else
      if old_mark then
        database.upsert_mark {
          id = old_mark[1],
          file = vim.api.nvim_buf_get_name(bufnr),
          row = row,
          title = text,
          code = code,
        }
        marx.set_mark {
          id = old_mark[1],
          bufnr = bufnr,
          row = row,
          text = text,
        }
      else
        local id = database.upsert_mark {
          file = vim.api.nvim_buf_get_name(bufnr),
          row = row,
          title = text,
          code = code,
        }
        marx.set_mark {
          id = id,
          bufnr = bufnr,
          row = row,
          text = text,
        }
      end
    end
  end)
end

---@class marx.MotionOpts
---@field wrap boolean? Whether to wrap around when reaching the end of the file

---@param opts marx.MotionOpts?
function M.next_mark(opts)
  local wrap = opts and opts.wrap or false
  local current_row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local bufnr = vim.api.nvim_get_current_buf()

  local num_lines = vim.api.nvim_buf_line_count(bufnr)
  local marks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    marx.ns_id,
    { current_row + 1, 0 },
    { num_lines, 0 },
    { limit = 1 }
  )

  if #marks == 1 then
    local next_mark = marks[1]
    vim.api.nvim_win_set_cursor(0, { next_mark[2] + 1, 0 })
    return
  end

  if not wrap then
    return
  end

  marks = vim.api.nvim_buf_get_extmarks(bufnr, marx.ns_id, { 0, 0 }, { current_row, 0 }, { limit = 1 })

  if #marks == 1 then
    local next_mark = marks[1]
    vim.api.nvim_win_set_cursor(0, { next_mark[2] + 1, 0 })
  end
end

---@param opts marx.MotionOpts?
function M.prev_mark(opts)
  local wrap = opts and opts.wrap or false
  local current_row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local bufnr = vim.api.nvim_get_current_buf()

  local marks = vim.api.nvim_buf_get_extmarks(bufnr, marx.ns_id, { current_row - 1, 0 }, { 0, 0 }, { limit = 1 })

  if #marks == 1 then
    local prev_mark_row = marks[#marks][2]
    vim.api.nvim_win_set_cursor(0, { prev_mark_row + 1, 0 })
    return
  end

  if not wrap then
    return
  end

  local num_lines = vim.api.nvim_buf_line_count(bufnr)
  marks = vim.api.nvim_buf_get_extmarks(bufnr, marx.ns_id, { num_lines, 0 }, { current_row + 1, 0 }, { limit = 1 })

  if #marks == 1 then
    local prev_mark_row = marks[#marks][2]
    vim.api.nvim_win_set_cursor(0, { prev_mark_row + 1, 0 })
  end
end

function M.pick_mark()
  local marx_telescope = require "marx.telescope"
  local actions = require "telescope.actions"
  return marx_telescope.pick_mark(function(mark)
    actions.jump(mark.id)
  end)
end

return M
