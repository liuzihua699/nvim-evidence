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

---@class SingleImpl
local SingleImpl = {}
SingleImpl.__index = SingleImpl

function SingleImpl:new()
	self.xx = 123
	self.is_setup = false
	return setmetatable({}, self)
end

function SingleImpl:a()
	print("x")
end

function SingleImpl:setup(data)
	print("x")
end

---@class Single
local Single = {}

Single.__index = function(self, key)
	--print(key)
	local value = rawget(Single, key)
	if key ~= "setup" then
		if not self.is_setup then
			error("Class not initialized. Please call setup() first.", 2)
		end
	end
	return value
end

Single.__newindex = function()
	error("Attempt to modify a read-only table")
end

---@return Single
function Single:getInstance()
	if not self.instance then
		self._ = SingleImpl:new()
		local data = {
			is_setup = false,
			x1 = 1,
			x2 = 2,
		}
		self.instance = setmetatable(data, self)
	end
	return self.instance
end

function Single:setup(data)
	if self.is_setup then
		error("cannot setup twice")
	end
	self.is_setup = true
	Single.__index = Single
	self._.setup(data)
	self.x1 = data.x1
end

function Single:foo()
	print("foo")
end

function Single:b()
	print("b")
	self._:a()
end

-- example
--local xx = Single:getInstance()
--xx:setup({ x1 = 342 })
--xx:b()

-- export
-- cannot not export MyClass directly
return Single:getInstance()

