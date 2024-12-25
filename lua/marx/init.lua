local M = {}

local utils = require "marx.utils"

M.setup = function()
  vim.keymap.set("n", "<leader>bm", function()
    M.toggle_bookmark()
  end)
end

M.add_bookmark = function()
  local line_num = vim.fn.line "."
  local bufnr = vim.fn.bufnr "%"
  utils.add_sign {
    bufnr = bufnr,
    lnum = line_num,
    text = "",
    priority = 10,
  }
end

M.remove_bookmark = function()
  local line_num = vim.fn.line "."
  local bufnr = vim.fn.bufnr "%"
  utils.remove_sign {
    bufnr = bufnr,
    lnum = line_num,
  }
end

M.toggle_bookmark = function()
  local line_num = vim.fn.line "."
  local bufnr = vim.fn.bufnr "%"
  if utils.get_sign_id(bufnr, line_num) then
    utils.remove_sign {
      bufnr = bufnr,
      lnum = line_num,
    }
  else
    utils.add_sign {
      bufnr = bufnr,
      lnum = line_num,
      text = "",
      priority = 10,
    }
  end
end

return M
