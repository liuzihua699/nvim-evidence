local _ = require("lua.fsrs_models")
local tools = require("lua.tools")

--- @class Parameters
--- @field request_retention number
--- @field maximum_interval number
--- @field easy_bonus number
--- @field hard_factor number
--- @field w table<number>
local Parameters = {}

function Parameters:new()
	local obj = {
		request_retention = 0.9,
		maximum_interval = 36500,
		easy_bonus = 1.3,
		hard_factor = 1.2,
		w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 },
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

--- @class FSRS
--- @field p Parameters
local FSRS = {}

function FSRS:new()
	local obj = {
		p = Parameters:new(),
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

---@param d number
---@return number
function FSRS:constrain_difficulty(d)
	return math.min(math.max(d, 1), 10)
end

---@param r RatingType
function FSRS:init_difficulty(r)
	return self:constrain_difficulty(self.p.w[3] + self.p.w[4] * (r - 2))
end

---@param r RatingType
function FSRS:init_stability(r)
	return math.max(self.p.w[1] + self.p.w[2] * r, 0.1)
end

---@param s SchedulingCards
function FSRS:init_ds(s)
	s.again.difficulty = self:init_difficulty(_.Rating.Again)
	s.again.stability = self:init_stability(_.Rating.Again)
	s.hard.difficulty = self:init_difficulty(_.Rating.Hard)
	s.hard.stability = self:init_stability(_.Rating.Hard)
	s.good.difficulty = self:init_difficulty(_.Rating.Good)
	s.good.stability = self:init_stability(_.Rating.Good)
	s.easy.difficulty = self:init_difficulty(_.Rating.Easy)
	s.easy.stability = self:init_stability(_.Rating.Easy)
end

---@param s number
---@return Days 
function FSRS:next_interval(s)
	local new_interval = s * math.log(self.p.request_retention) / math.log(0.9)
	return math.max(math.min(math.floor(new_interval + 0.5), self.p.maximum_interval), 1)
end

--- Repeat function
--- @param card_ Card
--- @param now Timestamp
function FSRS:repeats(card_, now)
	local card = _.Card:copy()
	if card.state == _.State.New then
		card.elapsed_days = 0
	else
		card.elapsed_days = os.difftime(now, card.last_review) / (24 * 60 * 60)
	end
	card.last_review = now
	card.reps = card.reps + 1
	local s = _.SchedulingCards:new(card)
	s:update_state(card.state)

	if card.state == State.New then
		self:init_ds(s)

		s.again.due = now + 60
		s.hard.due = now + 5 * 60
		s.good.due = now + 10 * 60

		local easy_interval = self:next_interval(s.easy.stability * self.p.easy_bonus)
		s.easy.scheduled_days = easy_interval
		s.easy.due = now + easy_interval * 24 * 60 * 60
	end
end
