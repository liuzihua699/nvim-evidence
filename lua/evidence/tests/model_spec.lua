local model = require("lua.model.index")
local _ = require("lua.model.fsrs_models")
local tools = require("lua.util.tools")

local eq = function(a, b)
  assert.are.same(a, b)
end

local data = {
  uri = "/Users/junyiouyang/.local/share/nvim/lazy/nvim-evidence/sql/v2",
  all_table = {
    t1 = {},
    t2 = {
      request_retention = 0.7,
      maximum_interval = 100,
      easy_bonus = 1.0,
      hard_factor = 0.8,
      w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
    },
  },
  now_table_id = "t1",
}

model:setup(data)

local lim = 3

local reset = function(n)
  model:clear()
  n = n or lim
  for i = 1, n do
    model:addNewCard("* mock" .. i .. "abc")
  end
  return n
end

describe("fsrs_sql_model", function()
  it("info", function()
    local info = model:getAllInfo()
    --print(vim.inspect(info))
  end)
  it("add_del", function()
    local n = reset()
    local data = model:findAll()
    assert(data ~= nil)
    eq(n, #data)
    for i = 1, n - 1 do
      model:delCard(data[i].id)
    end
    data = model:findAll()
    eq(1, #data)
  end)
  it("findById", function()
    reset()
    local ret = model:findById(1)
    assert(ret ~= nil)
    eq(1, ret.id)
  end)
  it("editById", function()
    reset()
    local content = "xx"
    local ret = model:editCard(1, { content = content })
    eq(ret, true)
    local obj = model:findById(1)
    assert(obj ~= nil)
    eq(content, obj.content)
  end)
  it("setTable", function()
    local ret = model:switchTable("t1")
    eq(true, ret)
    model:clear()
    ret = model:switchTable("t2")
    eq(true, ret)
    local n = reset()
    local data = model:findAll()
    eq(n, #data)
    ret = model:switchTable("t1")
    eq(true, ret)
    data = model:findAll()
    eq(nil, data)
  end)
  it("ratingCard", function()
    reset(1)
    local data = model:findAll()
    tools.printDump(data)
    model:ratingCard(1, _.Rating.Again, os.time() + 5 * 24 * 60 * 60)
    data = model:findAll()
    tools.printDump(data)
  end)
end)