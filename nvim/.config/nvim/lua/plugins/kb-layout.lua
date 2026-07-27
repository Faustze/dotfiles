local state = { text = "", busy = false }

local ps_script = [[Add-Type -Namespace Win32 -Name Kb -MemberDefinition '[DllImport("user32.dll")] public static extern System.IntPtr GetForegroundWindow(); [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(System.IntPtr hWnd, out uint procId); [DllImport("user32.dll")] public static extern System.IntPtr GetKeyboardLayout(uint idThread);'; $h=[Win32.Kb]::GetForegroundWindow(); $procId=0; $tid=[Win32.Kb]::GetWindowThreadProcessId($h,[ref]$procId); $layout=[Win32.Kb]::GetKeyboardLayout($tid); $lcid=[int]($layout.ToInt64() -band 0xFFFF); [System.Globalization.CultureInfo]::GetCultureInfo($lcid).TwoLetterISOLanguageName.ToUpper()]]

local function refresh()
  if state.busy then return end
  state.busy = true
  vim.system({ "powershell.exe", "-NoProfile", "-Command", ps_script }, { text = true }, function(res)
    state.busy = false
    if res.code == 0 and res.stdout then
      local v = vim.trim(res.stdout)
      if v ~= "" and v ~= state.text then
        vim.schedule(function()
          state.text = v
          pcall(function() require("lualine").refresh({ place = { "statusline" } }) end)
        end)
      end
    end
  end)
end

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, function() return state.text end)

      refresh()
      local timer = vim.uv.new_timer()
      timer:start(1000, 1500, vim.schedule_wrap(refresh))

      return opts
    end,
  },
}
