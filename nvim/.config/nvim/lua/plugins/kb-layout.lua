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

-- X11 --------------------------------------------------------------------
--
-- Asking GNOME is only correct when GNOME is the thing doing the switching.
-- Here it isn't: ~/.profile runs `setxkbmap -layout us,ru -option
-- grp:ctrl_shift_toggle`, so Ctrl+Shift flips the XKB group inside the X
-- server and gnome-settings-daemon never finds out - its
-- org.gnome.desktop.input-sources `current` reads 0 forever while the real
-- group is 1. Hence a backend that asks X itself, tried before GNOME.
--
-- LuaJIT FFI rather than a helper process: neither xkb-switch nor
-- xkblayout-state is packaged for Ubuntu, and this turns a poll into a plain
-- function call instead of spawning something every 1.5 seconds.

local x11 = { lib = nil, display = nil, layouts = {} }

local function x11_setup()
  if vim.env.DISPLAY == nil or vim.env.DISPLAY == "" then return false end

  local ok, ffi = pcall(require, "ffi")
  if not ok then return false end

  -- Redefining a type throws, and this file can be re-sourced by :Lazy reload.
  pcall(
    ffi.cdef,
    [[
      typedef struct {
        unsigned char group, locked_group;
        unsigned short base_group, latched_group;
        unsigned char mods, base_mods, latched_mods, locked_mods, compat_state,
                      grab_mods, compat_grab_mods, lookup_mods, compat_lookup_mods;
        unsigned short ptr_buttons;
      } XkbStateRec;
      void *XOpenDisplay(const char *);
      int XkbQueryExtension(void *, int *, int *, int *, int *, int *);
      int XkbGetState(void *, unsigned int, XkbStateRec *);
    ]]
  )

  local loaded, lib = pcall(ffi.load, "X11")
  if not loaded then return false end

  local display = lib.XOpenDisplay(nil)
  if display == nil then return false end

  -- XkbGetState returns stale data unless the extension is initialised first.
  local scratch = ffi.new("int[1]")
  if lib.XkbQueryExtension(display, scratch, scratch, scratch, scratch, scratch) == 0 then return false end

  -- XKB reports the group as an index; the names live in the keymap. Read the
  -- list once here instead of per poll - it only changes if something re-runs
  -- setxkbmap, which happens at login, not while nvim is up. Note the list can
  -- hold duplicates ("us,ru,us" on this box, GNOME and .profile having both had
  -- a go at it), so index order matters and the names cannot be deduplicated.
  local query = vim.fn.systemlist({ "setxkbmap", "-query" })
  if vim.v.shell_error ~= 0 then return false end
  for _, line in ipairs(query) do
    local list = line:match("^layout:%s*(.+)$")
    if list then
      for name in vim.gsplit(vim.trim(list), ",", { trimempty = true }) do
        x11.layouts[#x11.layouts + 1] = vim.trim(name)
      end
    end
  end
  if #x11.layouts == 0 then return false end

  x11.lib, x11.display = lib, display
  x11.state = ffi.new("XkbStateRec")
  return true
end

--- Reads the live XKB group and maps it onto the layout list. Synchronous, but
--- it is one X round trip, not a process spawn.
local function x11_poll()
  x11.lib.XkbGetState(x11.display, 0x0100, x11.state) -- 0x0100 = XkbUseCoreKbd
  local name = x11.layouts[tonumber(x11.state.group) + 1]
  if not name then return "" end
  return name:match("^(%a%a)") and name:sub(1, 2):upper() or ""
end

--- Returns either { poll = fn } for an in-process backend, or
--- { cmd = {...}, parse = fn } for one that shells out. nil when this machine
--- has no way to answer, so the file stays safe to stow anywhere.
local function detect_backend()
  if vim.fn.executable("powershell.exe") == 1 then
    return { cmd = { "powershell.exe", "-NoProfile", "-Command", ps_script }, parse = parse_win32 }
  end

  -- Before GNOME on purpose: on a GNOME session that still switches layouts
  -- through raw XKB, GNOME would answer confidently and wrongly.
  if x11_setup() then
    return { poll = x11_poll }
  end

  local desktop = (vim.env.XDG_CURRENT_DESKTOP or ""):upper()
  if vim.fn.executable("gsettings") == 1 and desktop:find("GNOME") then
    return { cmd = { "sh", "-c", gnome_script }, parse = parse_gnome }
  end

  return nil
end

--- Commits a freshly read value, redrawing only when it actually changed.
local function publish(v)
  if v == "" or v == state.text then return end
  state.text = v
  pcall(function() require("lualine").refresh({ place = { "statusline" } }) end)
end

local function make_refresh(backend)
  -- In-process backend: no subprocess, so no busy flag and no scheduling.
  if backend.poll then
    return function()
      local ok, v = pcall(backend.poll)
      if ok then publish(v) end
    end
  end

  return function()
    if state.busy then return end
    state.busy = true

    -- vim.system throws on a missing executable, and this runs from a timer,
    -- so let a failure clear the busy flag instead of wedging it forever.
    local ok = pcall(vim.system, backend.cmd, { text = true }, function(res)
      state.busy = false
      if res.code ~= 0 or not res.stdout then return end
      local v = backend.parse(res.stdout)
      vim.schedule(function() publish(v) end)
    end)

    if not ok then state.busy = false end
  end
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      local backend = detect_backend()
      if not backend then return opts end

      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, function() return state.text end)

      local refresh = make_refresh(backend)
      refresh()
      local timer = vim.uv.new_timer()
      timer:start(1000, 1500, vim.schedule_wrap(refresh))

      return opts
    end,
  },
}
