local mutate = require'mutate'
local parser = require'parser'

describe("Testing Rule Mutation", function()

	test("Removing non-terminals", function()
		local g = parser.match[[
			s   <-  A B / C D / a D B
			a   <- C / A
			A   <- 'a'
			B   <- 'b'
			C   <- 'c'
			D   <- 'd'
		]]
		
		local mut = mutate.new(g)
		mut:mutateG()
	end)
end)
