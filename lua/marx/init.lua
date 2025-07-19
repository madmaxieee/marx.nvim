local M = {}

local utils = require "marx.utils"
local highlight = require "marx.highlight"

function M.setup()
  highlight.setup()
  vim.keymap.set("n", "<leader>bm", function()
    M.set_bookmark()
  end)
end

function M.set_bookmark()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local bufnr = vim.api.nvim_get_current_buf()

  local old_mark = utils.get_mark(bufnr, row)
  local old_text = old_mark and old_mark[4].virt_text[1][1] or nil

  vim.ui.input({ prompt = "Bookmark text: ", default = old_text }, function(input)
    local text = input and input or old_text
    if text == "" then
      if old_mark then
        utils.remove_mark { id = old_mark[1], bufnr = bufnr }
      else
        utils.remove_mark {
          bufnr = bufnr,
          row = row,
        }
      end
    else
      if old_mark then
        utils.set_mark {
          id = old_mark[1],
          text = text,
          bufnr = bufnr,
          row = row,
        }
      else
        utils.set_mark {
          text = text,
          bufnr = bufnr,
          row = row,
        }
      end
    end
  end)
end

return M
