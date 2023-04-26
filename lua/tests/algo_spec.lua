local algo = require("lua.algo")
local tools = require("lua.tools")

local eq = function(a, b)
  assert.are.same(a, b)
end

--- Grade `-1` means learn new card,and `0, 1, 2` means review old card (0:forget 1:remember 2:grasp).
--
local now_test = function(n, grade)
  local p = {}
  p[1] = algo({ id = "123" }, -1, nil)
  for i = 2, n do
    p[i] = algo(p[i - 1].cardData, grade, p[i - 1].globalData)
  end
  return p[n]
end

local parse_format = "(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)"
local time_format = "%Y-%m-%dT%H:%M:%S"

local due_test = function(n, grade)
  local p = {}
  p[1] = algo({ id = "123" }, -1, nil)
  for i = 2, n do
    local tmp = p[i - 1]
    local review_time = tools.parseDate(tmp.cardData.review, parse_format)
    local due_time = tools.parseDate(tmp.cardData.due, parse_format)
    local diff_time = due_time - review_time
    tmp.cardData.review = tostring(os.date(time_format, os.time() - diff_time))
    tmp.cardData.due = tostring(os.date(time_format))
    p[i] = algo(tmp.cardData, grade, tmp.globalData)
  end
  return p[n]
end

local check_grade = function(func)
  local p = {}
  for i = 0, 2 do
    p[i] = func(10, i)
    --print("=========")
    --print(vim.inspect(p[i]))
  end
end

describe("algo", function()
  it("now_test", function()
    --check_grade(now_test)
  end)
  it("due_grade", function()
    check_grade(due_test)
  end)
end)
