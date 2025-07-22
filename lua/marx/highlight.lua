local M = {}

M.sign_hl = "MarxSignHL"
M.virt_text_hl = "MarxVirtualTextHL"
M.code_hl = "MarxCodeHL"

M.setup = function()
  vim.api.nvim_set_hl(0, M.sign_hl, { fg = "#65bcff" })
  vim.api.nvim_set_hl(0, M.virt_text_hl, { fg = "#65bcff" })
  vim.api.nvim_set_hl(0, M.code_hl, { bg = "#394b70" })
end

return M
