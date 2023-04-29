
function Card:get_retrievability(now)
  if self.state == State.Review then
    local elapsed_days = math.max(0, os.difftime(now, self.last_review) / (24 * 3600))
    return math.exp(math.log(0.9) * elapsed_days / self.stability)
  else
    return nil
  end
end

--- @class SchedulingInfo


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

--- @class FSRS
local FSRS = {}
FSRS.__index = FSRS

--- FSRS constructor
function FSRS:new()
  self.p = Parameters:new()
  return setmetatable({}, self)
end

--- Repeat function
--- @param card_ Card
--- @param now number
--- @return table<number, SchedulingInfo>
function FSRS:repeats(card_, now)
  local card = card_:copy()
  if card.state == State.New then
    card.elapsed_days = 0
  else
    card.elapsed_days = os.difftime(now, card.last_review) / (24 * 60 * 60)
  end
  card.last_review = now
  card.reps = card.reps + 1
  local s = SchedulingCards:new(card)
  s:update_state(card.state)

  if card.state == State.New then
    self:init_ds(s)

    s.again.due = now + 60
    s.hard.due = now + 5 * 60
    s.good.due = now + 10 * 60
    local easy_interval = self:next_interval(s.easy.stability * self.p.easy_bonus)
    s.easy.scheduled_days = easy_interval
    s.easy.due = now + easy_interval * 24 * 60 * 60
  elseif card.state == State.Learning or card.state == State.Relearning then
    local hard_interval = 0
    local good_interval = self:next_interval(s.good.stability)
    local easy_interval = math.max(self:next_interval(s.easy.stability * self.p.easy_bonus), good_interval + 1)

    s:schedule(now, hard_interval, good_interval, easy_interval)
  elseif card.state == State.Review then
    local interval = card.elapsed_days
    local last_d = card.difficulty
    local last_s = card.stability
    local retrievability = math.exp(math.log(0.9) * interval / last_s)
    self:next_ds(s, last_d, last_s, retrievability)

    local hard_interval = self:next_interval(last_s * self.p.hard_factor)
    local good_interval = self:next_interval(s.good.stability)
    hard_interval = math.min(hard_interval, good_interval)
    good_interval = math.max(good_interval, hard_interval + 1)
    local easy_interval = math.max(self:next_interval(s.easy.stability * self.p.hard_factor), good_interval + 1)
    s:schedule(now, hard_interval, good_interval, easy_interval)
  end
  return s:record_log(card, now)
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

return {
  FSRS = FSRS,
  Card = Card,
  Rating = Rating,
}
