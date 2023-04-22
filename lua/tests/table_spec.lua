local sql = require("lua.table")

local eq = function(a, b)
  assert.are.same(a, b)
end

local data = {
  uri = "/Users/ouyangjunyi/.local/share/nvim/lazy/nvim-evidence/sql/v2",
  all_table_id = { "sundry" },
  now_table_id = "sundry",
}

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
    sql:drop()
    local n = 3
    for i = 1, n do
      sql:addContent("* mock" .. i .. "\n aa d \n ** answer\n bb ")
    end
    local data = sql:findAll()
    assert(data ~= nil)
    eq(n, #data)
    for i = 1, n - 1 do
      sql:del(data[i].id)
    end
    data = sql:findAll()
    eq(1, #data)
  end)
end)
