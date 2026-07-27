local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- Vue support (vue_ls + vtsls). This extra pulls in
    -- lazyvim.plugins.extras.lang.typescript itself, so TS/TSX files
    -- and the vtsls LSP work without importing that extra separately.
    { import = "lazyvim.plugins.extras.lang.vue" },
    { import = "lazyvim.plugins.extras.lang.tailwind" },
    { import = "lazyvim.plugins.extras.lang.json" },

    -- C#/.NET support (omnisharp LSP + csharpier formatter)
    { import = "lazyvim.plugins.extras.lang.dotnet" },

    -- eslint LSP registers a *secondary* formatter that runs `eslint --fix`
    -- on save whenever the eslint LSP is attached to the buffer (i.e. the
    -- project has an eslint config at all). Combined with
    -- `lazyvim_prettier_needs_config = true` in options.lua, this means:
    --   - projects with a real .prettierrc (e.g. staff_app) format with prettier
    --   - antfu-style projects with no .prettierrc (todo-app, svrv_tech,
    --     SUMO-project) format via eslint fix instead, matching how VS Code
    --     was already configured for them (prettier.enable: false there).
    { import = "lazyvim.plugins.extras.linting.eslint" },
    { import = "lazyvim.plugins.extras.formatting.prettier" },

    -- fuzzy finder
    { import = "lazyvim.plugins.extras.editor.telescope" },

    -- completion + snippets
    { import = "lazyvim.plugins.extras.coding.blink" },
    { import = "lazyvim.plugins.extras.coding.luasnip" },

    -- import/override with your own plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "catppuccin", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
})
