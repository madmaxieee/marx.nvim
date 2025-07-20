local M = {}

local marks = require "marx.marks"
local highlight = require "marx.highlight"
local database = require "marx.database"

function M.setup()
  highlight.setup()
  database.setup { root_path = vim.fn.getcwd() }

  for _, mark in pairs(database.marks) do
    marks.set_mark {
      id = mark.id,
      text = mark.title,
      bufnr = vim.uri_to_bufnr(vim.uri_from_fname(mark.file)),
      row = mark.row,
    }
  end

  vim.keymap.set("n", "<leader>bm", function()
    M.set_bookmark()
  end)
end

function M.set_bookmark()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local bufnr = vim.api.nvim_get_current_buf()

  local old_mark = marks.get_mark(bufnr, row)
  local old_text = old_mark and old_mark[4].virt_text[1][1] or nil

  vim.ui.input({ prompt = "Title: ", default = old_text }, function(input)
    local text = input and input or old_text
    local code = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
    if text == "" then
      if old_mark then
        marks.remove_mark { id = old_mark[1], bufnr = bufnr }
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
        marks.set_mark {
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
        marks.set_mark {
          id = id,
          bufnr = bufnr,
          row = row,
          text = text,
        }
      end
    end
  end)
end

return M
