local eq = function(a, b)
	assert.are.same(a, b)
end

local sqlite = require("sqlite.db")
local xx = require("lua.single")

describe("Test", function()
	it("x1", function()
		xx:setup({ x1 = 342 })
		xx:b()
		eq(342, xx.x1)
	end)
end)
