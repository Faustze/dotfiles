-- Neovide-style cursor trail, drawn as plain text (half-block glyphs in
-- extmarks) rather than graphics, so it survives the whole stack here:
-- GNOME Terminal -> tmux -> nvim. Nothing in the chain has to understand
-- anything beyond ordinary characters.
--
-- The GPU-shader route (ghostty `custom-shader`, kitty `cursor_trail`) would
-- also cover the shell prompt, but VTE/GNOME Terminal has no shader pipeline
-- at all, so it isn't an option without switching terminals.
return {
  "sphamba/smear-cursor.nvim",
  event = "VeryLazy",
  opts = {
    -- Terminus (TTF) covers the half blocks at U+2580 but not the Legacy
    -- Computing quadrants at U+1FB00 (checked with `fc-list ':charset=1fb00'`
    -- - only Cascadia Code, Noto Sans Symbols2 and Unifont have them here).
    -- Leaving this false keeps the trail at half-cell granularity instead of
    -- rendering tofu boxes.
    legacy_computing_symbols_support = false,

    -- No trail while typing. Two reasons: insert mode already announces itself
    -- through the tinted block set up in config/options.lua, and the plugin's
    -- insert-mode default (`vertical_bar_cursor_insert_mode`) would draw a thin
    -- bar - exactly the shape that block replaced.
    smear_insert_mode = false,

    -- Without this the trail colour falls back to the `Cursor` highlight, which
    -- the `custom` colorscheme never defines, and then to Normal's foreground -
    -- i.e. a white smear. Use the same accent the insert-mode cursor is mixed
    -- from, so both cursor effects read as one idea.
    cursor_color = "#AA9AAC",

    -- Motion feel. Higher stiffness = snappier, higher damping = less overshoot.
    stiffness = 0.6,
    trailing_stiffness = 0.45,
    damping = 0.85,
    time_interval = 17, -- ms, ~60fps
  },
  config = function(_, opts)
    require("smear_cursor").setup(opts)

    -- On load the plugin appends `a:SmearCursorHideable` to guicursor so it can
    -- blank the real cursor mid-animation (color.lua:198-202). `a:` means every
    -- mode, and being last it outranks the `i-ci-ve:block-InsertCursor` entry
    -- from config/options.lua - which is why the tinted insert-mode block stops
    -- reaching the terminal once this plugin is enabled (no bg on the group ->
    -- nvim emits no OSC 12).
    --
    -- guicursor resolves last-match-wins, so re-append the insert entry after
    -- the plugin's. Normal/visual keep `a:SmearCursorHideable` and stay
    -- hideable, which is all the animation needs; insert is safe to reclaim
    -- because `smear_insert_mode = false` means nothing animates there anyway.
    --
    -- color.lua is only pulled in on the first animation, i.e. after this
    -- function has already run, so require it here to force its append to
    -- happen first. Plain concatenation rather than `vim.opt.guicursor:append`,
    -- which dedupes an entry that already exists and would silently no-op.
    require("smear_cursor.color")
    vim.o.guicursor = vim.o.guicursor .. ",i-ci-ve:block-InsertCursor"
  end,
}
