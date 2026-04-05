local M = {}

M.sign_hl = "MarxSignHL"
M.virt_text_hl = "MarxVirtualTextHL"
M.background_hl = "MarxBackgroundHL"

local function setup_hl_groups()
  if vim.o.background == "light" then
    vim.api.nvim_set_hl(0, M.sign_hl, { fg = "#179299" })
    vim.api.nvim_set_hl(0, M.virt_text_hl, { fg = "#179299" })
    vim.api.nvim_set_hl(0, M.background_hl, { bg = "#caf8fa" })
  else
    vim.api.nvim_set_hl(0, M.sign_hl, { fg = "#4fd6be" })
    vim.api.nvim_set_hl(0, M.virt_text_hl, { fg = "#4fd6be" })
    vim.api.nvim_set_hl(0, M.background_hl, { bg = "#273849" })
  end
end

M.setup = function()
  setup_hl_groups()
  vim.api.nvim_create_autocmd("ColorScheme", {
    desc = "update colors",
    callback = function()
      setup_hl_groups()
    end,
  })
end

return M
