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

-- Русский текст в заметках/коммитах не должен весь подсвечиваться как
-- опечатки: LazyVim включает spell для markdown/gitcommit по умолчанию
-- (lazyvim_wrap_spell), но словарь по умолчанию только английский.
vim.opt.spelllang = { "ru", "en" }

-- Insert mode gets the same solid block as normal/visual instead of nvim's
-- default thin bar (`i-ci-ve:ver25`). To keep the modes distinguishable once
-- the shapes match, insert paints its block through a dedicated highlight
-- group, InsertCursor, defined in autocmds.lua.
--
-- A terminal cursor cannot actually be translucent: DECSCUSR carries a shape,
-- OSC 12 carries one opaque colour, and neither VTE/GNOME Terminal nor any
-- other emulator exposes an alpha channel for it. InsertCursor fakes it the
-- only way that works - the block is mixed towards the editor background and
-- the character underneath keeps the normal foreground instead of being
-- inverted, which reads as a translucent slab rather than a solid one.
vim.opt.guicursor = table.concat({
  "n-v-c-sm:block",
  "i-ci-ve:block-InsertCursor",
  "r-cr-o:hor20",
  "t:block-blinkon500-blinkoff500-TermCursor",
}, ",")
