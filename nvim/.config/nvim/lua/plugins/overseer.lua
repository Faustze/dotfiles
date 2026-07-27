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
            cmd = svc.cmd,
            cwd = svc.cwd,
            components = { "default" },
          }
        end,
      })
    end

    overseer.register_template({
      name = "SUMO: всё",
      builder = function()
        for _, svc in ipairs(services) do
          overseer.new_task({
            name = svc.name,
            cmd = svc.cmd,
            cwd = svc.cwd,
            components = { "default" },
          }):start()
        end
        return {
          cmd = { "echo", "SUMO: все сервисы запущены, смотри <leader>oo" },
          components = { "default" },
        }
      end,
    })

    local service_names = {}
    for _, svc in ipairs(services) do
      service_names[svc.name] = true
    end

    overseer.register_template({
      name = "SUMO: стоп всё",
      builder = function()
        for _, task in ipairs(overseer.list_tasks({})) do
          if service_names[task.name] then
            task:stop()
            task:dispose(true)
          end
        end
        return {
          cmd = { "echo", "SUMO: все сервисы остановлены" },
          components = { "default" },
        }
      end,
    })
  end,
}
