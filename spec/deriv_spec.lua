local deriv = require'deriv'
local parser = require'parser'
local list = require'list'
local pretty = require'pretty'
local say = require'say'

local newNode = parser.newNode

local function equalDeriv (d, s)
	local dStr = d.list:toString('', '', ' ', pretty.printp)
	local sStr = s
	if type(s) ~= "string" then	-- s is a list
		sStr = s:toString('', '', ' ', pretty.printp)
	end
	return dStr == sStr
end


local function is_one_of (state, args)
	local s = args[1]
	
	for i = 2, #args do
		local v = args[i]
		if equalDeriv(s, v) then
			return true
		end
	end
	
	return false
end

say:set("assertion.is_one_of.positive", "%s should be equal to one of the supplied expressions")
say:set("assertion.is_one_of.negative", "%s should not be equal to none of the supplied expressions")
assert:register("assertion", "is_one_of", is_one_of, "assertion.is_one_of.positive", "assertion.is_one_of.negative")



describe("Testing #deriv", function()
	
	test("New derivation from a simple grammar", function()
		local g = [[S <- 'a']]
		g = parser.match(g)
		assert.True(equalDeriv(deriv.new(g), list.new(newNode('var', 'S'))))
		assert.same(deriv.new(g).list, list.new(newNode('var', 'S')))
	end)
	
	test("Testing if the current derivation is a sentential form (must not have a lowercase non-terminal)", function()
		local g = [[S <- 'a']]
		g = parser.match(g)
		assert.True(deriv.new(g):isSententialForm())
	end)	
	
	test("Testing if the current derivation is not a sentential form (must have at lest a lowercase non-terminal)", function()
		local g = [[s <- 'a']]
		g = parser.match(g)
		assert.False(deriv.new(g):isSententialForm())
	end)
	
	test("Making a single derivation", function()
		local g = [[s <- 'a']]
		g = parser.match(g)
		local d = deriv.new(g)
		assert.same(d.list, list.new(newNode('var', 's')))
		d:step()
		assert.same(d.list, list.new(newNode('char', 'a')))
	end)
	
	test("Trying to derivate a sentential form (second step)", function()
		local g = [[s <- 'a']]
		g = parser.match(g)
		local d = deriv.new(g)
		assert.same(d.list, list.new(newNode('var', 's')))
		d:step()
		-- it is already a sentential form
		d:step()
		assert.same(d.list, list.new(newNode('char', 'a')))
	end)
	
	test("Making two derivations without choice", function()
		local g = [[s <- 'a' b
		            b <- c
		            c <- 'c']]
		g = parser.match(g)
		local d1 = deriv.new(g)
		d1:step()
		d1:step()
		
		local d2 = deriv.new(g)
		d2:step(2)
		
		assert.same(d1, d2)
		
		local l = list.new(newNode('char', 'a'), newNode('var', 'c'))
		assert.same(d1.list, l)
		assert.True(equalDeriv(d1, l))
	end)
	
	test("Making two derivations with choice", function()
		local g = [[s <- 'a' b / b c
			            b <- c
		              c <- 'c']]
		g = parser.match(g)
		
		local d1 = deriv.new(g)
		d1:step()
		d1:step()
		
		local d2 = deriv.new(g)
		d2:step(2)
		assert.same(d1, d2)
		
		local l1 = list.new(newNode('char', 'a'), newNode('var', 'c'))
		local l2 = list.new(newNode('var', 'c'), newNode('var', 'c'))
		assert.is_one_of(d1, l1, l2)
		
		-- Simple assert, without creating list
		assert.is_one_of(d1, "'a' c", "c c")
	end)
	
	
	test("Making three derivations with choice", function()
		local g = [[s <- 'a' b / b c
		            b <- c
		            c <- 'c']]
		g = parser.match(g)
		
		local d = deriv.new(g)
		d:step(3)
		
		assert.is_one_of(d, "'a' 'c'", "'c' c")
	end)
	
	test("Making three derivations with choice", function()
		local g = [[s <- 'a' b / b c
		            b <- c / D
		            c <- 'c'
		            D <- 'd']]
		g = parser.match(g)
		
		local d = deriv.new(g)
		d:step(3)
		
		local s1 = "'a' 'c'"
		local s2 = "'a' D"
		local s3 = "'c' c"
		local s4 = "D 'c'"
		assert.is_one_of(d, s1, s2, s3, s4)
	end)
	
end)
