--- @class State
local State = {
  New = 0,
  Learning = 1,
  Review = 2,
  Relearning = 3,
}

--- @class Rating
local Rating = {
  Again = 0,
  Hard = 1,
  Good = 2,
  Easy = 3,
}

--- @class ReviewLog
--- @field rating integer
--- @field elapsed_days integer
--- @field scheduled_days integer
--- @field review string
--- @field state integer
local ReviewLog = {}
ReviewLog.__index = ReviewLog

--- ReviewLog constructor
function ReviewLog:new(rating, elapsed_days, scheduled_days, review, state)
  self.rating = rating
  self.elapsed_days = elapsed_days
  self.scheduled_days = scheduled_days
  self.review = review
  self.state = state
  return setmetatable({}, self)
end

--- @class Card
--- @field due integer ostime
--- @field stability number
--- @field difficulty number
--- @field elapsed_days integer
--- @field scheduled_days integer
--- @field reps integer
--- @field lapses integer
--- @field state integer
--- @field last_review integer ostime
local Card = {}
Card.__index = Card

--- Card constructor
function Card:new()
  self.due = os.time()
  self.stability = 0.0
  self.difficulty = 0
  self.elapsed_days = 0
  self.scheduled_days = 0
  self.reps = 0
  self.lapses = 0
  self.state = State.New
  self.last_review = os.time()
  return setmetatable({}, self)
end

--- @class SchedulingInfo
--- @field card Card
--- @field review_log ReviewLog
local SchedulingInfo = {}
SchedulingInfo.__index = SchedulingInfo

--- SchedulingInfo constructor
function SchedulingInfo:new(card, review_log)
  self.card = card
  self.review_log = review_log
  return setmetatable({}, self)
end

--- @class SchedulingCards
--- @field card Card
local SchedulingCards = {}
SchedulingCards.__index = SchedulingCards

--- SchedulingCards constructor
function SchedulingCards:new(card)
  self.again = card:copy()
  self.hard = card:copy()
  self.good = card:copy()
  self.easy = card:copy()
  return setmetatable({}, self)
end

--- @class Parameters
local Parameters = {}
Parameters.__index = Parameters

--- Parameters constructor
function Parameters:new()
  self.request_retention = 0.9
  self.maximum_interval = 36500
  self.easy_bonus = 1.3
  self.hard_factor = 1.2
  self.w = { 1.0, 1.0, 5.0, -0.5, -0.5, 0.2, 1.4, -0.12, 0.8, 2.0, -0.2, 0.2, 1.0 }
  return setmetatable({}, self)
end

--- @class FSRS
local FSRS = {}
FSRS.__index = FSRS

--- FSRS constructor
function FSRS:new()
  self.p = Parameters:new()
  return setmetatable({}, self)
end

--- Get a deep copy of the card
function Card:copy()
  local new_card = Card:new()
  for k, v in pairs(self) do
    new_card[k] = v
  end
  return new_card
end


function Card:get_retrievability(now)
  if self.state == State.Review then
    local elapsed_days = math.max(0, os.difftime(now, self.last_review) / (24 * 3600))
    return math.exp(math.log(0.9) * elapsed_days / self.stability)
  else
    return nil
  end
end

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

function SchedulingCards:schedule(now, hard_interval, good_interval, easy_interval)
  self.again.scheduled_days = 0
  self.hard.scheduled_days = hard_interval
  self.good.scheduled_days = good_interval
  self.easy.scheduled_days = easy_interval
  self.again.due = now + 5 * 60
  if hard_interval > 0 then
    self.hard.due = now + hard_interval * 24 * 3600
  else
    self.hard.due = now + 10 * 60
  end
  self.good.due = now + good_interval * 24 * 3600
  self.easy.due = now + easy_interval * 24 * 3600
end

function SchedulingCards:record_log(card, now)
  return {
        [Rating.Again] = SchedulingInfo:new(
      self.again,
      ReviewLog:new(Rating.Again, self.again.scheduled_days, card.elapsed_days, now, card.state)
    ),
        [Rating.Hard] = SchedulingInfo:new(
      self.hard,
      ReviewLog:new(Rating.Hard, self.hard.scheduled_days, card.elapsed_days, now, card.state)
    ),
        [Rating.Good] = SchedulingInfo:new(
      self.good,
      ReviewLog:new(Rating.Good, self.good.scheduled_days, card.elapsed_days, now, card.state)
    ),
        [Rating.Easy] = SchedulingInfo:new(
      self.easy,
      ReviewLog:new(Rating.Easy, self.easy.scheduled_days, card.elapsed_days, now, card.state)
    ),
  }
end


function FSRS:init_ds(s)
  s.again.difficulty = self:init_difficulty(Rating.Again)
  s.again.stability = self:init_stability(Rating.Again)
  s.hard.difficulty = self:init_difficulty(Rating.Hard)
  s.hard.stability = self:init_stability(Rating.Hard)
  s.good.difficulty = self:init_difficulty(Rating.Good)
  s.good.stability = self:init_stability(Rating.Good)
  s.easy.difficulty = self:init_difficulty(Rating.Easy)
  s.easy.stability = self:init_stability(Rating.Easy)
end

function FSRS:next_ds(s, last_d, last_s, retrievability)
  s.again.difficulty = self:next_difficulty(last_d, Rating.Again)
  s.again.stability = self:next_forget_stability(s.again.difficulty, last_s, retrievability)
  s.hard.difficulty = self:next_difficulty(last_d, Rating.Hard)
  s.hard.stability = self:next_recall_stability(s.hard.difficulty, last_s, retrievability)
  s.good.difficulty = self:next_difficulty(last_d, Rating.Good)
  s.good.stability = self:next_recall_stability(s.good.difficulty, last_s, retrievability)
  s.easy.difficulty = self:next_difficulty(last_d, Rating.Easy)
  s.easy.stability = self:next_recall_stability(s.easy.difficulty, last_s, retrievability)
end

function FSRS:init_stability(r)
  return math.max(self.p.w[1] + self.p.w[2] * r, 0.1)
end

function FSRS:init_difficulty(r)
  return math.min(math.max(self.p.w[3] + self.p.w[4] * (r - 2), 1), 10)
end

function FSRS:next_interval(s)
  local new_interval = s * math.log(self.p.request_retention) / math.log(0.9)
  return math.min(math.max(math.floor(new_interval + 0.5), 1), self.p.maximum_interval)
end

function FSRS:next_difficulty(d, r)
  local next_d = d + self.p.w[5] * (r - 2)
  return math.min(math.max(self:mean_reversion(self.p.w[3], next_d), 1), 10)
end

function FSRS:mean_reversion(init, current)
  return self.p.w[6] * init + (1 - self.p.w[6]) * current
end

function FSRS:next_recall_stability(d, s, r)
  return s * (1 + math.exp(self.p.w[7]) * (11 - d) * math.pow(s, self.p.w[8]) * (math.exp((1 - r) * self.p.w[9]) - 1))
end

function FSRS:next_forget_stability(d, s, r)
  return self.p.w[10] * math.pow(d, self.p.w[11]) * math.pow(s, self.p.w[12]) * math.exp((1 - r) * self.p.w[13])
end
