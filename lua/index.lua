local tools = require("utils.tools")

---@class Evidence
---@field initialized boolean
---@field table_id string
---@field is_start boolean
---@field win_buf WinBuf
---@field sql SqlTable
local Evidence = {}

local mt = {
	__index = Evidence,
	__newindex = function(t, k, v)
		error("Attempt to modify a read-only Evidence")
	end,
}

function Evidence:new()
	error("Attempt to create instance of Evidence")
end

function Evidence:getInstance()
	if not self.instance then
		self.instance = setmetatable({}, mt)
		self.table_id = nil
		self.is_start = false
		self.ratio_min = 50
		self.ratio_new = 90
		self.ratio_rand = 100
		self.initialized = true
		self.win_buf = require("evidence.win_buf")
		self.sql = require("evidence.table")
		self.sql.init()
	end
	return self.instance
end

---@param exist? boolean
---@return Evidence
local function get_instance(exist)
	if not instance then
		assert(exist ~= nil and exist == true)
		instance = Evidence:new()
		Evidence:init()
	end
	return instance
end

local function add()
	local this = get_instance()
	local content = vim.api.nvim_buf_get_lines(this.win_buf:get_info().buf, 0, -1, false)
	local content_str = table.concat(content, "\n")
	this.sql.add(content_str)
	vim.notify("add ok", "success", {
		timeout = 1000 * 5,
		title = "org evidence",
	})
end

local function edit()
	local this = get_instance()
	local content = vim.api.nvim_buf_get_lines(this.win_buf:get_info().buf, 0, -1, false)
	local content_str = table.concat(content, "\n")
	this.sql.setContent(this.table_id, content_str)
	vim.notify("edit ok", "success", {
		timeout = 1000 * 5,
		title = "org evidence",
	})
	return item
end

function Evidence:get_min()
	local item = self.sql.min("schedule", "total_repeats!=0")
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

function Evidence:get_rand()
	local item = nil
	local items = self.sql.random()
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

function Evidence:get_new()
	local item = nil
	local items = self.sql.find(1, "total_repeats=0")
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

Evidence.get_ratio_func = {
	get_min = Evidence.get_min,
	get_new = Evidence.get_new,
	get_rand = Evidence.get_rand,
}

function Evidence:calc_next()
	local item = nil
	local id = 1
	local rand = math.floor(math.random(0, 100))
	if rand < self.ratio_min then
		id = 1
	elseif rand < self.ratio_new then
		id = 2
	elseif rand < self.ratio_rand then
		id = 3
	end
	item = self.get_ratio_func[id]()
	if item == nil then
		item = self.get_ratio_func[3]()
	end
	return item
end

local function next()
	local this = get_instance()
	local item = this:calc_next()
	if type(item) ~= "table" then
		vim.notify("empty", "success", {
			timeout = 1000 * 5,
			title = "org evidence",
		})
		return
	end
	local item_date = os.date("%Y-%m-%d %H:%M", tonumber(item.schedule))
	--print("last_time:" .. item_date)
	--vim.notify(item_date, "success", {
	--	timeout = 1000 * 7,
	--	title = "org evidence",
	--})
	this.table_id = item.id
	this.win_buf.view_content(item.content)
	return item
end

local function content_overlay(item)
	vim.notify("content_overlay", "success", {
		timeout = 1000 * 5,
		title = "org evidence",
	})
	local this = get_instance()
	this.table_id = item.id
	this.win_buf.view_content(item.content)
end

local function mock()
	local this = get_instance()
	this.sql.mock(true)
end

local function del_current()
	local this = get_instance()
	this.sql.del(this.table_id)
end

local function setTable(id)
	local this = get_instance()
	this.sql.setTable(id)
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
	local items = this.sql.find(1, "id=" .. this.table_id)
	if items and #items == 1 then
		local item = items[1]
		--item.actual_date = os.date("%Y-%m-%d %H:%M", tonumber(x.schedule))
		print("<<<<<<<<<<<<<<<<<")
		print("<<<<evidence info")
		print("id: " .. vim.inspect(item.id))
		print("ef: " .. vim.inspect(item.ef))
		print("failures: " .. vim.inspect(item.failures))
		print("lasttime: " .. format_date(item.lasttime))
		print("meanq: " .. vim.inspect(item.meanq))
		print("schedule: " .. format_date(item.schedule))
		print("total_repeat: " .. vim.inspect(item.total_repeats))
		print(">>>>evidence info")
		print(">>>>>>>>>>>>>>>>")
	end
end

local function setup()
	local this = get_instance(true)

	--init_test()
	this.win_buf:open_split_win()
	local item = next()
	if item == nil then
		return
	end
	local diff = tonumber(get_end_of_today()) - tonumber(item.schedule)
	--print(vim.inspect(item_date))
	--print(vim.inspect(diff))
	--print(vim.inspect(get_end_of_today()))
	--print(vim.inspect(item.schedule))
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
	return this.sql.tables
end

local function quality()
	local this = get_instance()
	local val = vim.fn.OrgmodeInput("quality: ", "")
	assert(val ~= nil)
	local x = tonumber(val)
	assert(x ~= nil)
	this.sql.setQuality(this.table_id, x)
	--vim.notify("set quality", "success", {
	--	timeout = 1000 * 2,
	--	title = "org evidence",
	--})
	next()
end

return {
	setup = setup,
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
