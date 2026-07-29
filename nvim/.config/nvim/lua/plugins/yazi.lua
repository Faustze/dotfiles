-- yazi is the only file navigator here.
--
-- It used to fight snacks.explorer, which LazyVim turns on by default: both
-- claim directory buffers (`snacks.explorer.replace_netrw` on one side,
-- `open_for_directories` on the other), so `nvim .` opened the sidebar and
-- yazi at the same time, and <leader>e still went to the sidebar while
-- <leader>- went to yazi. Two navigators, two sets of muscle memory, one of
-- them unwanted - so the explorer is switched off rather than kept as a
-- fallback.
--
-- This file lived as a real (unstowed) file in ~/.config/nvim for a while,
-- outside this repo and outside git. It is tracked here now.

return {
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = { "folke/snacks.nvim" },
    keys = {
      -- <leader>e / <leader>E keep the meaning LazyVim gives them ("open the
      -- file explorer, rooted at the project / at cwd"), just pointed at yazi.
      -- Cheaper than retraining the habit, and every LazyVim doc still reads
      -- correctly.
      { "<leader>e", "<cmd>Yazi<cr>", desc = "Yazi at current file" },
      { "<leader>E", "<cmd>Yazi cwd<cr>", desc = "Yazi in nvim's cwd" },
      { "<leader>-", "<cmd>Yazi<cr>", desc = "Yazi at current file" },
      { "<leader>cw", "<cmd>Yazi cwd<cr>", desc = "Yazi in nvim's cwd" },
      { "<c-up>", "<cmd>Yazi toggle<cr>", desc = "Resume last yazi session" },
    },
    opts = {
      -- `nvim .` or `nvim some/dir` opens yazi instead of netrw. Only
      -- unambiguous now that snacks.explorer has stopped claiming the same
      -- buffers below.
      open_for_directories = true,
      keymaps = {
        show_help = "<f1>",
      },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      explorer = {
        enabled = false,
        -- Explicit even though `enabled = false` already prevents setup:
        -- this is the flag that actually hijacked directory buffers, and
        -- leaving it stated documents what the conflict was.
        replace_netrw = false,
      },
    },
    -- Drop the explorer keys LazyVim adds, so nothing routes back to the
    -- sidebar. <leader>e and <leader>E are re-bound to yazi above; the
    -- <leader>f* pair just goes away.
    keys = {
      { "<leader>e", false },
      { "<leader>E", false },
      { "<leader>fe", false },
      { "<leader>fE", false },
    },
  },
}
