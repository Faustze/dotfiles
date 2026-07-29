-- Make nvim's own state survive a reboot, so a restored tmux pane comes back
-- with its buffers rather than an empty editor.
--
-- tmux-resurrect already relaunches nvim in the right directory (it is on
-- resurrect's default process list), but nvim then starts blank. The
-- `@resurrect-strategy-nvim 'session'` setting only helps when a Session.vim
-- sits in that directory, and nothing here ever writes one - it is a
-- `:mksession` you have to remember to run.
--
-- persistence already keeps one session per cwd; that is what <leader>qs
-- loads. Two gaps stop it from covering a reboot on its own:
--
--   1. it only saves on VimLeavePre, and a reboot does not give nvim a clean
--      exit - which is precisely the case this is supposed to survive;
--   2. nothing loads it automatically, so a restored pane shows an empty nvim
--      until you press <leader>qs in every one of them.
--
-- LazyVim's spec (event = "BufReadPre", the <leader>q* keys) is inherited; only
-- these two behaviours are added.

-- How much work a crash may cost. `:mksession` is a small local write, so this
-- can be short without being felt.
local SAVE_INTERVAL_MS = 60 * 1000

--- Sessions saved from a dashboard or a lone scratch buffer are worse than no
--- session at all - they would replace a real one for that cwd on the next
--- periodic tick. Mirrors what persistence itself checks on VimLeavePre.
local function has_real_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buftype == ""
      and vim.api.nvim_buf_get_name(buf) ~= ""
    then
      return true
    end
  end
  return false
end

return {
  "folke/persistence.nvim",
  opts = {},

  -- `init` rather than `config`: this has to be registered before VimEnter,
  -- and the plugin itself is lazy (BufReadPre), which never fires when nvim
  -- opens no file at all - exactly the case a restored pane hits.
  init = function()
    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("persistence_autoload", { clear = true }),
      -- Sourcing a session fires autocmds of its own; without nested they are
      -- skipped and filetype/LSP never attach to the restored buffers.
      nested = true,
      callback = function()
        -- `nvim file.ts` means "open this file", not "restore everything".
        if vim.fn.argc(-1) > 0 then return end
        -- Piped input (`git diff | nvim -`) also arrives with no arguments.
        if vim.g.persistence_autoload == false then return end

        -- Requiring it here is what pulls the lazy plugin in, which runs
        -- config() below and gives Config.options its values.
        local persistence = require("persistence")

        -- load() silently does nothing when the file is missing; check first so
        -- a cwd with no session leaves the dashboard alone instead of blinking.
        local file = persistence.current()
        if vim.fn.filereadable(file) == 0 then
          file = persistence.current({ branch = false })
        end
        if vim.fn.filereadable(file) == 0 then return end

        persistence.load()
      end,
    })
  end,

  config = function(_, opts)
    local persistence = require("persistence")
    persistence.setup(opts)

    -- persistence.stop() (<leader>qd, "don't save this session") flips
    -- active(), so the timer has to respect it or it would keep writing.
    local timer = vim.uv.new_timer()
    timer:start(
      SAVE_INTERVAL_MS,
      SAVE_INTERVAL_MS,
      vim.schedule_wrap(function()
        if persistence.active() and has_real_buffers() then
          -- :mksession throws on some transient buffer states (terminals
          -- mid-exit, for one), and this runs from a timer where an error
          -- would surface as a stray notification every minute.
          pcall(persistence.save)
        end
      end)
    )
  end,
}
