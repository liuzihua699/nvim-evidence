local tools = require("lua.tools")

local now_time = os.time()

---@class SqlInfo
---@field uri string
---@field all_table_id table<string>
---@field now_table_id string
local SqlInfo = {}

---@class EvidenceTableField
---@field id number
---@field content string
---@field schedule number
---@field lasttime number
---@field ef number
---@field n number
---@field failures number
---@field meanq number
---@field total_repeats number
---@field weight number
local EvidenceTableField = {
  id = 0, -- same as { type = "integer", required = true, primary = true }
  content = "text",
  lasttime = now_time,
  schedule = now_time,
  ef = 0,
  n = 0, -- new card mark
  failures = 0,
  meanq = 0,
  total_repeats = 0,
  weight = 1,
}

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
    schedule = { "number", default = EvidenceTableField.schedule },
    lasttime = { "number", default = EvidenceTableField.lasttime },
    ef = { "number", default = EvidenceTableField.ef },
    n = { "number", default = EvidenceTableField.n }, -- new card mark
    failures = { "number", default = EvidenceTableField.failures },
    meanq = { "number", default = EvidenceTableField.meanq },
    total_repeats = { "number", default = EvidenceTableField.total_repeats },
    weight = { "number", default = EvidenceTableField.weight },
  }
  self.all_table = {}
  return setmetatable({}, self)
end

---@param data SqlInfo
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

---@param id number
---@param row table
---@return boolean
function SqlTableImpl:editById(id, row)
  return self.now_table:update({
    where = { id = id },
    set = row,
  })
end

---@param query string
---@return nil | table
function SqlTableImpl:eval(query)
  local item = self.now_table:eval(query)
  if tools.isTableEmpty(item) then
    return nil
  end
  return item
end

function SqlTableImpl:clear()
  return self:eval("delete from " .. self.now_table_id)
end

---@param limit_num number
---@param statement string | nil
---@return nil | EvidenceTableField[]
function SqlTableImpl:find(limit_num, statement)
  local query = "SELECT * FROM " .. self.now_table_id
  if statement ~= nil then
    query = query .. " where " .. statement
  end
  if limit_num ~= -1 then
    query = query .. " LIMIT " .. limit_num
  end
  local ret = self:eval(query)
  if type(ret) ~= "table" then
    return nil
  end
  return ret
end

---@param id number
function SqlTableImpl:del(id)
  self.now_table:remove({ id = id })
end

---@param column number
---@param statement string | nil
---@return nil | EvidenceTableField
function SqlTableImpl:min(column, statement)
  local query = "SELECT *, MIN(" .. column .. ") AS `rowmin` FROM " .. self.now_table_id
  if statement ~= nil then
    query = query .. " where " .. statement
  end
  local ret = self:eval(query)
  if ret ~= nil then
    return ret[1]
  else
    return nil
  end
end

---@param id string
---@return boolean
function SqlTableImpl:setTable(id)
  if tools.isInTable(id, self.all_table_id) then
    self.now_table_id = id
    self.now_table = self.all_table[id]
    return true
  end
  return false
end

---------------------------------------------------------------------------
---------------------------------------------------------------------------
---------------------------------------------------------------------------

---@class SqlTable
---@field _ SqlTableImpl
---@field is_setup boolean
---@field now_table_id number
---@field instance SqlTable
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

---@param data SqlInfo
function SqlTable:setup(data)
  if self.is_setup then
    error("cannot setup twice")
  end
  self.is_setup = true
  self._:setup(data)
end

---@return SqlInfo
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

---@param content string
function SqlTable:addContent(content)
  self._:insert({ content = content })
end

---@param id number
---@param row table
---@return boolean
function SqlTable:editById(id, row)
  return self._:editById(id, row)
end

---@return nil | EvidenceTableField[]
function SqlTable:findAll()
  return self._:find(-1, nil)
end

---@param id number
---@return nil | EvidenceTableField
function SqlTable:findById(id)
  local ret = self._:find(1, "id=" .. id)
  if ret ~= nil then
    return ret[1]
  else
    error("findById not exist id:" .. id)
    return nil
  end
end

---@param id number
function SqlTable:del(id)
  self._:del(id)
  return true
end

---@param column number
---@param statement string | nil
---@return nil | EvidenceTableField
function SqlTable:min(column, statement)
  return self._:min(column, statement)
end

---@param id string
---@return boolean
function SqlTable:setTable(id)
  return self._:setTable(id)
end

function SqlTable:clear()
  return self._:clear()
end

return SqlTable:getInstance()
