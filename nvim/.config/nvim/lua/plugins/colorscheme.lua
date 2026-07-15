return {
  { "catppuccin/nvim", name = "catppuccin", lazy = true, opts = { flavour = "mocha" } },

  -- tell LazyVim to actually use it instead of the tokyonight default
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
}
