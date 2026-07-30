return {
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      workspaces = {
        {
          name = "notes",
          path = "/home/faust/OBSIDIAN/Obsidian-Notes",
        },
      },
      completion = {
        nvim_cmp = false,
        blink = true,
      },
    },
  },
}
