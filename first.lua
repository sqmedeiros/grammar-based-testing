local set = require"set"
local parser = require"parser"

local First = { prefixLex = "___",
								empty     = "__empty",
								any       = "__any" }
First.__index = First

function First.new (grammar)
	local self = {}
	setmetatable(self, First)
	self:setGrammar(grammar)
	return self
end


function First:setGrammar(grammar)
	self.grammar = grammar
	self:initSetFromGrammar("FIRST")
	self:initSetFromGrammar("LAST")
	self:initSetFromGrammar("FOLLOW")
	self:initSetFromGrammar("PRECEDE")
end


function First:lexKey (var)
	assert(parser.isLexRule(var))
	return self.prefixLex .. var
end

function First:initSetFromGrammar (name)
	self[name] = {}
	local tab = self[name]
	for _, v in pairs(self.grammar.plist) do
		tab[v] = set.new()
	end
end


function First:calcFstG ()	
	local update = true
	local grammar = self.grammar
	local FIRST = self.FIRST
	
	while update do
    update = false
    for i, var in ipairs(grammar.plist) do
			local exp = grammar.prules[var]
			if parser.isLexRule(var) then
				exp = parser.newNode('var', var)
			end
			local newFirst = self:calcFstExp(exp)
			if FIRST[var]:equal(newFirst) == false then
        update = true
	      FIRST[var] = FIRST[var]:union(newFirst)
			end
    end
	end

	return FIRST
end


function First:calcFstExp (exp)
	if exp.tag == 'empty' then
		return set.new{ self.empty }
	elseif exp.tag == 'char' then
    return set.new{ exp.p1 }
	elseif exp.tag == 'any' then
		return set.new{ self.any }
	--elseif p.tag == 'set' then
	--	return unfoldset(p.p1)
	elseif exp.tag == 'ord' then
		local firstChoice = set.new()
		
		for i, v in ipairs(exp.p1) do
			firstChoice = firstChoice:union(self:calcFstExp(v))
		end
		
		return firstChoice
	elseif exp.tag == 'con' then
		local firstSeq = self:calcFstExp(exp.p1[1])
		local i = 2
		
		while firstSeq:getEle(self.empty) == true and i <= #exp.p1 do
			local firstNext = self:calcFstExp(exp.p1[i])
			firstSeq = firstSeq:union(firstNext)
			if not firstNext:getEle(self.empty) then
				firstSeq:remove(self.empty)
			end
			i = i + 1
		end
		
		return firstSeq
	elseif exp.tag == 'var' then
		if parser.isLexRule(exp.p1) then
			return set.new{ self:lexKey(exp.p1) }
		end
		return self.FIRST[exp.p1]
	--elseif p.tag == 'throw' then
	--	return { [empty] = true }
	--elseif p.tag == 'and' then
	--	return { [empty] = true }
	--elseif p.tag == 'not' then
	--	return { [empty] = true }
  -- in a well-formed PEG, given p*, we know p does not match the empty string
	elseif exp.tag == 'opt' or exp.tag == 'star' then 
		return self:calcFstExp(exp.p1):union(set.new{self.empty})
  elseif exp.tag == 'plus' then
		return self:calcFstExp(exp.p1)
	else
		print(exp, exp.tag, exp.empty, exp.any)
		error("Unknown tag: " .. exp.tag)
	end
end


function First:tostring(setName, var)
	local grammar = self.grammar
	--for i, v in pairs
end

return First
