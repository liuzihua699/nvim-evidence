--exmaple https://github.com/kkharji/sqlite.lua/blob/master/lua/sqlite/examples/bookmarks.lua

local sql = require("lua.table")

local eq = function(a, b)
  assert.are.same(a, b)
end

local data = {
  uri = "/Users/junyiouyang/.local/share/nvim/lazy/nvim-evidence/sql/v2",
  all_table_id = { "t1", "t2", "t3" },
  now_table_id = "t1",
}

local reset = function()
  sql:clear()
  local n = 3
  for i = 1, n do
    sql:addContent("* mock" .. i .. "abc")
  end
  return n
end

describe("SqlTable", function()
  it("setup", function()
    sql:setup(data)
  end)
  it("getInfo", function()
    local info = sql:getInfo()
    assert(info.uri ~= nil)
    assert(type(info.all_table_id) == "table")
    assert(type(info.now_table_id) == "string")
  end)
  it("add_del", function()
    local n = reset()
    local data = sql:findAll()
    assert(data ~= nil)
    eq(n, #data)
    for i = 1, n - 1 do
      sql:del(data[i].id)
    end
    data = sql:findAll()
    eq(1, #data)
  end)
  it("findById", function()
    reset()
    local ret = sql:findById(1)
    assert(ret ~= nil)
    eq(1, ret.id)
  end)
  it("editById", function()
    reset()
    local content = "xx"
    local ret = sql:editById(1, { content = content })
    eq(ret, true)
    local obj = sql:findById(1)
    assert(obj ~= nil)
    eq(content, obj.content)
  end)
  it("setTable", function()
    local ret = sql:setTable("t1")
    eq(true, ret)
    sql:clear()
    ret = sql:setTable("t2")
    eq(true, ret)
    local n = reset()
    local data = sql:findAll()
    eq(n, #data)
    ret = sql:setTable("t1")
    eq(true, ret)
    data = sql:findAll()
    --print(vim.inspect(data))
    eq(nil, data)
  end)
end)
