local function isInTable(v, tb)
  for _, value in ipairs(tb) do
    if value == v then
      return true
    end
  end
  return false
end

-- array concat
local function table_concat(...)
  local nargs = select("#", ...)
  local argv = { ... }
  local t = {}
  for i = 1, nargs do
    local array = argv[i]
    if type(array) == "table" then
      for j = 1, #array do
        t[#t + 1] = array[j]
      end
    else
      t[#t + 1] = array
    end
  end

  return t
end

-- t2 merge into t1
local function merge(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == "table") and (type(t1[k] or false) == "table") then
      merge(t1[k], t2[k])
    else
      t1[k] = v
    end
  end
  return t1
end

local function str2table(str)
  local lines = {}
  for s in str:gmatch("[^\r\n]+") do
    local s1 = s:gsub("\\n", "\n")
    for ss in s1:gmatch("[^\r\n]+") do
      table.insert(lines, ss)
      table.insert(lines, "")
    end
  end
  return lines
end

--- check {{{}}}
function isTableEmpty(t, visited)
  if type(t) ~= "table" then
    return false
  end
  visited = visited or {} -- 初始化 visited 表
  if visited[t] then
    return true          -- 如果 t 已经被访问过，认为它是空表
  end
  visited[t] = true      -- 将 t 加入 visited 表中
  for _, v in pairs(t) do
    if type(v) == "table" then
      if not isTableEmpty(v, visited) then
        return false
      end
    else
      if v ~= nil then
        return false
      end
    end
  end
  return true
end

return {
  isInTable = isInTable,
  table_concat = table_concat,
  merge = merge,
  str2table = str2table,
  isTableEmpty = isTableEmpty,
}
