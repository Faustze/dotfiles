return {
  { "catppuccin/nvim", name = "catppuccin", lazy = true, opts = { flavour = "mocha" } },

  -- "custom" lives in colors/custom.vim (plain vimscript colorscheme, no plugin needed)
  { "LazyVim/LazyVim", opts = { colorscheme = "custom" } },
}
