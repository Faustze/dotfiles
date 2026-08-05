-- Format on save through the project's own `eslint.config.*`
-- (@antfu/eslint-config), i.e. the nvim port of the .vscode/settings.json that
-- those projects ship:
--
--   "prettier.enable": false,
--   "editor.formatOnSave": true,
--   "editor.codeActionsOnSave": { "source.fixAll.eslint": "explicit" },
--   "eslint.rules.customizations": [...],
--   "eslint.validate": [...]
--
-- The prettier half is already handled by `lazyvim_prettier_needs_config = true`
-- in options.lua (conform skips prettier when the project has no prettier
-- config). This file covers the eslint half.
--
-- Only applies where the eslint LSP attaches at all, and it attaches only when
-- there is an eslint config in the file's directory tree (see the `root_dir` in
-- nvim-lspconfig's lsp/eslint.lua), so nothing here leaks into projects that
-- don't use eslint.

-- Ported from "eslint.rules.customizations": keep the stylistic rules silent in
-- the editor (they are noise — every one of them is fixed automatically on
-- save) while real problems still show up as diagnostics.
local rules_customizations = {
  { rule = "style/*", severity = "off", fixable = true },
  { rule = "format/*", severity = "off", fixable = true },
  { rule = "*-indent", severity = "off", fixable = true },
  { rule = "*-spacing", severity = "off", fixable = true },
  { rule = "*-spaces", severity = "off", fixable = true },
  { rule = "*-order", severity = "off", fixable = true },
  { rule = "*-dangle", severity = "off", fixable = true },
  { rule = "*-newline", severity = "off", fixable = true },
  { rule = "*quotes", severity = "off", fixable = true },
  { rule = "*semi", severity = "off", fixable = true },
  -- Kept for parity with the VS Code file, but note it is a no-op there too:
  -- the server only applies a customization when `fixable` is nil or equals the
  -- rule's actual fixability, and vue/block-order *is* auto-fixable, so this
  -- entry never matches and the `*-order` line above keeps winning.
  { rule = "vue/block-order", fixable = false },
}

-- Ported from "eslint.validate". nvim-lspconfig's default filetype list is only
-- js/ts/jsx/tsx/vue/svelte/astro/htmlangular; antfu's config also lints json,
-- yaml, markdown, css/scss and graphql, so the eslint LSP has to be attached
-- there for `eslint --fix` on save to reach those files.
local eslint_filetypes = {
  -- lspconfig defaults
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "vue",
  "svelte",
  "astro",
  "htmlangular",
  -- added for eslint.validate parity
  "css",
  "graphql",
  "html",
  "json",
  "jsonc",
  "json5",
  "less",
  "markdown",
  "postcss",
  "scss",
  "toml",
  "xml",
  "yaml",
}

return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- 1. Let eslint own formatting for the filetypes it handles.
      --
      -- Without this, LazyVim's generic "LSP" formatter is the active primary
      -- formatter for TS/Vue buffers in an antfu project (conform is skipped
      -- because there is no prettier config) and vtsls/vue_ls reformat the file
      -- with the TypeScript language service's own style before eslint gets to
      -- fix it — two passes fighting over quotes, semicolons and indent.
      -- VS Code never did this: there, no formatter was enabled at all and only
      -- `source.fixAll.eslint` ran.
      --
      -- Safe to do unconditionally: in projects that *do* ship a prettier
      -- config, conform (priority 100) outranks the "LSP" formatter
      -- (priority 1) and marks itself primary, so vtsls/vue_ls formatting was
      -- already never reached there.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("eslint_owns_formatting", { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and (client.name == "vtsls" or client.name == "vue_ls") then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end,
      })

      -- 2. eslint server settings.
      opts.servers = opts.servers or {}
      opts.servers.eslint = vim.tbl_deep_extend("force", opts.servers.eslint or {}, {
        settings = {
          rulesCustomizations = rules_customizations,
          -- Required: the server returns an empty edit list for
          -- textDocument/formatting unless this is on, so it gates the handler
          -- and not just the capability advertisement.
          format = true,
        },
      })
      opts.servers.eslint.filetypes = eslint_filetypes

      -- 3. Replace the formatter registered by
      -- lazyvim.plugins.extras.linting.eslint with one that actually fires on
      -- save. Two things had to change:
      --
      -- `sources` keys off the attached client by name instead of
      -- `supports_method("textDocument/formatting")`. The eslint server only
      -- announces that capability through a *dynamic* registration that can
      -- land after the buffer is opened, so LazyVim's version reports no
      -- sources and a save right after opening a file silently skips
      -- formatting.
      --
      -- `format` sends textDocument/formatting itself instead of going through
      -- `vim.lsp.buf.format`, which would skip eslint whenever the dynamic
      -- registration above hasn't landed yet. The edits arrive in the
      -- *response* and are applied inline, which is the part that matters: the
      -- more obvious `eslint.applyAllFixes` command (the literal equivalent of
      -- "source.fixAll.eslint") pushes its result back as a separate
      -- workspace/applyEdit request, and nvim defers handling that until the
      -- current autocmd returns — i.e. until after the file has been written.
      -- The fix lands in the buffer but never makes it into the saved file.
      opts.setup = opts.setup or {}
      opts.setup.eslint = function()
        LazyVim.format.register({
          name = "eslint: fix all",
          -- Primary at a higher priority than conform (100) and the generic
          -- "LSP" formatter (1), so exactly one formatting pass runs. Without
          -- this, eslint would format twice per save: once here and once via
          -- the generic "LSP" formatter, which picks up every client
          -- advertising textDocument/formatting.
          primary = true,
          priority = 200,
          sources = function(buf)
            if #vim.lsp.get_clients({ bufnr = buf, name = "eslint" }) == 0 then
              return {}
            end
            -- Stand down in projects that ship a real formatter config, so
            -- conform stays the primary one there. Mirrors the split already
            -- described in options.lua: prettier where there is a prettier
            -- config, eslint --fix in the antfu-style projects that have none.
            local ok, conform = pcall(require, "conform")
            if ok and #conform.list_formatters(buf) > 0 then
              return {}
            end
            return { "eslint" }
          end,
          format = function(buf)
            for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, name = "eslint" })) do
              local res = client:request_sync("textDocument/formatting", {
                textDocument = vim.lsp.util.make_text_document_params(buf),
                options = {
                  tabSize = vim.bo[buf].shiftwidth,
                  insertSpaces = vim.bo[buf].expandtab,
                },
              }, 5000, buf)
              if res and res.result then
                vim.lsp.util.apply_text_edits(res.result, buf, client.offset_encoding)
              end
            end
          end,
        })
      end
    end,
  },
}
