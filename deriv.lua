local list = require'list'
local parser = require'parser'
local math = require'math'
local os = require'os'
local pretty = require'pretty'

local Deriv = {}
Deriv.__index = Deriv

local isDeriv = function(x) return parser.isDerivable(x) end

function Deriv.new(grammar)
	local varInit = parser.newNode('var', grammar.plist[1])
	math.randomseed(os.time())
	return setmetatable({
		grammar = grammar,
		list = list.new(varInit),
	}, Deriv)
end


function Deriv:nextNonTerm ()
	local fn = isDeriv
	return self.list:find("", fn)
end


function Deriv:isSententialForm ()
	local fn = isDeriv
	return not self.list:contains("", fn)
end


function Deriv:replaceNonTerm (rhs)	
	if rhs.tag == 'ord' then
		local n = #rhs.p1
		local exp = rhs.p1[math.random(n)]
		return self:replaceNonTerm(exp)			
	elseif rhs.tag == 'con' then
		return table.unpack(rhs.p1)
	elseif rhs.tag == 'var' or rhs.tag == 'char' then
		return rhs
	else
		assert(false, "Invalid expression " .. tostring(rhs.tag))
	end
end


function Deriv:rec_step(l)	
	if l:isEmpty() then
		return false
	end
	
	local head = l:head()
	
	if parser.isDerivSimp(head) then
		local rhs = self.grammar.prules[head.p1]
		l:replace(head, self:replaceNonTerm(rhs))
		return true	 	
	else
		return self:rec_step(l:tail())
	end
end


function Deriv:step(n)
	n = n or 1
	for i = 1, n do
		if not self:rec_step(self.list) then
			break
		end
	end
end


function Deriv:toString()
	return self.list:toString()	
end


return Deriv
