local tools = require("lua.tools")

--- @alias RatingType integer
--- @class Rating
local Rating = {
	Again = 0,
	Hard = 1,
	Good = 2,
	Easy = 3,
}

--- @alias StateType integer
--- @class State
local State = {
	New = 0,
	Learning = 1,
	Review = 2,
	Relearning = 3,
}

--- @alias Timestamp integer
--- @alias Days integer

--- @class Card
--- @field due Timestamp
--- @field stability number
--- @field difficulty number
--- @field elapsed_days Days 前后两次实际复习时间间隔
--- @field scheduled_days Days
--- @field reps integer
--- @field lapses Days
--- @field state StateType
--- @field last_review Timestamp
local Card = {}

---@return Card
function Card:copy()
	return tools.copy(self)
end

function Card:new()
	local obj = {
		due = os.time(),
		stability = 0.0,
		difficulty = 0,
		elapsed_days = 0,
		scheduled_days = 0,
		reps = 0,
		lapses = 0,
		state = State.New,
		last_review = os.time(),
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

--- @class SchedulingCards
--- @field again Card
--- @field hard Card
--- @field good Card
--- @field easy Card
local SchedulingCards = {}

---@param card Card
---@return SchedulingCards 
function SchedulingCards:new(card)
	local obj = {
		again = tools.copy(card),
		hard = tools.copy(card),
		good = tools.copy(card),
		easy = tools.copy(card),
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

---@param state StateType
function SchedulingCards:update_state(state)
	if state == State.New then
		self.again.state = State.Learning
		self.hard.state = State.Learning
		self.good.state = State.Learning
		self.easy.state = State.Review
		self.again.lapses = self.again.lapses + 1
	elseif state == State.Learning or state == State.Relearning then
		self.again.state = state
		self.hard.state = state
		self.good.state = State.Review
		self.easy.state = State.Review
	elseif state == State.Review then
		self.again.state = State.Relearning
		self.hard.state = State.Review
		self.good.state = State.Review
		self.easy.state = State.Review
		self.again.lapses = self.again.lapses + 1
	end
end

--- @class SchedulingInfo
--- @field card Card
local SchedulingInfo = {}

function SchedulingInfo:new(card)
	local obj = {
		card = tools.copy(card),
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

return {
	SchedulingInfo = SchedulingInfo,
	Rating = Rating,
	State = State,
	Card = Card,
	SchedulingCards = SchedulingCards,
}
