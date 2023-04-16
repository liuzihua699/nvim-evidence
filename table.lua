local sqlite = require("sqlite.db") --- for constructing sql databases
local tbl = require("sqlite.tbl") --- for constructing sql tables
local uri = "/home/oyjy/.config/nvim/sql/v2" -- defined here to be deleted later
local sm_algorithm = require("evidence.sm_algorithm")
local tools = require("utils.tools")
require("utils.dump")

local info_field = {
	id = true,
	table_id = { "text" },
	sm5_optimal_factor_matrix = { "text" },
}

local fields = {
	id = true, -- same as { type = "integer", required = true, primary = true }
	content = { "text", required = true },
	drill_schedule = { "number", default = tonumber(os.time()) },
	drill_lasttime = { "number", default = tonumber(os.time()) },
	drill_ef = { "number", default = 0 },
	drill_n = { "number", default = 0 }, -- new card mark
	drill_failures = { "number", default = 0 },
	drill_meanq = { "number", default = 0 },
	drill_total_repeats = { "number", default = 0 },
	drill_weight = { "number", default = 1 },
}

local table_list = {
	"sundry",
}
local drill_table_id = "sundry"

local drill_info_table = tbl("drill_info", info_field)

local drill_table = nil
local table_map = { ["drill_info"] = drill_info_table }

local function sql_init()
	for _k, item in pairs(table_list) do
		local tb = tbl(item, fields)
		table_map[item] = tb
	end

	drill_table = table_map[drill_table_id]

	local sql_map = { uri = uri }
	sqlite(tools.merge(sql_map, table_map))
end

local function setTable(id)
	drill_table_id = id
	drill_table = table_map[id]
end

local demo = {}

local function mock()
	for i = 1, 5 do
		table.insert(demo, { content = "* mock" .. i .. "\n asdfa d \n ** answer\n asldfjasdf " })
	end
end

local function mock(force)
	if not force and drill_table:count() ~= 0 then
		return
	end
	drill_table:drop()
	mock()
	for _, row in ipairs(demo) do
		drill_table:insert(row)
	end
end

local function add(content)
	drill_table:insert({ content = content })
end

local function edit_by_table(tb, id, row)
	return tb:update({
		where = { id = id },
		set = row,
	})
end

local function info_get_by_table_id()
	local item = drill_info_table:get({ where = { table_id = drill_table_id } })
	if item and item[1] then
		return item[1]
	else
		drill_info_table:insert({ sm5_optimal_factor_matrix = "", table_id = drill_table_id })
	end
	return nil
end

local function info_edit(row)
	local item = info_get_by_table_id()
	if item then
		edit_by_table(drill_info_table, item.id, row)
	end
end

local function edit(id, row)
	return edit_by_table(drill_table, id, row)
end

local function setContent(id, content)
	return edit(id, {
		content = content,
	})
end

local function update_of_matrix(value)
	info_edit({
		sm5_optimal_factor_matrix = DataDumper(value),
	})
end

local function get_of_matrix()
	local item = info_get_by_table_id()
	if item then
		local of_matrix = loadstring(item.sm5_optimal_factor_matrix)
		if of_matrix then
			of_matrix = of_matrix()
			return of_matrix
		end
	end
	return nil
end

local function format_date(date)
	return os.date("%Y-%m-%d %H:%M", tonumber(date))
end

local function setQuality(id, quality)
	if quality == nil or quality > 5 or quality < 0 then
		vim.notify("org quality number format error", "error")
		return false
	end
	local item = drill_table:get({ where = { id = id } })
	if #item ~= 1 then
		vim.notify("next id not found", "error")
	end
	item = item[1]
	-- local now_time=Date

	local now_time = tonumber(os.time())

	item.last_interval = (item.drill_schedule - item.drill_lasttime) / 24 / 60 / 60

	--print("<<<<<<<<<<<<<<<<<")
	--print("<<<<evidence input")
	--print("id: " .. vim.inspect(item.id))
	--print("quality: " .. vim.inspect(quality))
	--print("ef: " .. vim.inspect(item.drill_ef))
	--print("failures: " .. vim.inspect(item.drill_failures))
	--print("lasttime: " .. format_date(item.drill_lasttime))
	--print("meanq: " .. vim.inspect(item.drill_meanq))
	--print("schedule: " .. format_date(item.drill_schedule))
	--print("total_repeat: " .. vim.inspect(item.drill_total_repeats))
	--print("last_interval_days: " .. vim.inspect(item.last_interval))
	--print(">>>>evidence input")
	--print(">>>>>>>>>>>>>>>>")
	--print("<<<")
	print("evidence lasttime: " .. format_date(item.drill_lasttime))
	local new_item = sm_algorithm.start(item, quality, get_of_matrix())
	update_of_matrix(new_item.of_matrix)
	new_item.lasttime = now_time

	--print("<<<<<<<<<<<<<<<<<")
	--print("<<<<evidence output")
	--print("id: " .. vim.inspect(id))
	--print("ef: " .. vim.inspect(new_item.ef))
	--print("failures: " .. vim.inspect(new_item.failures))
	--print("lasttime: " .. format_date(new_item.lasttime))
	--print("meanq: " .. vim.inspect(new_item.meanq))
	--print("schedule: " .. format_date(new_item.schedule_time))
	--print("total_repeat: " .. vim.inspect(new_item.total_repeats))
	--print(">>>>evidence output")
	--print(">>>>>>>>>>>>>>>>")

	edit(id, {
		drill_schedule = new_item.schedule_time,
		drill_lasttime = new_item.lasttime,
		drill_ef = new_item.ef,
		drill_n = new_item.n,
		drill_failures = new_item.failures,
		drill_meanq = new_item.meanq,
		drill_total_repeats = new_item.total_repeats,
	})
	print("evidence schedule: " .. format_date(new_item.schedule_time))
	print(">>>")
end

local function parse_statement(item)
	assert(type(item) == "table")
	local statement = ""
	for key, val in pairs(item) do
		statement = statement .. key .. "=" .. val .. " "
	end
	return statement
end

local function empty_nil(item)
	local ret = item
	if item == nil or (type(item) == "table" and #item == 1 and next(item[1]) == nil) then
		ret = nil
	end
	--print(vim.inspect("==="))
	--print(vim.inspect(ret))
	--print(vim.inspect("==="))
	return ret
end

local function eval(query)
	--print(vim.inspect(query))
	local item = drill_table:eval(query)
	return empty_nil(item)
end

local function min(column, statement)
	local query = "SELECT *, MIN(" .. column .. ") AS `rowmin` FROM " .. drill_table_id
	if statement ~= nil then
		query = query .. " where " .. statement
	end
	local ret = eval(query)
	if ret ~= nil then
		return ret[1]
	else
		return nil
	end
end

local function find(limit_num, statement)
	local query = "SELECT * FROM " .. drill_table_id
	if statement ~= nil then
		query = query .. " where " .. statement
	end
	return eval(query .. " LIMIT " .. limit_num)
end

local function top(column, limit_num)
	return eval("SELECT * FROM " .. drill_table_id .. " ORDER BY " .. column .. " ASC LIMIT " .. limit_num)
end

local function random()
	return eval("SELECT * FROM " .. drill_table_id .. " ORDER BY RANDOM() LIMIT 1")
end

local function del(id)
	drill_table:remove({ id = id })
end

return {
	min = min,
	setQuality = setQuality,
	setContent = setContent,
	mock = mock,
	add = add,
	setTable = setTable,
	tables = table_list,
	init = sql_init,
	find = find,
	del = del,
	random = random,
}
