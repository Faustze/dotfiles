-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Re-point LazyVim's default <C-hjkl> window-nav keys at vim-tmux-navigator
-- so they also hop out into tmux panes at the edge of the nvim split layout.
-- Set here (loaded on VeryLazy, after everything else) so this wins over
-- LazyVim's own plain <C-w>h-style defaults.
-- The same <C-hjkl> work straight from terminal mode too, so leaving a
-- terminal buffer no longer needs the <C-\><C-n> dance first.
local tmux_nav = { h = "Left", j = "Down", k = "Up", l = "Right" }
for key, dir in pairs(tmux_nav) do
  vim.keymap.set(
    { "n", "t" },
    "<c-" .. key .. ">",
    "<cmd>TmuxNavigate" .. dir .. "<cr>",
    { desc = "Go to window/pane " .. dir:lower() }
  )
end

-- Exit terminal mode in place, without the <C-\><C-n> chord.
vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Exit terminal mode" })

-- Alt+` cycles, as a one-handed alternative to the directional keys above.
-- Those all stay bound; this is additive.
--
-- What it cycles depends on where you are, which is the whole point: in a
-- terminal buffer you're almost always trying to get *out* to another window,
-- in normal mode you're flipping between files.
--
-- Shift+` is `~`, so the backwards key is <M-~> — there is no <M-S-`> to
-- write, the terminal simply sends the shifted character.
vim.keymap.set("t", "<M-`>", "<cmd>wincmd w<cr>", { desc = "Cycle to next window" })
vim.keymap.set("t", "<M-~>", "<cmd>wincmd W<cr>", { desc = "Cycle to previous window" })
vim.keymap.set("n", "<M-`>", "<cmd>bnext<cr>", { desc = "Cycle to next buffer" })
vim.keymap.set("n", "<M-~>", "<cmd>bprevious<cr>", { desc = "Cycle to previous buffer" })
