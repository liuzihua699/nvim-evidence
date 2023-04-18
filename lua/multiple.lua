function dump(o)
	if type(o) == "table" then
		local s = "{ "
		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = '"' .. k .. '"'
			end
			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end
		return s .. "} "
	else
		return tostring(o)
	end
end

---@class MultipleImpl
local MultipleImpl = {}
MultipleImpl.__index = MultipleImpl

function MultipleImpl:new()
	self.xx = 123
	self.is_setup = false
	return setmetatable({}, self)
end

function MultipleImpl:a()
	print("_ a")
end

function MultipleImpl:setup(data)
	print("_ setup", dump(data))
end

---@class Multiple
local Multiple = {}

Multiple.__index = function(self, key)
	--print(key)
	local value = rawget(Multiple, key)
	if key ~= "setup" then
		if not self.is_setup then
			error("Class not initialized. Please call setup() first.", 2)
		end
	end
	return value
end

Multiple.__newindex = function()
	error("Attempt to modify a read-only table")
end

function Multiple:new()
	self._ = MultipleImpl:new()
	local data = {
		is_setup = false,
		x1 = 1,
		x2 = 2,
	}
	return setmetatable(data, self)
end

function Multiple:setup(data)
	if self.is_setup then
		error("cannot setup twice")
	end
	print('setup', dump(data))
	self.is_setup = true
	Multiple.__index = Multiple
	self._:setup(data)
	self.x1 = data.x1
end

function Multiple:foo()
	print("foo")
end

function Multiple:b()
	print("b")
	self._:a()
end

local function createInstance()
	Multiple._ = MultipleImpl:new()
	local data = {
		is_setup = false,
		x1 = 1,
		x2 = 2,
	}
	return setmetatable(data, Multiple)
end

-- example
local x = createInstance()
x:setup({ x1 = 342 })
print(x.x1)

local y = createInstance()
y:setup({ x1 = 123 })
print(y.x1)

-- export
-- cannot not export MyClass directly
return {
	createInstance = createInstance,
}
