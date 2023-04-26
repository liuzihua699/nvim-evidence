--- @class CardData
--- @field id string
--- @field due string
--- @field interval number
--- @field difficulty number
--- @field stability number
--- @field retrievability number
--- @field grade number
--- @field review string
--- @field reps number
--- @field lapses number
--- @field history History[]

--- @class History
--- @field due string
--- @field interval number
--- @field difficulty number
--- @field stability number
--- @field retrievability number
--- @field grade number
--- @field lapses number
--- @field reps number
--- @field review string

--- @class GlobalData
--- @field difficultyDecay number
--- @field stabilityDecay number
--- @field increaseFactor number
--- @field requestRetention number
--- @field totalCase number
--- @field totalDiff number
--- @field totalReview number
--- @field defaultDifficulty number
--- @field defaultStability number
--- @field stabilityDataArry StabilityData[]

--- @class StabilityData
--- @field interval number
--- @field retrievability number

--- Algo function
--- @param cardData CardData
--- @param grade number
--- @param globalData GlobalData
--- @return table
function algo(cardData, grade, globalData)
  cardData = cardData or { id = "default" }
  grade = grade or -1
  globalData = globalData
      or {
        difficultyDecay = -0.7,
        stabilityDecay = -0.2,
        increaseFactor = 60,
        requestRetention = 0.9,
        totalCase = 0,
        totalDiff = 0,
        totalReview = 0,
        defaultDifficulty = 5,
        defaultStability = 2,
        stabilityDataArry = {},
      }

  if grade == -1 then
    local addDay = math.floor(globalData.defaultStability * math.log(globalData.requestRetention) / math.log(0.9))

    cardData.due = os.date("!%Y-%m-%dT%H:%M:%S", os.time() + addDay * 86400)
    cardData.interval = 0
    cardData.difficulty = globalData.defaultDifficulty
    cardData.stability = globalData.defaultStability
    cardData.retrievability = 1
    cardData.grade = -1
    cardData.review = os.date("!%Y-%m-%dT%H:%M:%S")
    cardData.reps = 1
    cardData.lapses = 0
    cardData.history = {}
  else
    local lastDifficulty = cardData.difficulty
    local lastStability = cardData.stability
    local lastLapses = cardData.lapses
    local lastReps = cardData.reps
    local lastReview = cardData.review

    table.insert(cardData.history, {
      due = cardData.due,
      interval = cardData.interval,
      difficulty = cardData.difficulty,
      stability = cardData.stability,
      retrievability = cardData.retrievability,
      grade = cardData.grade,
      lapses = cardData.lapses,
      reps = cardData.reps,
      review = cardData.review,
    })

    local diffDay = (os.time() - os.time(lastReview)) / 86400

    cardData.interval = diffDay > 0 and math.ceil(diffDay) or 0
    cardData.review = os.date("!%Y-%m-%dT%H:%M:%S")
    cardData.retrievability = math.exp((math.log(0.9) * cardData.interval) / lastStability)
    cardData.difficulty = math.min(math.max(lastDifficulty + cardData.retrievability - grade + 0.2, 1), 10)

    if grade == 0 then
      cardData.stability = globalData.defaultStability * math.exp(-0.3 * (lastLapses + 1))

      if lastReps > 1 then
        globalData.totalDiff = globalData.totalDiff - cardData.retrievability
      end

      cardData.lapses = lastLapses + 1
      cardData.reps = 1
    else
      cardData.stability = lastStability
          * (
          1
          + globalData.increaseFactor
          * math.pow(cardData.difficulty, globalData.difficultyDecay)
          * math.pow(lastStability, globalData.stabilityDecay)
          * (math.exp(1 - cardData.retrievability) - 1)
          )

      if lastReps > 1 then
        globalData.totalDiff = globalData.totalDiff + 1 - cardData.retrievability
      end

      cardData.lapses = lastLapses
      cardData.reps = lastReps + 1
    end

    globalData.totalCase = globalData.totalCase + 1
    globalData.totalReview = globalData.totalReview + 1

    local addDay = math.floor(cardData.stability * math.log(globalData.requestRetention) / math.log(0.9))
    cardData.due = os.date("!%Y-%m-%dT%H:%M:%S", os.time() + addDay * 86400)

    if globalData.totalCase > 100 then
      globalData.defaultDifficulty = (1 / math.pow(globalData.totalReview, 0.3))
          * (math.pow(
            math.log(globalData.requestRetention)
            / math.max(
              math.log(globalData.requestRetention + globalData.totalDiff / globalData.totalCase),
              0
            ),
            1 / globalData.difficultyDecay
          ) * 5)
          + (1 - 1 / math.pow(globalData.totalReview, 0.3)) * globalData.defaultDifficulty

      globalData.totalDiff = 0
      globalData.totalCase = 0
    end

    if lastReps == 1 and lastLapses == 0 then
      table.insert(
        globalData.stabilityDataArry,
        { interval = cardData.interval, retrievability = grade == 0 and 0 or 1 }
      )

      if #globalData.stabilityDataArry > 0 and #globalData.stabilityDataArry % 50 == 0 then
        local intervalSetArry = {}

        local sumRI2S = 0
        local sumI2S = 0

        for _, s in ipairs(globalData.stabilityDataArry) do
          local ivl = s.interval

          if not table.contains(intervalSetArry, ivl) then
            table.insert(intervalSetArry, ivl)

            local filterArry = table.filter(globalData.stabilityDataArry, function(fi)
              return fi.interval == ivl
            end)

            local retrievabilitySum = table.reduce(filterArry, function(sum, e)
              return sum + e.retrievability
            end, 0)

            if retrievabilitySum > 0 then
              sumRI2S = sumRI2S + ivl * math.log(retrievabilitySum / #filterArry) * #filterArry
              sumI2S = sumI2S + ivl * ivl * #filterArry
            end
          end
        end
        globalData.defaultStability = (
            math.max(math.log(0.9) / (sumRI2S / sumI2S), 0.1) + globalData.defaultStability
            ) / 2
      end
    end
  end

  return { cardData = cardData, globalData = globalData }
end

-- Utility functions

--- Check if a value exists in a table
function table.contains(tbl, val)
  for _, v in ipairs(tbl) do
    if v == val then
      return true
    end
  end
  return false
end

--- Filter a table using a predicate function
function table.filter(tbl, predicate)
  local res = {}
  for _, v in ipairs(tbl) do
    if predicate(v) then
      table.insert(res, v)
    end
  end
  return res
end

--- Reduce a table to a single value using a reducer function
function table.reduce(tbl, reducer, init)
  local res = init
  for _, v in ipairs(tbl) do
    res = reducer(res, v)
  end
  return res
end

return algo
