local tools = require("evidence.util.tools")
local Hydra = require("hydra")
local model = require("evidence.model.index")

local function hint_list(name, list)
  local res = [[
  # ]] .. name .. [[


  ]]
  for id = 1, #list do
    res = res .. [[_]] .. id .. [[_: ]] .. list[id] .. [[

  ]]
  end
  res = res .. [[

  _<Esc>_: exit  _q_: exit
  ]]
  return res
end

local function WrapHydra(name, hint, heads)
  return Hydra({
    name = name,
    hint = hint,
    config = {
      timeout = 30000,
      color = "teal",
      invoke_on_body = true,
      hint = {
        position = "middle",
        border = "rounded",
      },
    },
    heads = tools.table_concat(heads, {
      { "q",     nil, { exit = true, nowait = true, desc = "exit" } },
      { "<Esc>", nil, { exit = true, nowait = true } },
    }),
  })
end

local function WrapListHeads(list, func)
  local res = {}
  for i = 1, #list do
    local id = tostring(i)
    table.insert(res, {
      id,
      function()
        func(i)
      end,
    })
  end
  return res
end

local evidence_hint = [[
 _x_: start
 ^
     _<Esc>_: exit  _q_: exit
]]

local data = {
  uri = "/Users/junyiouyang/.local/share/nvim/lazy/nvim-evidence/sql/v2",
  all_table = {
    t1 = {},
    t2 = {
      request_retention = 0.7,
      maximum_interval = 100,
      easy_bonus = 1.0,
      hard_factor = 0.8,
      w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
    },
  },
  now_table_id = "t1",
}

local setup = function()
  Hydra({
    name = "Evidence",
    hint = evidence_hint,
    config = {
      timeout = 30000,
      color = "teal",
      invoke_on_body = true,
      hint = {
        position = "middle",
        border = "rounded",
      },
    },
    mode = "n",
    body = "<Leader>O",
    heads = {
      {
        "x",
        function()
          model:setup(data)
        end,
      },
      { "q",     nil, { exit = true, nowait = true, desc = "exit" } },
      { "<Esc>", nil, { exit = true, nowait = true } },
    },
  })
end

return {
  setup = setup,
}
