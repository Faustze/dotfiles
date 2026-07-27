-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Inside a terminal buffer, <C-h>/<C-l> switch buffers instead of windows,
-- i.e. the terminal-mode stand-in for LazyVim's <S-h>/<S-l> (which can't be
-- mapped in terminal mode without eating a capital H/L in the shell).
-- <C-j>/<C-k> keep their global meaning (window/tmux-pane up/down), so both
-- ways out of a terminal stay on one chord.
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("term_buffer_nav", { clear = true }),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set("t", "<c-h>", "<cmd>bprevious<cr>", vim.tbl_extend("error", opts, { desc = "Prev Buffer" }))
    vim.keymap.set("t", "<c-l>", "<cmd>bnext<cr>", vim.tbl_extend("error", opts, { desc = "Next Buffer" }))
  end,
})
