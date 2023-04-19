local SqlTable = require("lua.table")
local sql = SqlTable:getInstance()

local eq = function(a, b)
  assert.are.same(a, b)
end

local data = {
  uri = "/Users/ouyangjunyi/.config/nvim/sql/v2",
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
  it("setup and release", function()
    sql = SqlTable:getInstance()
    SqlTable:release()
    eq(sql.is_setup, false)
    sql = SqlTable:getInstance()
    eq(sql.is_setup, false)
    sql:setup(data)
    eq(sql.is_setup, true)
  end)
end)
