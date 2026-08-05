-- Auto-save the buffer on idle, without fighting LazyVim's built-in
-- `:w` / buffer-listing behaviour.
return {
  {
    "okuuva/auto-save.nvim",
    event = { "InsertLeave", "TextChanged" },
    opts = {
      -- Debounce so the eslint `textDocument/formatting` pass on save
      -- (plugins/eslint.lua) isn't triggered on every keystroke.
      debounce_delay = 1000,
      execution_message = { message = "" },
      condition = function(buf)
        -- Skip buffers that must stay unsaved: no filename, or a non-file
        -- buffertype (scratch, quickfix, terminals...).
        if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then
          return false
        end
        -- Don't auto-save plugin/help/lsp buffers or special files.
        if vim.fn.index({ "help", "quickfix", "nofile" }, vim.bo[buf].buftype) ~= -1 then
          return false
        end
        return true
      end,
    },
  },
}
