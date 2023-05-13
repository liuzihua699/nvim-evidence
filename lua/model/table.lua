local tools = require("lua.util.tools")

local now_time = os.time()

---@class SqlInfo
---@field uri string
---@field all_table_id table<string>
---@field now_table_id string
local SqlInfo = {}

---@class FsrsTableField
---@field id number
---@field content string
---@field schedule number
---@field info string fsrs data
local FsrsTableField = {
  id = 0, -- same as { type = "integer", required = true, primary = true }
  content = "text",
  schedule = now_time,
  info = "",
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
    content = { "text" },
    schedule = { "number", default = FsrsTableField.schedule },
    info = { "text", required = true },
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
---@return nil | FsrsTableField[]
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
---@return nil | FsrsTableField
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

return SqlTableImpl
