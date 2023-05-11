local _ = require("lua.fsrs_models")
local fsrs = require("lua.fsrs")
local tools = require("lua.tools")

local eq = function(a, b)
	assert.are.same(a, b)
end

---@param data table<RatingType,SchedulingInfo>
local printFSRS = function(data)
	print("<<<<<<<")
	print("again.card:")
	data[_.Rating.Again].card:dump()
	print("hard.card:")
	data[_.Rating.Hard].card:dump()
	print("good.card:")
	data[_.Rating.Good].card:dump()
	print("easy.card:")
	data[_.Rating.Easy].card:dump()
	print(">>>>>>>")
end

describe("fsrs", function()
	--it("fsrs_model", function()
	--	local card = _.Card:new()
	--	local info = _.SchedulingInfo:new(card)
	--	local cards = _.SchedulingCards:new(card)
	--	--dump(card)
	--	--dump(info)
	--	tools.dump(cards)
	--	cards:update_state(_.State.New)
	--	print("======")
	--	tools.dump(cards)
	--end)
	it("fsrs_schedule", function()
		local f = fsrs.FSRS:new()
		local card = _.Card:new()

		local now = os.time({ year = 2022, month = 11, day = 29, hour = 12, min = 30, sec = 0 })
		local scheduling_cards = f:repeats(card, now)
		--printFSRS(scheduling_cards)
		--
		card = scheduling_cards[_.Rating.Good].card
		now = card.due
		scheduling_cards = f:repeats(card, now)
		--printFSRS(scheduling_cards)
    --
		card = scheduling_cards[_.Rating.Good].card
		now = card.due
		scheduling_cards = f:repeats(card, now)
		--printFSRS(scheduling_cards)
    --
		card = scheduling_cards[_.Rating.Again].card
		now = card.due
		scheduling_cards = f:repeats(card, now)
		--printFSRS(scheduling_cards)
    --
		card = scheduling_cards[_.Rating.Good].card
		now = card.due
		scheduling_cards = f:repeats(card, now)
		printFSRS(scheduling_cards)
	end)
end)
