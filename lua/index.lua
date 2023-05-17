local hydra = require("lua.view.hydra")

local command_list = {
  setup = hydra.setup,
}

local function complete_key()
  local keys = {}
  for key, _ in pairs(command_list) do
    table.insert(keys, key)
  end
  return keys
end

local function work(arg)
  local command = command_list[arg]
  if command == nil then
    print("not match command for spectre")
    return
  end
  command()
end

return {
  setup = function()
    vim.api.nvim_create_user_command("Evidence", function(tb1)
      work(tb1.args)
    end, {
      nargs = 1,
      complete = function(ArgLead, CmdLine, CursorPos)
        return complete_key()
      end,
    })
  end,
}
