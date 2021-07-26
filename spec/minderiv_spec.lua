local minderiv = require'minderiv'
local parser = require'parser'
local list = require'list'
local say = require'say'

local newNode = parser.newNode
local newSeq = parser.newSeq

local function newChar (ch)
	return newNode('char', ch)
end

local function newVar (var)
	return newNode('var', var)
end

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

	
	test("Calculate minimum derivation 4", function()
		local g = [[s <- 'a' b / b c
		            b <- c F / 'x' b / D
		            c <- 'c' / E / D
		            D <- 'd' / 'd' b I
		            E <- 'e'
		            F <- 'f' G
		            G <- 'g'
		            H <- 'h'
		            I <- 'i' 'j']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		local minD = d:calcMinDeriv()
		
		assert.same(getSubtable(minD, "n"), { I = 1, H = 1, G = 1, F = 2, E = 1, D = 1, c = 1, b = 2, s = 3 })
		local words = getSubtable(minD, "w") 
		
		assert.same(words.s, "a d")
		assert.same(words.b, "d")
		assert.same(words.c, "c")
		assert.same(words.D, "d")
		assert.same(words.E, "e")
		assert.same(words.F, "f g")
		assert.same(words.G, "g")
		assert.same(words.H, "h")
		assert.same(words.I, "i j")
	end)
	
	
	test("Calculate a minimum derivation where non-terminal A is rewritten in a specific way 1", function()
		local g = [[s <- 'a' b / b c / 'e'
		            b <- c b / D / E
		            c <- 'c' b
		            D <- 'd'
		            E <- 'x']]
		g = parser.match(g)

		local d = minderiv.new(g)
		local minD = d:calcMinDeriv()
		
		-- s should be rewritten in a way that non-terminal b appears
		local pairCov = { s = newVar('b') }
		local entry = d:getMinDeriv(newVar('s'), pairCov)
		assert.True(entry.w == "d")
		
		-- first choice of rule s
		pairCov['s'] = g.prules['s'].p1[1]
		entry = d:getMinDeriv(newVar('s'), pairCov)
		assert.True(entry.w == "a d")

		--second choice of rule s
		pairCov['s'] = g.prules['s'].p1[2]
		entry = d:getMinDeriv(newVar('s'), pairCov)
		assert.True(entry.w == "d c d")
		
		-- D -> E
		pairCov['D'] = g.prules['E']
		-- exp = c D
		local exp = parser.newSeq(newVar('c'), newVar('D'))
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
		assert.same(getSubtable(graph['s'], 'exp'), { b = newSeq(newChar('a'), newVar('b')),
		                                              c = newSeq(newVar('b'), newVar('c'))})
		assert.same(getSubtable(graph['b'], 'exp'), { c = newVar('c'), D = newVar('D')})
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
		assert.same(getSubtable(graph['s'], 'exp'), { s = newSeq(newChar('c'), newVar('s')),
		                                              b = newVar('b')})
		assert.same(getSubtable(graph['b'], 'exp'), { })
	end)


	test("Graph min path #1", function()
		local g = [[s <- 'a' b / b c
		            b <- c / D
		            c <- 'c'
		            D <- 'd']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		d:calcMinDeriv()
		d:buildGraph()
		local graph = d:minDerivPath()
		
		-- graph[A][B].n = length of the mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'n'), { b = 1, c = 1, D = 2})
		assert.same(getSubtable(graph['b'], 'n'), { c = 1, D = 1})
		assert.same(getSubtable(graph['c'], 'n'), { })
		assert.same(getSubtable(graph['D'], 'n'), { })

		-- graph[A][B].w = sentential form we get after a mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'w'), { b = 'a c', c = 'c c', D = 'a d'})
		assert.same(getSubtable(graph['b'], 'w'), { c = 'c', D = 'd'})
		assert.same(getSubtable(graph['c'], 'w'), { })
		assert.same(getSubtable(graph['D'], 'w'), { })

		-- graph[A][B].exp = expression we get after a mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'exp'), { b = newSeq(newChar('a'), newVar('b')),
		                                              c = newSeq(newVar('b'), newVar('c')),
		                                              D = newSeq(newChar('a'), newVar('D'))})
		assert.same(getSubtable(graph['b'], 'exp'), { c = newVar('c'), D = newVar('D')})
		assert.same(getSubtable(graph['c'], 'exp'), { })
		assert.same(getSubtable(graph['D'], 'exp'), { })
	end)

	test("Graph min path #2", function()
		local g = [[s <- 'a' b / b c
		            b <- c F / 'x' b / D
		            c <- 'c' / E / D
		            D <- 'd' / 'd' b I
		            E <- 'e'
		            F <- 'f' G
		            G <- 'g'
		            H <- 'h'
		            I <- 'i']]
		g = parser.match(g)
		
		local d = minderiv.new(g)
		d:calcMinDeriv() 
		d:buildGraph() 
		local graph = d:minDerivPath()
		
		-- graph[A][B].n = length of the mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'n'), { b = 1, c = 1, D = 2, E = 2, F = 2, G = 3, I = 3 })
		assert.same(getSubtable(graph['b'], 'n'), { b = 1, c = 1, D = 1, E = 2, F = 1, G = 2, I = 2})
		assert.same(getSubtable(graph['c'], 'n'), { b = 2, c = 3, D = 1, E = 1, F = 3, G = 4, I = 2})
		assert.same(getSubtable(graph['D'], 'n'), { b = 1, c = 2, D = 2, E = 3, F = 2, G = 3, I = 1})
		assert.same(getSubtable(graph['E'], 'n'), { })
		assert.same(getSubtable(graph['F'], 'n'), { G = 1})
		assert.same(getSubtable(graph['H'], 'n'), {  })
		assert.same(getSubtable(graph['I'], 'n'), {  })

		-- graph[A][B].w = sentential form we get after a mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'w'), { b = 'a d', c = 'd c', D = 'a d', E = 'd e', F = 'a c f g', G = 'a c f g', I = 'a d d i'})
		assert.same(getSubtable(graph['b'], 'w'), { b = 'x d', c = 'c f g', D = 'd', E = 'e f g', F = 'c f g', G = 'c f g', I = 'd d i'})
		assert.same(getSubtable(graph['c'], 'w'), { b = 'd d i', c = 'd c f g i', D = 'd', E = 'e', F = 'd c f g i', G = 'd c f g i', I = 'd d i'})
		assert.same(getSubtable(graph['D'], 'w'), { b = 'd d i', c = 'd c f g i', D = 'd d i', E = 'd e f g i', F = 'd c f g i', G = 'd c f g i', I = 'd d i'})
		assert.same(getSubtable(graph['E'], 'w'), {  })
		assert.same(getSubtable(graph['F'], 'w'), { G = 'f g'})
		assert.same(getSubtable(graph['H'], 'w'), {  })
		assert.same(getSubtable(graph['I'], 'w'), {  })


		-- graph[A][B].exp = expression we get after a mininum derivation from A to B
		assert.same(getSubtable(graph['s'], 'exp'), {
			b = newSeq(newChar'a', newVar'b'),
			c = newSeq(newVar'b', newVar'c'),
			D = newSeq(newChar'a', newVar'D'),
			E = newSeq(newVar'b', newVar'E'),
			F = newSeq(newChar'a', newVar'c', newVar'F'),
			G = newSeq(newChar'a', newVar'c', newChar'f', newVar'G'),
			I = newSeq(newChar'a', newChar'd', newVar'b', newVar'I')
		})		

		assert.same(getSubtable(graph['b'], 'exp'), {
			b = newSeq(newChar'x', newVar'b'),
			c = newSeq(newVar'c', newVar'F'),
			D = newVar'D',
			E = newSeq(newVar'E', newVar'F'),
			F = newSeq(newVar'c', newVar'F'),
			G = newSeq(newVar'c', newChar'f', newVar'G'),
			I = newSeq(newChar'd', newVar'b', newVar'I')
		})
		
		assert.same(getSubtable(graph['c'], 'exp'), {
			b = newSeq(newChar'd', newVar'b', newVar'I'),
			c = newSeq(newChar'd', newVar'c', newVar'F', newVar'I'),
			D = newVar'D',
			E = newVar'E',
			F = newSeq(newChar'd', newVar'c', newVar'F', newVar'I'),
			G = newSeq(newChar'd', newVar'c', newChar'f', newVar'G', newVar'I'),
			I = newSeq(newChar'd', newVar'b', newVar'I')
		})
		
		assert.same(getSubtable(graph['D'], 'exp'), {
			b = newSeq(newChar'd', newVar'b', newVar'I'),
			c = newSeq(newChar'd', newVar'c', newVar'F', newVar'I'),
			D = newSeq(newChar'd', newVar'D', newVar'I'),
			E = newSeq(newChar'd', newVar'E', newVar'F', newVar'I'),
			F = newSeq(newChar'd', newVar'c', newVar'F', newVar'I'),
			G = newSeq(newChar'd', newVar'c', newChar'f', newVar'G', newVar'I'),
			I = newSeq(newChar'd', newVar'b', newVar'I')
		})
		
		assert.same(getSubtable(graph['E'], 'exp'), { })
		assert.same(getSubtable(graph['F'], 'exp'), {
			G = newSeq(newChar'f', newVar'G')
		})
		assert.same(getSubtable(graph['H'], 'exp'), { })
		assert.same(getSubtable(graph['I'], 'exp'), { })		
	end)

			
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


	test("Derivable pair coverage 1", function()
		local g = [[s <- 'a' b / b c
		            b <- c / D
		            c <- 'c'
		            D <- 'd']]
		g = parser.match(g)
		local d = minderiv.new(g)
		d:calcMinDeriv()
		d:buildGraph()
		d:minDerivPath()
		local pairCov = d:pairCoverage()
		
		assert.same(pairCov['s'], {
			b = 'a c',
			c = 'c c',
			D = 'a d',
		})
		
		assert.same(pairCov['b'], {
			c = 'a c',
			D = 'a d',
		})
		
		assert.same(pairCov['c'], {})
		assert.same(pairCov['D'], {})
		
	end)
	
	test("Derivable pair coverage #coverage2", function()
		local g = [[s <- 'a' b / b c
		            b <- c F / 'x' b / D
		            c <- 'c' / E / D
		            D <- 'd' / 'd' b I
		            E <- 'e'
		            F <- 'f' G
		            G <- 'g'
		            H <- 'h'
		            I <- 'i']]
		g = parser.match(g)
		local d = minderiv.new(g)
		d:calcMinDeriv()
		d:buildGraph()
		d:minDerivPath()
		local pairCov = d:pairCoverage()
		
		assert.same(pairCov['s'], {
			b = 'a d',
			c = 'd c',
			D = 'a d',
			E = 'd e',
			F = 'a c f g',
			G = 'a c f g',
			I = 'a d d i',
		})
	
		
		assert.same(pairCov['b'], {
			b = 'a x d',
			c = 'a c f g',
			D = 'a d',
			E = 'a e f g',
			F = 'a c f g',
			G = 'a c f g',
			I = 'a d d i',
		})
		
		assert.same(pairCov['c'], {
			b = 'd d d i',
			c = 'd d c f g i',
			D = 'd d',
			E = 'd e',
			F = 'd d c f g i',
			G = 'd d c f g i',
			I = 'd d d i',
		})
	
	assert.same(pairCov['D'], {
			b = 'a d d i',
			c = 'a d c f g i',
			D = 'a d d i',
			E = 'a d e f g i',
			F = 'a d c f g i',
			G = 'a d c f g i',
			I = 'a d d i',
		})
		
	assert.same(pairCov['E'], {})
	assert.same(pairCov['F'], {
		G = 'a c f g',
	})
	assert.same(pairCov['G'], {})
	assert.same(pairCov['H'], {})
	assert.same(pairCov['I'], {})
		
	end)	
		
end)
