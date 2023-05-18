local SqlTable = require("evidence.model.table")
local _FSRS_ = require("evidence.model.fsrs")
local _ = _FSRS_.model
local tools = require("evidence.util.tools")

---@class ModelTableInfo
---@field uri string
---@field all_table table<string,Parameters|{}>
---@field now_table_id string

---@class Model
---@field tbl SqlTable
---@field is_setup boolean
---@field now_table_id number
---@field instance Model
---@field all_table table<string,Parameters>
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
    self.tbl = SqlTable:new()
    self.all_table = {}
    self.instance = setmetatable({ is_setup = false }, self)
  end
  return self.instance
end

---@param data ModelTableInfo
function Model:setup(data)
  if self.is_setup then
    error("cannot setup twice")
  end
  self.is_setup = true
  local all_id = {}
  for key, item in pairs(data.all_table) do
    self.all_table[key] = _.Parameters:new(item)
    table.insert(all_id, key)
  end
  local sql_info = {
    uri = data.uri,
    now_table_id = data.now_table_id,
    all_table_id = all_id,
  }
  self.tbl:setup(sql_info)
end

---@return ModelTableInfo
function Model:getAllInfo()
  return {
    uri = self.tbl.uri,
    now_table_id = self.tbl.now_table_id,
    all_table = self.all_table,
    sql_table = self.tbl:dump(),
  }
end

--function Model:release()
--  self.instance.is_setup = false
--  self.instance = nil
--  self.tbl = nil
--end

---@param content string
function Model:addNewCard(content)
  local card_info = _.Card:new()
  self.tbl:insertCard(content, card_info:dumpStr(), card_info.due)
end

---@param id number
---@param row table
---@return boolean
function Model:editCard(id, row)
  return self.tbl:editById(id, row)
end

---@return nil | FsrsTableField[]
function Model:findAll()
  return self.tbl:find(-1, nil)
end

---@param id number
---@return FsrsTableField
function Model:findById(id)
  local ret = self.tbl:find(1, "id=" .. id)
  if ret ~= nil then
    return ret[1]
  else
    error("findById not exist id:" .. id)
  end
end

---@param id number
function Model:delCard(id)
  self.tbl:del(id)
  return true
end

---@param column number
---@param statement string | nil
---@return nil | FsrsTableField
function Model:min(column, statement)
  return self.tbl:min(column, statement)
end

---@param table_id string
---@return boolean
function Model:switchTable(table_id)
  return self.tbl:setTable(table_id)
end

---@return Parameters
function Model:getParameter()
  return self.all_table[self.now_table_id]
end

---@return FSRS
function Model:getFsrs()
  return _FSRS_.fsrs:new(self:getParameter())
end

function Model:clear()
  return self.tbl:clear()
end

---@param sql_card FsrsTableField
---@return Card
function Model:convertRealCard(sql_card)
  local data = tools.parse(sql_card.info)
  --print(vim.inspect(data))
  return _.Card:new(data)
end

---@param id number
---@param rating RatingType
---@param now_time? Timestamp
function Model:ratingCard(id, rating, now_time)
  local fsrs = self:getFsrs()
  local sql_card = self:findById(id)
  now_time = now_time or os.time()
  local new_card = fsrs:repeats(self:convertRealCard(sql_card), now_time)[rating].card
  sql_card.due = new_card.due
  sql_card.info = new_card:dumpStr()
  self:editCard(id, sql_card)
end

return Model:getInstance()
