local algo = require("lua.algo")
local fsrs = require("lua.fsrs")
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

local cross_test = function(n, grade)
  local p = {}
  p[1] = algo({ id = "123" }, -1, nil)
  for i = 2, n do
    local tmp = p[i - 1]
    local review_time = tools.parseDate(tmp.cardData.review, parse_format)
    local due_time = tools.parseDate(tmp.cardData.due, parse_format)
    local diff_time = due_time - review_time
    tmp.cardData.review = tostring(os.date(time_format, os.time() - diff_time))
    tmp.cardData.due = tostring(os.date(time_format))
    grade = (grade + 1) % 3
    p[i] = algo(tmp.cardData, grade, tmp.globalData)
  end
  return p[n]
end

local long_before_test = function(n, grade)
  local p = {}
  p[1] = algo({ id = "123" }, -1, nil)
  for i = 2, n do
    local tmp = p[i - 1]
    local review_time = tools.parseDate(tmp.cardData.review, parse_format)
    local due_time = tools.parseDate(tmp.cardData.due, parse_format)
    local diff_time = due_time - review_time
    local long_time = 86400 * 30 -- 1 month
    tmp.cardData.review = tostring(os.date(time_format, os.time() - diff_time - long_time))
    tmp.cardData.due = tostring(os.date(time_format, os.time() - long_time))
    grade = (grade + 1) % 3
    p[i] = algo(tmp.cardData, grade, tmp.globalData)
  end
  return p[n]
end

local func_print = function(func, grade)
  local ret = func(10, grade)
  print("=========")
  print(vim.inspect(ret))
end

local check_grade = function(func, grade)
  if grade ~= nil then
    func_print(func, grade)
  else
    for i = 0, 2 do
      func_print(func, i)
    end
  end
end

function print_scheduling_cards(scheduling_cards)
  print("again.card:", vim.inspect(scheduling_cards[fsrs.Rating.Again].card))
  print("again.review_log:", vim.inspect(scheduling_cards[fsrs.Rating.Again].review_log))
  print("hard.card:", vim.inspect(scheduling_cards[fsrs.Rating.Hard].card))
  print("hard.review_log:", vim.inspect(scheduling_cards[fsrs.Rating.Hard].review_log))
  print("good.card:", vim.inspect(scheduling_cards[fsrs.Rating.Good].card))
  print("good.review_log:", vim.inspect(scheduling_cards[fsrs.Rating.Good].review_log))
  print("easy.card:", vim.inspect(scheduling_cards[fsrs.Rating.Easy].card))
  print("easy.review_log:", vim.inspect(scheduling_cards[fsrs.Rating.Easy].review_log))
  print("======================")
end

describe("algo", function()
  it("now_test", function()
    --check_grade(now_test)
  end)
  it("due_grade", function()
    --check_grade(due_test)
  end)
  it("cross_test", function()
    --check_grade(cross_test)
  end)
  it("long_before_test", function()
    --check_grade(long_before_test)
  end)
  it("fsrs", function()
    local f = fsrs.FSRS:new()
    local card = fsrs.Card:new()
    --local now = os.time()
    local now = os.time({ year = 2022, month = 11, day = 29, hour = 12, min = 30, sec = 0 })

    local scheduling_cards = f:repeats(card, now)
    print_scheduling_cards(scheduling_cards)

    --card = scheduling_cards[fsrs.Rating.Good].card
    --now = card.due
    --scheduling_cards = f:repeats(card, now)
    --print_scheduling_cards(scheduling_cards)

    --card = scheduling_cards[fsrs.Rating.Good].card
    --now = card.due
    --scheduling_cards = f:repeats(card, now)
    --print_scheduling_cards(scheduling_cards)

    --card = scheduling_cards[fsrs.Rating.Again].card
    --now = card.due
    --scheduling_cards = f:repeats(card, now)
    --print_scheduling_cards(scheduling_cards)

    --card = scheduling_cards[fsrs.Rating.Good].card
    --now = card.due
    --scheduling_cards = f:repeats(card, now)
    --print_scheduling_cards(scheduling_cards)
  end)
end)
