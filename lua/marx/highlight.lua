local M = {}

M.sign_hl = "MarxSignHL"
M.virt_text_hl = "MarxVirtualTextHL"
M.background_hl = "MarxBackgroundHL"

M.setup = function()
  vim.api.nvim_set_hl(0, M.sign_hl, { fg = "#4fd6be" })
  vim.api.nvim_set_hl(0, M.virt_text_hl, { fg = "#4fd6be" })
  vim.api.nvim_set_hl(0, M.background_hl, { bg = "#273849" })
end

return M
