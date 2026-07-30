-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Colour for the insert-mode block cursor set up in options.lua.
--
-- Recomputed from whatever Normal currently is rather than hardcoded, so the
-- "translucency" still reads correctly after a :colorscheme change (the active
-- theme is `custom`, colors/custom.vim, but catppuccin/tokyonight are installed
-- and get tried now and then).
--
-- ALPHA is the knob: 0 makes the block vanish into the background, 1 makes it
-- solid ACCENT. Anything around 0.5 looks like frosted glass over the text.
local CURSOR_ACCENT = "#AA9AAC" -- same muted purple the theme uses for Function
local CURSOR_ALPHA = 0.55

local function hex(n)
  return string.format("#%06x", n)
end

local function mix(top, bottom, alpha)
  local function channel(color, shift)
    return bit.band(bit.rshift(color, shift), 0xff)
  end
  local out = 0
  for _, shift in ipairs({ 16, 8, 0 }) do
    local value = math.floor(channel(top, shift) * alpha + channel(bottom, shift) * (1 - alpha) + 0.5)
    out = out + bit.lshift(math.min(value, 0xff), shift)
  end
  return out
end

local function set_insert_cursor()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local bg = normal.bg or 0x000000
  local fg = normal.fg or 0xffffff
  local accent = tonumber(CURSOR_ACCENT:sub(2), 16)
  -- guifg = Normal's foreground, not Normal's background: the character under
  -- the cursor stays its usual colour, which is what sells the transparency.
  vim.api.nvim_set_hl(0, "InsertCursor", { bg = hex(mix(accent, bg, CURSOR_ALPHA)), fg = hex(fg) })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("insert_cursor_hl", { clear = true }),
  callback = set_insert_cursor,
})
set_insert_cursor()
