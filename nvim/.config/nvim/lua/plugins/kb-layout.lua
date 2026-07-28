-- Lualine component showing the active keyboard layout (EN/RU).
--
-- The layout lives outside nvim, so it has to be polled from the OS, and the
-- way to ask differs per machine: under WSL the real keyboard belongs to
-- Windows, on the native Linux box it belongs to GNOME. Pick the backend once
-- at startup and no-op entirely when neither is available, so this file stays
-- safe to stow onto any machine.

local state = { text = "", busy = false }

local ps_script = [[Add-Type -Namespace Win32 -Name Kb -MemberDefinition '[DllImport("user32.dll")] public static extern System.IntPtr GetForegroundWindow(); [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(System.IntPtr hWnd, out uint procId); [DllImport("user32.dll")] public static extern System.IntPtr GetKeyboardLayout(uint idThread);'; $h=[Win32.Kb]::GetForegroundWindow(); $procId=0; $tid=[Win32.Kb]::GetWindowThreadProcessId($h,[ref]$procId); $layout=[Win32.Kb]::GetKeyboardLayout($tid); $lcid=[int]($layout.ToInt64() -band 0xFFFF); [System.Globalization.CultureInfo]::GetCultureInfo($lcid).TwoLetterISOLanguageName.ToUpper()]]

-- GNOME keeps the configured layouts in `sources` and the index of the active
-- one in `current`, so both are needed to resolve a name. Ask for them in a
-- single shell so one poll stays one process.
local gnome_script = table.concat({
  "gsettings get org.gnome.desktop.input-sources current",
  "gsettings get org.gnome.desktop.input-sources sources",
}, "; ")

--- Win32 already hands back a two-letter code; just normalise it.
local function parse_win32(out)
  return vim.trim(out)
end

--- `uint32 1` + `[('xkb', 'us'), ('xkb', 'ru')]` -> `RU`
local function parse_gnome(out)
  local lines = vim.split(vim.trim(out), "\n", { trimempty = true })
  if #lines < 2 then return "" end

  -- Anchor at the end: the value arrives as "uint32 0", and an unanchored
  -- %d+ would happily pick the 32 out of the type name.
  local idx = tonumber(lines[1]:match("(%d+)%s*$"))
  if not idx then return "" end

  local names = {}
  -- Each entry is ('<type>', '<layout>'); the layout is the second string.
  for _, name in lines[2]:gmatch("%('([^']*)',%s*'([^']*)'%)") do
    names[#names + 1] = name
  end

  -- `current` is 0-based, Lua tables are 1-based.
  local name = names[idx + 1]
  if not name then return "" end

  -- Layouts can carry a variant ("us+dvorak"); the language part is enough.
  return name:match("^(%a%a)") and name:sub(1, 2):upper() or ""
end

--- Returns the command to poll with and its output parser, or nil when this
--- machine has no way to answer.
local function detect_backend()
  if vim.fn.executable("powershell.exe") == 1 then
    return { "powershell.exe", "-NoProfile", "-Command", ps_script }, parse_win32
  end

  local desktop = (vim.env.XDG_CURRENT_DESKTOP or ""):upper()
  if vim.fn.executable("gsettings") == 1 and desktop:find("GNOME") then
    return { "sh", "-c", gnome_script }, parse_gnome
  end

  return nil
end

local function make_refresh(cmd, parse)
  return function()
    if state.busy then return end
    state.busy = true

    -- vim.system throws on a missing executable, and this runs from a timer,
    -- so let a failure clear the busy flag instead of wedging it forever.
    local ok = pcall(vim.system, cmd, { text = true }, function(res)
      state.busy = false
      if res.code ~= 0 or not res.stdout then return end

      local v = parse(res.stdout)
      if v == "" or v == state.text then return end

      vim.schedule(function()
        state.text = v
        pcall(function() require("lualine").refresh({ place = { "statusline" } }) end)
      end)
    end)

    if not ok then state.busy = false end
  end
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      local cmd, parse = detect_backend()
      if not cmd then return opts end

      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, function() return state.text end)

      local refresh = make_refresh(cmd, parse)
      refresh()
      local timer = vim.uv.new_timer()
      timer:start(1000, 1500, vim.schedule_wrap(refresh))

      return opts
    end,
  },
}
