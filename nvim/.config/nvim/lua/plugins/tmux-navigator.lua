return {
  "christoomey/vim-tmux-navigator",
  -- load eagerly: keymaps.lua wires <C-hjkl> to these commands on VeryLazy,
  -- so the commands need to already exist by then
  lazy = false,
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
  },
}
