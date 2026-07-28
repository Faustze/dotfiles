-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Without this, conform's prettier formatter runs everywhere it can infer a
-- parser, using prettier's own defaults, regardless of whether the project
-- has a prettier config. That clashes with two real conventions across my
-- projects:
--   - antfu-style projects (todo-app, svrv_tech/front, SUMO-project/front)
--     have no .prettierrc and format via `eslint --fix` instead (VS Code has
--     "prettier.enable": false there) — 2-space indent, single quotes.
--   - staff_app-style projects ship a real .prettierrc — tabs, printWidth
--     150, no trailing commas.
-- Setting this to true makes conform's prettier formatter check
-- `prettier --find-config-path` first and silently skip if none is found, so
-- each project's own formatter/rules win instead of one hardcoded style.
vim.g.lazyvim_prettier_needs_config = true

-- Absolute line numbers (VS Code-style) instead of LazyVim's default relativenumber
vim.opt.relativenumber = false
