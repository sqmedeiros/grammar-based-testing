local say = require'say'
local m = require'parser'
local errinfo = require'syntax_errors'
local pretty = require'pretty'

local function has_label (state, args)
	local g = args[1]
	local lab = args[2]
	local r, msg, pos = m.match(g)
	local errMsg = errinfo[lab]
	if not errMsg then
		return false
	end
	if r then 
		pretty.printg(r, msg) 
		return false	
	end
	return string.find(msg, errMsg, 1, true) ~= nil
end

say:set("assertion.has_label.positive", "Expected fail the matching of %s \nwith label %s")
say:set("assertion.has_label.negative", "Expected not fail the matching of %s \nwith label %s")
assert:register("assertion", "has_label", has_label, "assertion.has_label.positive", "assertion.has_label.negative")


describe("Grammar parser", function()
	
	
	describe("Syntactically #invalid grammars", function()	
		test("Extra input after a valid grammar", function()
			assert.has_label([[a <- 'b'  3]], 'Extra')
		end)
		
		test("Grammar with no rules", function()
		  assert.has_label([[a <- 'b'  3]], 'Extra')
		end)
		
		test("Invalid expression in rule right-hand side", function()
		  assert.has_label([[a <- ]], 'ExpRule')
		end)
		
		test("Missing '<-' in a grammar rule", function()
		  assert.has_label([[a ]], 'Arrow')
		end)

		test("Invalid expression in choice alternative", function()
		  assert.has_label([[a <- 'b' / 3]], 'SeqExp')
		end)

		test("Invalid expression in AND predicate", function()
		  assert.has_label([[a <- 'b' / 3]], 'SeqExp')
		end)
		
		test("Invalid expression in AND predicate", function()
		  assert.has_label([[a <- 'b'& ]], 'AndPred')
		end)

		test("Invalid expression in NOT predicate", function()
		  assert.has_label([[a <- ! ]], 'NotPred')
		end)

		test("Invalid expression inside parentheses", function()
		  assert.has_label([[a <- () ]], 'ExpPri')
		end)

		test("Missing ')'", function()
		  assert.has_label([[a <- ( 'b' ]], 'RParPri')
		end)

		test("Missing \'", function()
		  assert.has_label([[a <- ( 'b" ]], 'SingQuote')
		end)
		
		test("Missing \"", function()
		  assert.has_label([[a <- ( "b' ]], 'DoubQuote')
		end)
		
		test("Empty character class", function()
		  assert.has_label([[a <- []], 'EmptyClass')
		end)
		
		test("Missing ']'", function()
		  assert.has_label([[a <- [a-z]], 'RBraClass')
		end)

		test("Missing label name in throw expression", function()
		  assert.has_label([[a <- %{ } ]], 'NameThrow')
		end)

		test("Missing '}'", function()
		  assert.has_label([[a <- %{ ops ]], 'RCurThrow')
		end)
		
		test("Undefined non-terminal", function()
			local errFunction = function()
				m.match([[a <- 'a' b]])
			end
			assert.has_error(errFunction, "Rule 'b' was not defined")
		end)
		
	end)
	
	describe("Testing isDerivable", function()	
		test("Non-derivable expression", function()
			assert.False(m.isDerivable(m.newNode('var', 'S')))
		end)
	
		test("Derivable expression", function()
			assert.True(m.isDerivable(m.newNode('var', 's')))
		end)
	end)
	
	describe("Checking the AST of valid grammars", function()
		test("Derivable expression", function()
			local g = m.match([[a <- 'a']])
			local s = pretty.printp(g.prules['a'])
			assert.equal(s, "'a'")
			
			local g = m.match([[a <- 'a' b
			                    b <- 'c']])
			local s = pretty.printp(g.prules['a'])
			assert.equal(s, "'a' b")
		end)
	end)
	
	describe("Testing hasSymbol", function()	
		local g = [[s <- 'a' b / b c
		            b <- c / D
		            c <- 'c'
		            D <- 'd']]
		g = m.match(g)
		
		local hasSymbol = m.hasSymbol
		local rhsS = g.prules['s']
		assert.False(hasSymbol(rhsS, 's'))
		assert.False(hasSymbol(rhsS, 'D'))
		assert.False(hasSymbol(rhsS, 'a'))
		assert.True(hasSymbol(rhsS, 'a', true))
		assert.True(hasSymbol(rhsS, 'b'))
		assert.True(hasSymbol(rhsS, 'c'))
		
		local rhsB = g.prules['b']
		assert.False(hasSymbol(rhsB, 's'))
		assert.True(hasSymbol(rhsB, 'D'))
		assert.False(hasSymbol(rhsB, 'a'))
		assert.False(hasSymbol(rhsB, 'b'))
		assert.True(hasSymbol(rhsB, 'c'))
		
		local rhsC = g.prules['c']
		assert.False(hasSymbol(rhsC, 'b'))
		assert.False(hasSymbol(rhsC, 'b', true))
		assert.False(hasSymbol(rhsC, 'c'))
		assert.True(hasSymbol(rhsC, 'c', true))
		
		local rhsD = g.prules['D']
		assert.False(hasSymbol(rhsD, 'd'))
		assert.True(hasSymbol(rhsD, 'd', true))
	end)
	
	
end)
