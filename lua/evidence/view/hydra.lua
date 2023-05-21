local tools = require("evidence.util.tools")
local Hydra = require("hydra")
local model = require("evidence.model.index")
local win_buf = require("evidence.view.win_buf")
local telescope = require("evidence.view.telescope")

local user_data = nil
local is_start_ = false
local now_item = nil

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
 _x_: start _s_: score 
 _f_: fuzzyFind _m_: minFind
 ^
     _<Esc>_: exit  _q_: exit
]]

local function setup()
  if is_start_ == true then
    return
  end
  is_start_ = true
  model:setup(user_data)
  win_buf:setup({})
end

local function next()
  local item = model:getMinDueItem(1)
  if item == nil then
    print("empty table")
    return
  end
  now_item = item[1]
  win_buf:viewContent(now_item.content)
end

local function start()
  setup()
  win_buf:openSplitWin()
  next()
end

local function checkScore(score)
  return score == 0 or score == 1 or score == 2 or score == 3
end

local function score()
  local rating = tonumber(tools.uiInput("score(0,1,2,3):", ""))
  if type(rating) ~= "number" or not checkScore(rating) then
    print("input format error (0,1,2,3)")
    return
  end
  print(rating)
  model:ratingCard(now_item.id, rating)
  next()
end

local function fuzzyFind()
  telescope.find(telescope.SearchMode.fuzzy)
end

local function minFind()
  telescope.find(telescope.SearchMode.min_due)
end

---@param data ModelTableInfo
local setup = function(data)
  user_data = data
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
      { "x",     start },
      { "s",     score },
      { "f",     fuzzyFind },
      { "m",     minFind },
      { "q",     nil,  { exit = true, nowait = true, desc = "exit" } },
      { "<Esc>", nil,  { exit = true, nowait = true } },
    },
  })
end

return {
  setup = setup,
}
