local instance = nil

---@class Evidence
local Evidence = {}

function Evidence:new()
	local data = { initialized = false }
	setmetatable(data, self)
	self.__index = self
	return data
end

function Evidence:init()
	if self.initialized then
		return
	end
	self.drill_id = nil
	self.is_start = false
	self.ratio_min = 50
	self.ratio_new = 90
	self.ratio_rand = 100
	self.initialized = true
	self.tools = require("utils.tools")
	self.win_buf = require("evidence.win_buf")
	self.org_sql = require("evidence.table")
end

local function get_instance()
	if not instance then
		instance = Evidence:new()
		Evidence:init()
	end
	return instance
end

local function get_info()
	local this = get_instance()
	return {
		win = this.win,
		buf = this.buf,
	}
end

local function add()
	local this = get_instance()
	local content = vim.api.nvim_buf_get_lines(this.win_buf.get_info().buf, 0, -1, false)
	local content_str = table.concat(content, "\n")
	this.org_sql.add(content_str)
	vim.notify("add ok", "success", {
		timeout = 1000 * 5,
		title = "org evidence",
	})
end

local function edit()
	local this = get_instance()
	local content = vim.api.nvim_buf_get_lines(this.win_buf.get_info().buf, 0, -1, false)
	local content_str = table.concat(content, "\n")
	this.org_sql.setContent(this.drill_id, content_str)
	vim.notify("edit ok", "success", {
		timeout = 1000 * 5,
		title = "org evidence",
	})
end

local function get_min()
	local this = get_instance()
	local item = this.org_sql.min("drill_schedule", "drill_total_repeats!=0")
	if type(item) ~= "table" then
		item = nil
	else
		vim.notify("min", "success", {
			timeout = 1000 * 5,
			title = "org evidence",
		})
	end
	return item
end

local function get_rand()
	local this = get_instance()
	local item = nil
	local items = this.org_sql.random()
	if type(items) == "table" then
		item = items[1]
	else
		vim.notify("rand", "success", {
			timeout = 1000 * 5,
			title = "org evidence",
		})
	end
	return item
end

local function get_new()
	local this = get_instance()
	local item = nil
	local items = this.org_sql.find(1, "drill_total_repeats=0")
	if type(items) == "table" then
		item = items[1]
	else
		vim.notify("new", "success", {
			timeout = 1000 * 5,
			title = "org evidence",
		})
	end
	return item
end

local get_ratio_func = {
	get_min,
	get_new,
	get_rand,
}

local function calc_next()
	local this = get_instance()
	local item = nil
	local id = 1
	local rand = math.floor(math.random(0, 100))
	if rand < this.ratio_min then
		id = 1
	elseif rand < this.ratio_new then
		id = 2
	elseif rand < this.ratio_rand then
		id = 3
	end
	item = get_ratio_func[id]()
	if item == nil then
		item = get_ratio_func[3]()
	end
	return item
end

local function next()
	local this = get_instance()
	local item = calc_next()
	if type(item) ~= "table" then
		vim.notify("empty", "success", {
			timeout = 1000 * 5,
			title = "org evidence",
		})
		return
	end
	local item_date = os.date("%Y-%m-%d %H:%M", tonumber(item.drill_schedule))
	--print("last_time:" .. item_date)
	--vim.notify(item_date, "success", {
	--	timeout = 1000 * 7,
	--	title = "org evidence",
	--})
	this.drill_id = item.id
	this.win_buf.view_content(item.content)
	return item
end

local function content_overlay(item)
	vim.notify("content_overlay", "success", {
		timeout = 1000 * 5,
		title = "org evidence",
	})
	local this = get_instance()
	this.drill_id = item.id
	this.win_buf.view_content(item.content)
end

local function mock()
	local this = get_instance()
	this.org_sql.mock(true)
end

local function del_current()
	local this = get_instance()
	this.org_sql.del(this.drill_id)
end

local function setTable(id)
	local this = get_instance()
	this.org_sql.setTable(id)
	vim.notify("setTable: " .. id, "success", {
		timeout = 1000 * 2,
		title = "org evidence",
	})
end

local function get_end_of_today()
	local today = os.date("*t")
	today.hour = 0
	today.day = today.day + 1
	today.min = 0
	return os.time(today)
end

local function format_date(date)
	return os.date("%Y-%m-%d %H:%M", tonumber(date))
end

local function print_info()
	local this = get_instance()
	local items = this.org_sql.find(1, "id=" .. this.drill_id)
	if items and #items == 1 then
		local item = items[1]
		--item.actual_date = os.date("%Y-%m-%d %H:%M", tonumber(x.drill_schedule))
		print("<<<<<<<<<<<<<<<<<")
		print("<<<<evidence info")
		print("id: " .. vim.inspect(item.id))
		print("ef: " .. vim.inspect(item.drill_ef))
		print("failures: " .. vim.inspect(item.drill_failures))
		print("lasttime: " .. format_date(item.drill_lasttime))
		print("meanq: " .. vim.inspect(item.drill_meanq))
		print("schedule: " .. format_date(item.drill_schedule))
		print("total_repeat: " .. vim.inspect(item.drill_total_repeats))
		print(">>>>evidence info")
		print(">>>>>>>>>>>>>>>>")
	end
end

local function start()
	local this = get_instance()
	if this.is_start == false then
		this.is_start = true
		this.org_sql.init()
	end

	--init_test()
	this.win_buf.open_split_win()
	local item = next()
	if item == nil then
		return
	end
	local diff = tonumber(get_end_of_today()) - tonumber(item.drill_schedule)
	--print(vim.inspect(item_date))
	--print(vim.inspect(diff))
	--print(vim.inspect(get_end_of_today()))
	--print(vim.inspect(item.drill_schedule))
	--print(vim.inspect(os.time()))
	local msg = "start"
	if diff < 0 then
		msg = msg .. " (today work finished)"
	end
	vim.notify(msg, "success", {
		timeout = 1000 * 2,
		title = "org evidence",
	})
end

local function get_tables()
	local this = get_instance()
	return this.org_sql.tables
end

local function quality()
	local this = get_instance()
	local val = vim.fn.OrgmodeInput("quality: ", "")
	assert(val ~= nil)
	local x = tonumber(val)
	assert(x ~= nil)
	this.org_sql.setQuality(this.drill_id, x)
	--vim.notify("set quality", "success", {
	--	timeout = 1000 * 2,
	--	title = "org evidence",
	--})
	next()
end

return {
	start = start,
	next = next,
	quality = quality,
	add = add,
	edit = edit,
	setTable = setTable,
	get_tables = get_tables,
	content_overlay = content_overlay,
	del_current = del_current,
	print_info = print_info,
}
