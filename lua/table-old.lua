local instance = nil

local sqlite = require("sqlite.db")                  --- for constructing sql databases
local tbl = require("sqlite.tbl")                    --- for constructing sql tables
local uri = "/Users/ouyangjunyi/.config/nvim/sql/v2" -- defined here to be deleted later
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
  schedule = { "number", default = tonumber(os.time()) },
  lasttime = { "number", default = tonumber(os.time()) },
  ef = { "number", default = 0 },
  n = { "number", default = 0 }, -- new card mark
  failures = { "number", default = 0 },
  meanq = { "number", default = 0 },
  total_repeats = { "number", default = 0 },
  weight = { "number", default = 1 },
}

---@class SqlTable
---@field initialized boolean
---@field table_list table
---@field current_table_id string
---@field info_table table
---@field current_table table
---@field table_map table
local SqlTable = {}

function SqlTable:new()
  local data = { initialized = false }
  setmetatable(data, self)
  self.__index = self
  return data
end

function SqlTable:init()
  if self.initialized then
    return
  end
  self.table_list = {
    "sundry",
  }

  self.current_table_id = "sundry"

  self.info_table = tbl("evidence_info", info_field)

  self.current_table = nil

  self.table_map = { ["evidence_info"] = self.info_table }
end

---@param exist? boolean
---@return SqlTable
local function get_instance(exist)
  if not instance then
    assert(exist ~= nil and exist == true)
    instance = SqlTable:new()
    SqlTable:init()
  end
  return instance
end

function SqlTable:setup()
  local this = get_instance()
  for _k, item in pairs(self.table_list) do
    local tb = tbl(item, fields)
    self.table_map[item] = tb
  end

  self.current_table = self.table_map[current_table_id]

  local sql_map = { uri = uri }
  sqlite(tools.merge(sql_map, self.table_map))
end

local function setTable(id)
  current_table_id = id
  current_table = table_map[id]
end

local demo = {}

local function mock()
  for i = 1, 5 do
    table.insert(demo, { content = "* mock" .. i .. "\n asdfa d \n ** answer\n asldfjasdf " })
  end
end

local function mock(force)
  if not force and current_table:count() ~= 0 then
    return
  end
  current_table:drop()
  mock()
  for _, row in ipairs(demo) do
    current_table:insert(row)
  end
end

local function add(content)
  current_table:insert({ content = content })
end

local function edit_by_table(tb, id, row)
  return tb:update({
    where = { id = id },
    set = row,
  })
end

local function info_get_by_table_id()
  local item = info_table:get({ where = { table_id = current_table_id } })
  if item and item[1] then
    return item[1]
  else
    info_table:insert({ sm5_optimal_factor_matrix = "", table_id = current_table_id })
  end
  return nil
end

local function info_edit(row)
  local item = info_get_by_table_id()
  if item then
    edit_by_table(info_table, item.id, row)
  end
end

local function edit(id, row)
  return edit_by_table(current_table, id, row)
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
  local item = current_table:get({ where = { id = id } })
  if #item ~= 1 then
    vim.notify("next id not found", "error")
  end
  item = item[1]
  -- local now_time=Date

  local now_time = tonumber(os.time())

  item.last_interval = (item.schedule - item.lasttime) / 24 / 60 / 60

  --print("<<<<<<<<<<<<<<<<<")
  --print("<<<<evidence input")
  --print("id: " .. vim.inspect(item.id))
  --print("quality: " .. vim.inspect(quality))
  --print("ef: " .. vim.inspect(item.ef))
  --print("failures: " .. vim.inspect(item.failures))
  --print("lasttime: " .. format_date(item.lasttime))
  --print("meanq: " .. vim.inspect(item.meanq))
  --print("schedule: " .. format_date(item.schedule))
  --print("total_repeat: " .. vim.inspect(item.total_repeats))
  --print("last_interval_days: " .. vim.inspect(item.last_interval))
  --print(">>>>evidence input")
  --print(">>>>>>>>>>>>>>>>")
  --print("<<<")
  print("evidence lasttime: " .. format_date(item.lasttime))
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
    schedule = new_item.schedule_time,
    lasttime = new_item.lasttime,
    ef = new_item.ef,
    n = new_item.n,
    failures = new_item.failures,
    meanq = new_item.meanq,
    total_repeats = new_item.total_repeats,
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
  local item = current_table:eval(query)
  return empty_nil(item)
end

local function min(column, statement)
  local query = "SELECT *, MIN(" .. column .. ") AS `rowmin` FROM " .. current_table_id
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
  local query = "SELECT * FROM " .. current_table_id
  if statement ~= nil then
    query = query .. " where " .. statement
  end
  return eval(query .. " LIMIT " .. limit_num)
end

local function top(column, limit_num)
  return eval("SELECT * FROM " .. current_table_id .. " ORDER BY " .. column .. " ASC LIMIT " .. limit_num)
end

local function random()
  return eval("SELECT * FROM " .. current_table_id .. " ORDER BY RANDOM() LIMIT 1")
end

local function del(id)
  current_table:remove({ id = id })
end

return SqlTable

return {
  min = min,
  setQuality = setQuality,
  setContent = setContent,
  mock = mock,
  setup = setup,
  --add = add,
  setTable = setTable,
  tables = table_list,
  --init = sql_init,
  setup = setup,
  find = find,
  del = del,
  random = random,
}
