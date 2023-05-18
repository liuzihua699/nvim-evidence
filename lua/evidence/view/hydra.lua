local tools = require("evidence.util.tools")
local Hydra = require("hydra")
local model = require("evidence.model.index")
local win_buf = require("evidence.view.win_buf")

local user_data = nil
local is_start_ = false

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
			{ "q", nil, { exit = true, nowait = true, desc = "exit" } },
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

local function setup()
	if is_start_ == true then
		return
	end
	is_start_ = true
	model:setup(user_data)
	win_buf:setup({})
end

local function start()
	setup()
	win_buf:openSplitWin()
	local item = model:get_min_due_item()
	if item == nil then
		print("empty table")
		return
	end
  win_buf:viewContent(item.content)
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
			{
				"x",
				start,
			},
			{ "q", nil, { exit = true, nowait = true, desc = "exit" } },
			{ "<Esc>", nil, { exit = true, nowait = true } },
		},
	})
end

return {
	setup = setup,
}
