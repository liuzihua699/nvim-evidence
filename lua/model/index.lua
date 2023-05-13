local SqlTableImpl = require("lua.model.table")
local FSRS = require("lua.model.fsrs")
local fsrs = FSRS.FSRS
local _ = FSRS.MODEL

---@class Model
---@field _ SqlTableImpl
---@field is_setup boolean
---@field now_table_id number
---@field instance Model
local Model = {}

Model.__index = function(self, key)
  local value = rawget(Model, key)
  if key ~= "setup" then
    if not self.is_setup then
      error("Class not initialized. Please call setup() first.", 2)
    end
  end
  return value
end

Model.__newindex = function()
  error("Attempt to modify a read-only table")
end

function Model:getInstance()
  if not self.instance then
    self._ = SqlTableImpl:new()
    self.instance = setmetatable({ is_setup = false }, self)
  end
  return self.instance
end

---@param data SqlInfo
function Model:setup(data)
  if self.is_setup then
    error("cannot setup twice")
  end
  self.is_setup = true
  self._:setup(data)
end

---@return SqlInfo
function Model:getInfo()
  return {
    uri = self._.uri,
    now_table_id = self._.now_table_id,
    all_table_id = self._.all_table_id,
  }
end

--function Model:release()
--  self.instance.is_setup = false
--  self.instance = nil
--  self._ = nil
--end

-----@param content string
--function Model:addContent(content)
--  self._:insert({ content = content })
--end
--
---@param content string
---@param info string
---@param schedule number
function Model:addCard(content, info, schedule)
  self._:insert({ content = content, info = info, schedule = schedule })
end

---@param id number
---@param row table
---@return boolean
function Model:editById(id, row)
  return self._:editById(id, row)
end

---@return nil | FsrsTableField[]
function Model:findAll()
  return self._:find(-1, nil)
end

---@param id number
---@return nil | FsrsTableField
function Model:findById(id)
  local ret = self._:find(1, "id=" .. id)
  if ret ~= nil then
    return ret[1]
  else
    error("findById not exist id:" .. id)
    return nil
  end
end

---@param id number
function Model:del(id)
  self._:del(id)
  return true
end

---@param column number
---@param statement string | nil
---@return nil | FsrsTableField
function Model:min(column, statement)
  return self._:min(column, statement)
end

---@param id string
---@return boolean
function Model:setTable(id)
  return self._:setTable(id)
end

function Model:clear()
  return self._:clear()
end

return Model:getInstance()
