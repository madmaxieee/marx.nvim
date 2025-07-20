local M = {}

M.sign_hl = "MarxSignHL"
M.virt_text_hl = "MarxVirtualTextHL"
M.code_hl = "MarxCodeHL"

M.setup = function()
  vim.api.nvim_set_hl(0, M.sign_hl, { fg = "#ff8800" })
  vim.api.nvim_set_hl(0, M.virt_text_hl, { fg = "#ff8800" })
  vim.api.nvim_set_hl(0, M.code_hl, { bg = "#402200" })
end

return M
