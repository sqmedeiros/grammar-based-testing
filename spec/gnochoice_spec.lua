local gnochoice = require"gnochoice"
local parser = require"parser"
local pretty = require"pretty"

local function removeChoice (g)
	local gNo = gnochoice.new()
	gNo:withChoiceToNoChoice(g)
	
	assert.same(g.plist, gNo.ruleList)
	
	for _, var in ipairs(gNo.ruleList) do
		local gRHS = g.prules[var]
		local gNoRHS = gNo.ruleMap[var]
		local s1 = pretty.printp(gRHS)
		local s2 = gNo:printRHS(gNoRHS)
		assert.equal(s1, s2:gsub('|', '/'))
	end
end

describe("Testing #grammar", function()
	
	test("Rewrite grammar without choice", function()
		local g = parser.match[[
			s <- 'a' / 'c'
		]]
		removeChoice(g)
	end)
	
	test("Rewrite grammar without choice", function()
		local g = parser.match[[
			s <- 'a' / 'c' / a
			a <- 'b' / 'c' a A / ''
			A <- B / D
			B <- 'b'
			D <- 'd'
		]]
		removeChoice(g)
	end)
	
	
end)
