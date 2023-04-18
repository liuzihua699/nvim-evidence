local eq = function(a, b)
  assert.are.same(a, b)
end

describe("WinBuf", function()
  it("x1", function()
    local xx = 123
    eq(123, xx)
  end)
end)
