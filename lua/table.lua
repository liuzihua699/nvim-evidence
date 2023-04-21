local tools = require("lua.tools")
require("lua.dump")

---@class SqlTableImpl
---@field sqlite any
---@field tbl any
---@field uri string sql path
---@field all_table_id table<string>
---@field now_table_id string
---@field now_table any
---@field all_table table<string,any>
---@field table_field table<string,any>
local SqlTableImpl = {}
SqlTableImpl.__index = SqlTableImpl

function SqlTableImpl:new()
  self.sqlite = require("sqlite.db")
  self.tbl = require("sqlite.tbl")
  self.uri = ""
  self.all_table_id = {}
  self.now_table_id = ""
  self.now_table = nil
  self.table_field = {
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
  self.all_table = {}
  return setmetatable({}, self)
end

function SqlTableImpl:setup(data)
  assert(data.uri ~= nil, "uri required")
  assert(type(data.all_table_id) == "table", "all_table_id required table")
  assert(type(data.now_table_id) == "string", "now_table_id required string")
  self.uri = data.uri
  self.all_table_id = data.all_table_id
  self.now_table_id = data.now_table_id

  for _k, item in pairs(self.all_table_id) do
    local tb = self.tbl(item, self.table_field)
    self.all_table[item] = tb
  end

  self.now_table = self.all_table[self.now_table_id]

  local uri_map = { uri = self.uri }
  self.sqlite(tools.merge(uri_map, self.all_table))
end

---@param obj table<string,any>
function SqlTableImpl:insert(obj)
  self.now_table:insert(obj)
end

function SqlTableImpl:editById(id, row)
  return self.now_table:update({
    where = { id = id },
    set = row,
  })
end

function SqlTableImpl:drop()
  self.now_table:drop()
end

-- convert empty table to nil
---@param item nil | table
---@return nil | table
function SqlTableImpl:convert_empty_table(item)
  local ret = item
  if item == nil or (type(item) == "table" and #item == 1 and next(item[1]) == nil) then
    ret = nil
  end
  return ret
end

---@param query string
---@return nil | table
function SqlTableImpl:eval(query)
  local item = self.now_table:eval(query)
  return self:convert_empty_table(item)
end

---@param limit_num number
---@param statement string | nil
---@return nil | table
function SqlTableImpl:find(limit_num, statement)
  local query = "SELECT * FROM " .. self.now_table_id
  if statement ~= nil then
    query = query .. " where " .. statement
  end
  if limit_num ~= -1 then
    query = query .. " LIMIT " .. limit_num
  end
  return self:eval(query)
end

---@class SqlTable
---@field _ SqlTableImpl
---@field is_setup boolean
---@field now_table_id number
---@field instance SqlTable
---@field setup function
---@field getInfo function
local SqlTable = {}

SqlTable.__index = function(self, key)
  local value = rawget(SqlTable, key)
  if key ~= "setup" then
    if not self.is_setup then
      error("Class not initialized. Please call setup() first.", 2)
    end
  end
  return value
end

SqlTable.__newindex = function()
  error("Attempt to modify a read-only table")
end

function SqlTable:getInstance()
  if not self.instance then
    self._ = SqlTableImpl:new()
    self.instance = setmetatable({ is_setup = false }, self)
  end
  return self.instance
end

---@param data table<string,any>
function SqlTable:setup(data)
  if self.is_setup then
    error("cannot setup twice")
  end
  self.is_setup = true
  self._:setup(data)
end

function SqlTable:getInfo()
  return {
    uri = self._.uri,
    now_table_id = self._.now_table_id,
    all_table_id = self._.all_table_id,
  }
end

--function SqlTable:release()
--  self.instance.is_setup = false
--  self.instance = nil
--  self._ = nil
--end

function SqlTable:addContent(content)
  self._:insert({ content = content })
end

---@param id number
---@param row table
function SqlTable:editById(id, row)
  self._:editById(id, row)
end

function SqlTable:drop()
  self._:drop()
end

---@return nil | table
function SqlTable:findAll()
  return self._:find(-1, nil)
end

return SqlTable:getInstance()
