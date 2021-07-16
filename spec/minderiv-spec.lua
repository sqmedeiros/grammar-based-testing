local minderiv = require'minderiv'
local parser = require'parser'
local list = require'list'
local say = require'say'

local newNode = parser.newNode
local newSeq = parser.newSeq

local function getSubtable (tab, field)
	local newTab = {}
	for k, v in pairs(tab) do
		newTab[k] = v[field]
	end
	return newTab
end


local function is_one_of (state, args)
	local s = args[1]
	
	for i = 2, #args do
		local v = args[i]
		if s == v then
			return true
		end
	end
	
	return false
end

say:set("assertion.is_one_of.positive", "%s should be equal to one of the supplied expressions")
say:set("assertion.is_one_of.negative", "%s should not be equal to none of the supplied expressions")
assert:register("assertion", "is_one_of", is_one_of, "assertion.is_one_of.positive", "assertion.is_one_of.negative")



describe("Testing #minderiv", function()
	
	
	test("Calculate minimum derivation 0", function()
		local g = [[s <- 'a' / 'c']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		local minD = d:calcMinDeriv()
		
		assert.same(getSubtable(minD, "n"), { s = 1 })
		local words = getSubtable(minD, "w") 
		
		--as the alternatives are tried in order, we actually know what is the minimum derivation
		assert.is_one_of(words.s, "a", "c")
	end)
	
	
	test("Calculate minimum derivation 1", function()
		local g = [[s <- 'a' b / b c
		            b <- c
		            c <- 'c']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		local minD = d:calcMinDeriv()
		
		assert.same(getSubtable(minD, "n"), { c = 1, b = 2, s = 3 })
		local words = getSubtable(minD, "w") 
		
		assert.is_one_of(words.s, "a c", "c c")
		assert.same(words.b, "c")
		assert.same(words.c, "c")
	end)
	
	test("Calculate minimum derivation 2", function()
		local g = [[s <- 'a' b / b c
		            b <- c / D
		            c <- 'c'
		            D <- 'd']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		local minD = d:calcMinDeriv()
		
		assert.same(getSubtable(minD, "n"), { D = 1, c = 1, b = 2, s = 3 })
		local words = getSubtable(minD, "w") 
		
		assert.is_one_of(words.s, "a c", "c d", "c c", "d c")
		--as the alternatives are tried in order, we actually know what is the minimum derivation
		assert.same(words.s, "a c")
		assert.is_one_of(words.b, "c", "d")
		assert.same(words.c, "c")
		assert.same(words.D, "d")
	end)
	
	test("Calculate minimum derivation 3", function()
		local g = [[s <- 'a' b / b c / 'e'
		            b <- c b / D / E
		            c <- 'c' b
		            D <- 'd'
		            E <- 'x']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		local minD = d:calcMinDeriv()
		
		assert.same(getSubtable(minD, "n"), { E = 1, D = 1, c = 3, b = 2, s = 1 })
		local words = getSubtable(minD, "w") 
		
		assert.same(words.s, "e")
		assert.is_one_of(words.b, "d", "x")
		assert.is_one_of(words.c, "c d", "c x")
		assert.same(words.D, "d")
		assert.same(words.E, "x")
	end)
	
	test("Calculate a minimum derivation where non-terminal A is rewritten in a specific way", function()
		local g = [[s <- 'a' b / b c / 'e'
		            b <- c b / D / E
		            c <- 'c' b
		            D <- 'd'
		            E <- 'x']]
		g = parser.match(g)

		local d = minderiv.new(g)
		local minD = d:calcMinDeriv()
		
		-- s should be rewritten in a way that non-terminal b appears
		local pairCov = { s = parser.newNode('var', 'b') }
		local entry = d:getMinDeriv(parser.newNode('var', 's'), pairCov)
		assert.True(entry.w == "d")
		
		-- first choice of rule s
		pairCov['s'] = g.prules['s'].p1[1]
		entry = d:getMinDeriv(parser.newNode('var', 's'), pairCov)
		assert.True(entry.w == "a d")

		--second choice of rule s
		pairCov['s'] = g.prules['s'].p1[2]
		entry = d:getMinDeriv(parser.newNode('var', 's'), pairCov)
		assert.True(entry.w == "d c d")
		
		-- D -> E
		pairCov['D'] = g.prules['E']
		-- exp = c D
		local exp = parser.newSeq(newNode('var', 'c'), newNode('var', 'D'))
		entry = d:getMinDeriv(exp, pairCov)
		assert.True(entry.w == "c d x")
	end)


	test("Build graph", function()
		local g = [[s <- 'a' b / b c
		            b <- c / D
		            c <- 'c'
		            D <- 'd']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		d:calcMinDeriv()
		local graph = d:buildGraph()

		-- graph[A][B].n = length of the mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'n'), { b = 1, c = 1})
		assert.same(getSubtable(graph['b'], 'n'), { c = 1, D = 1})
		assert.same(getSubtable(graph['c'], 'n'), { })
		assert.same(getSubtable(graph['D'], 'n'), { })

		-- graph[A][B].w = sentential form we get after a mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'w'), { b = 'a c', c = 'c c'})
		assert.same(getSubtable(graph['b'], 'w'), { c = 'c', D = 'd'})
		assert.same(getSubtable(graph['c'], 'w'), { })
		assert.same(getSubtable(graph['D'], 'w'), { })

		-- graph[A][B].exp = expression we get after a mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'exp'), { b = newSeq(newNode('char', 'a'), newNode('var', 'b')),
		                                              c = newSeq(newNode('var', 'b'), newNode('var', 'c'))})
		assert.same(getSubtable(graph['b'], 'exp'), { c = newNode('var', 'c'), D = newNode('var', 'D')})
		assert.same(getSubtable(graph['c'], 'exp'), { })
		assert.same(getSubtable(graph['D'], 'exp'), { })
	end)
	
	
	test("Build graph: recursive rule", function()
		local g = [[s <- 'c' s / 'a' / b
		            b <- 'x' / 'y']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		d:calcMinDeriv()
		local graph = d:buildGraph()

		-- graph[A][B].n = length of the mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'n'), { s = 1, b = 1})
		assert.same(getSubtable(graph['b'], 'n'), { })

		-- graph[A][B].w = sentential form we get after a mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'w'), { s = 'c a', b = 'x'})
		assert.same(getSubtable(graph['b'], 'w'), { })

		-- graph[A][B].exp = expression we get after a mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'exp'), { s = newSeq(newNode('char', 'c'), newNode('var', 's')),
		                                              b = newNode('var', 'b')})
		assert.same(getSubtable(graph['b'], 'exp'), { })
	end)


	test("Graph min path", function()
		local g = [[s <- 'a' b / b c
		            b <- c / D
		            c <- 'c'
		            D <- 'd']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		d:calcMinDeriv()
		local graph = d:buildGraph()
		d:minDerivPath()
	end)

	--[==[			
	test("Minimal derivation", function()
		local g = [[s <- 'a' b / b c
		            b <- c / D
		            c <- 'c'
		            D <- 'd']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		local minDeriv = d:calcMinDeriv()

		assert.same({s = 3, b = 2, c = 1, D = 1}, getSubtable(minDeriv, 'n'))
		
		local minS = minDeriv["s"].w
		assert.True(minS == "a c" or minS == "a d" or minS == "c c" or minS == "d c")
		assert.True(minDeriv["b"].w == "c" or minDeriv["b"].w == "d")
		assert.True(minDeriv["c"].w == "c")
		assert.True(minDeriv["D"].w == "d")
		
	end)


	test("Derivable pair coverage", function()
		local g = [[s <- 'a' b / b c
		            b <- c / D
		            c <- 'c'
		            D <- 'd']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		d:buildGraph()
		d:pairCoverage()
	end)
		--]==]
end)
