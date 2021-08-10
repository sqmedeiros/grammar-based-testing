local set = require"set"
local parser = require"parser"

local First = { prefixLex  = "___",
								empty      = "__empty",
								any        = "__any" ,
								endInput   = "__$",
								beginInput = "__@" }
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
	assert(parser.isLexRule(var), tostring(var))
	return self.prefixLex .. var
end

function First:initSetFromGrammar (name)
	self[name] = {}
	local tab = self[name]
	for _, v in pairs(self.grammar.plist) do
		tab[v] = set.new()
	end
end


function First:calcFirstG ()
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
			local newFirst = self:calcFirstExp(exp)
			if not newFirst:equal(FIRST[var]) then
        update = true
	      FIRST[var] = FIRST[var]:union(newFirst)
			end
    end
	end

	return FIRST
end


function First:calcFirstExp (exp)
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
			firstChoice = firstChoice:union(self:calcFirstExp(v))
		end
		
		return firstChoice
	elseif exp.tag == 'con' then
		local firstSeq = self:calcFirstExp(exp.p1[1])
		local i = 2
		
		while firstSeq:getEle(self.empty) == true and i <= #exp.p1 do
			local firstNext = self:calcFirstExp(exp.p1[i])
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
		return set.new(self.FIRST[exp.p1].tab, 'fromKey')
	--elseif p.tag == 'throw' then
	--	return { [empty] = true }
	--elseif p.tag == 'and' then
	--	return { [empty] = true }
	--elseif p.tag == 'not' then
	--	return { [empty] = true }
  -- in a well-formed PEG, given p*, we know p does not match the empty string
	elseif exp.tag == 'opt' or exp.tag == 'star' then 
		return self:calcFirstExp(exp.p1):union(set.new{self.empty})
  elseif exp.tag == 'plus' then
		return self:calcFirstExp(exp.p1)
	else
		print(exp, exp.tag, exp.empty, exp.any)
		error("Unknown tag: " .. exp.tag)
	end
end


function First:calcFollowG ()
	local update = true
	local grammar = self.grammar
	local FOLLOW = self.FOLLOW

	FOLLOW[self.grammar.init] = set.new{ self.endInput }

	while update do
    update = false

    local oldFOLLOW = {}
    for k, v in pairs(FOLLOW) do
			oldFOLLOW[k] = v
    end

    for i, var in ipairs(grammar.plist) do
			local exp = grammar.prules[var]
			if parser.isLexRule(var) then
				exp = parser.newNode('var', var)
			end
			self:calcFollowExp(exp, FOLLOW[var])
		end

		for i, var in ipairs(grammar.plist) do
			if not FOLLOW[var]:equal(oldFOLLOW[var]) then
        update = true
				break
			end
    end
	end

	return FOLLOW
end


function First:firstWithoutEmpty (set1, set2)
	assert(not set2:getEle(self.empty), set2:tostring() .. ' || ' .. set1:tostring())
	if set1:getEle(self.empty) then
		set1:remove(self.empty)
		return set1:union(set2)
	else
		return set1
	end
end


function First:calcFollowExp (exp, flw)
	if exp.tag == 'empty' or exp.tag == 'char' or exp.tag == 'any' then
		return
	elseif exp.tag == 'var' then
    self.FOLLOW[exp.p1] = self.FOLLOW[exp.p1]:union(flw)
  elseif exp.tag == 'con' then
		local n = #exp.p1
		for i = n, 1, -1 do
			local iExp = exp.p1[i]
			self:calcFollowExp(iExp, flw)
			local firstIExp = self:calcFirstExp(iExp)
			flw = self:firstWithoutEmpty(firstIExp, flw)
		end
  elseif exp.tag == 'ord' then
		for i, v in ipairs(exp.p1) do
			self:calcFollowExp(v, flw)
		end
  elseif exp.tag == 'star' or exp.tag == 'plus' then
		local firstInnerExp = self:calcFirstExp(exp.p1)
		firstInnerExp:remove(self.empty)
		self:calcFollowExp(exp.p1, firstInnerExp:union(flw))
  elseif exp.tag == 'opt' then
    self:calcFollowExp(exp.p1, flw)
  else
		print(exp, exp.tag, exp.empty, exp.any)
		error("Unknown tag: " .. exp.tag)
	end
end


