local root = "/home/faust/SUMO-project"

local services = {
  {
    name = "SUMO: frontend",
    cwd = root .. "/front",
    cmd = { "pnpm", "run", "dev-wait" },
  },
  {
    name = "SUMO: spots_api",
    cwd = root .. "/spots_api",
    cmd = { root .. "/spots_api/.venv/bin/python", "-m", "uvicorn", "dev:app", "--reload" },
  },
  {
    name = "SUMO: qr_api",
    cwd = root .. "/qr_api",
    cmd = { root .. "/qr_api/.venv/bin/python", "-m", "uvicorn", "app.main:app", "--reload", "--port", "8001" },
  },
  {
    name = "SUMO: server_api",
    cwd = root .. "/server_api",
    cmd = { "dotnet", "run" },
  },
}

local service_names = {}
for _, svc in ipairs(services) do
  service_names[svc.name] = true
end

-- A task built from a template does NOT inherit the template's name: overseer
-- passes the builder's return value straight to Task.new(), and when that table
-- has no `name` the task is named after the joined command line. The template
-- name survives only in `task.from_template.name`. So a service started from
-- <leader>or ends up called "…/python -m uvicorn dev:app --reload" and a filter
-- keyed on the pretty name silently skips it. Every builder below sets `name`
-- explicitly, and this check still looks at both, so tasks started before this
-- change (or by anything else) are matched too.
local function is_service(task)
  if service_names[task.name] then
    return true
  end
  local from = task.from_template and task.from_template.name
  return from ~= nil and service_names[from] == true
end

-- The wrapper tasks below exist only to satisfy register_template's contract
-- (a builder must return a task spec). Without this they pile up in the task
-- list as finished `echo …` entries — the "empty" rows in <leader>oo.
--
-- The component list is spelled out instead of reusing the "default" alias on
-- purpose. That alias already carries
-- `{ "on_complete_dispose", require_view = { "SUCCESS", "FAILURE" } }`, which
-- keeps a finished task around until it has been *viewed*; adding a second
-- on_complete_dispose on top of the alias does not override it. Passing
-- `require_view = {}` here is what actually lets the wrapper disappear on its
-- own. on_complete_notify is dropped too — no popup for a throwaway echo.
local function wrapper_task(message)
  return {
    cmd = { "echo", message },
    components = {
      "on_exit_set_status",
      { "on_complete_dispose", timeout = 3, require_view = {} },
    },
  }
end

return {
  "stevearc/overseer.nvim",
  opts = {},
  keys = {
    { "<leader>oo", "<cmd>OverseerToggle<cr>", desc = "Overseer: панель задач" },
    { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Overseer: запустить задачу" },
  },
  config = function(_, opts)
    local overseer = require("overseer")
    overseer.setup(opts)

    for _, svc in ipairs(services) do
      overseer.register_template({
        name = svc.name,
        builder = function()
          return {
            name = svc.name,
            cmd = svc.cmd,
            cwd = svc.cwd,
            components = { "default" },
          }
        end,
      })
    end

    local function running_services()
      local running = {}
      for _, task in ipairs(overseer.list_tasks({})) do
        if is_service(task) and task:is_running() then
          running[task.name] = true
          local from = task.from_template and task.from_template.name
          if from then
            running[from] = true
          end
        end
      end
      return running
    end

    overseer.register_template({
      name = "SUMO: всё",
      builder = function()
        -- Skip what is already up, otherwise a second run starts a duplicate
        -- set of servers that then fight over the same ports.
        local running = running_services()
        local started = 0
        for _, svc in ipairs(services) do
          if not running[svc.name] then
            overseer
              .new_task({
                name = svc.name,
                cmd = svc.cmd,
                cwd = svc.cwd,
                components = { "default" },
              })
              :start()
            started = started + 1
          end
        end
        return wrapper_task(
          string.format(
            "SUMO: запущено %d сервисов (%d уже работали), смотри <leader>oo",
            started,
            #services - started
          )
        )
      end,
    })

    overseer.register_template({
      name = "SUMO: стоп всё",
      builder = function()
        local stopped = 0
        for _, task in ipairs(overseer.list_tasks({})) do
          if is_service(task) then
            -- stop() closes the pty, which SIGHUPs the whole session: every
            -- service is its own session leader and its children stay in that
            -- session, so the grandchildren (nuxt dev under pnpm, the built
            -- ServerApi under `dotnet run`, the uvicorn reload workers) go down
            -- with it. No process-tree walking needed.
            if task:is_running() then
              stopped = stopped + 1
            end
            task:stop()
            task:dispose(true)
          end
        end
        return wrapper_task(string.format("SUMO: остановлено сервисов: %d", stopped))
      end,
    })
  end,
}