function First:calcLastG ()
	local update = true
	local grammar = self.grammar
	local LAST = self.LAST

	while update do
    update = false
    for i, var in ipairs(grammar.plist) do
			local exp = grammar.prules[var]
			if parser.isLexRule(var) then
				exp = parser.newNode('var', var)
			end
			local newLast = self:calcLastExp(exp)

			if not newLast:equal(LAST[var]) then
        update = true
	      LAST[var] = LAST[var]:union(newLast)
			end
    end
	end

	return LAST
end


function First:calcLastExp (exp)
	if exp.tag == 'empty' then
		return set.new{ self.empty }
	elseif exp.tag == 'char' then
    return set.new{ exp.p1 }
	elseif exp.tag == 'any' then
		return set.new{ self.any }
	--elseif p.tag == 'set' then
	--	return unfoldset(p.p1)
	elseif exp.tag == 'ord' then
		local lastChoice = set.new()
		local n = #exp.p1

		for i = n, 1, -1 do
			local iExp = exp.p1[i]
			lastChoice = lastChoice:union(self:calcLastExp(iExp))
		end

		return lastChoice
	elseif exp.tag == 'con' then
		local n = #exp.p1
		local lastSeq = self:calcLastExp(exp.p1[n])
		local i = n - 1

		while i >= 1 and lastSeq:getEle(self.empty) == true do
			local lastExp = self:calcLastExp(exp.p1[i])
			lastSeq = lastSeq:union(lastExp)
			if not lastExp:getEle(self.empty) then
				lastSeq:remove(self.empty)
			end
			i = i - 1
		end

		return lastSeq
	elseif exp.tag == 'var' then
		if parser.isLexRule(exp.p1) then
			return set.new{ self:lexKey(exp.p1) }
		end
		return set.new(self.LAST[exp.p1].tab, 'fromKey')
	--elseif p.tag == 'throw' then
	--	return { [empty] = true }
	--elseif p.tag == 'and' then
	--	return { [empty] = true }
	--elseif p.tag == 'not' then
	--	return { [empty] = true }
  -- in a well-formed PEG, given p*, we know p does not match the empty string
  elseif exp.tag == 'star' or exp.tag == 'opt' then
		local setEmpty = set.new{ self.empty }
		local repExp = self:calcLastExp(exp.p1)
		return setEmpty:union(repExp)
  elseif exp.tag == 'plus' then
		return self:calcLastExp(exp.p1)
	else
		print(exp, exp.tag, exp.empty, exp.any)
		error("Unknown tag: " .. exp.tag)
	end
end


function First:calcPrecedeG ()
	local update = true
	local grammar = self.grammar
	local PRECEDE = self.PRECEDE

	PRECEDE[self.grammar.init] = set.new{ self.beginInput }

	while update do
    update = false

    local oldPRECEDE = {}
    for k, v in pairs(PRECEDE) do
			oldPRECEDE[k] = v
    end

    for i, var in ipairs(grammar.plist) do
			local exp = grammar.prules[var]
			if parser.isLexRule(var) then
				exp = parser.newNode('var', var)
			end
			self:calcPrecedeExp(exp, PRECEDE[var])
		end

		for i, var in ipairs(grammar.plist) do
			if not PRECEDE[var]:equal(oldPRECEDE[var]) then
        update = true
				break
			end
    end
	end

	return PRECEDE
end


function First:calcPrecedeExp (exp, pre)
	if exp.tag == 'empty' or exp.tag == 'char' or exp.tag == 'any' then
		return
	elseif exp.tag == 'var' then
    self.PRECEDE[exp.p1] = self.PRECEDE[exp.p1]:union(pre)
  elseif exp.tag == 'con' then
		local n = #exp.p1
		for i = 1, n do
			local iExp = exp.p1[i]
			self:calcPrecedeExp(iExp, pre)
			local lastIExp = self:calcLastExp(iExp)
			pre = self:firstWithoutEmpty(lastIExp, pre)
		end
  elseif exp.tag == 'ord' then
		for i, v in ipairs(exp.p1) do
			self:calcPrecedeExp(v, pre)
		end
  elseif exp.tag == 'star' or exp.tag == 'plus' then
		local lastInnerExp = self:calcLastExp(exp.p1)
		lastInnerExp:remove(self.empty)
		self:calcPrecedeExp(exp.p1, lastInnerExp:union(pre))
  elseif exp.tag == 'opt' then
    self:calcPrecedeExp(exp.p1, pre)
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
