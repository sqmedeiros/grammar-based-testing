local parser = require'parser'
local pretty = require'pretty'
local deriv = require'deriv'

local MinDeriv = setmetatable({}, {__index = deriv} )
MinDeriv.__index = MinDeriv

function MinDeriv.new(grammar)
	local self = deriv.new(grammar)
	self = setmetatable(self, MinDeriv)
	self.minDeriv = {}
	self.graph = {}
	self.coverage = {}
	--self.coverage = self:pairCoverage()	
	return self
end


function MinDeriv:calcMinDeriv ()
	local minDeriv = self.minDeriv
	local g = self.grammar
	for i, v in ipairs(g.plist) do
		local rhs = g.prules[v]
		if not parser.isDerivable(rhs) then
			--minDeriv[v] = { n = 1, w = pretty.toString(rhs) }
			local expMin = self:getMinDeriv(rhs)
			if expMin.n and expMin.w then
				minDeriv[v] = { n = 1, w = expMin.w }
			elseif not minDeriv[v] then
				minDeriv[v] = { }
			end
		else
			minDeriv[v] = { }
		end
	end
	
	local changed = true
	while changed do
		changed = false
		for i, v in ipairs(g.plist) do
			local rhs = g.prules[v]
			local t = self:getMinDeriv(rhs)
			if t.n and (not minDeriv[v].n or t.n + 1 < minDeriv[v].n) then
				minDeriv[v] = { n = t.n + 1, w = t.w }
				changed = true
			end
		end
	end
	
	return minDeriv
end


function MinDeriv:getMinDeriv (p, pairCov)
	local minDeriv = self.minDeriv
	assert(minDeriv)
	
	if p.tag == 'char' then
		return { n = 0, w = pretty.toString(p) }
	elseif p.tag == 'var' then
		if pairCov and pairCov[p.p1] then
			-- pass an empty pairCov after doing the substitution
			return self:getMinDeriv(pairCov[p.p1], {})
		else
		  --assert(minDeriv and minDeriv[p.p1], "Grammar does not have var " .. p.p1)
			return minDeriv[p.p1] or {}
		end
	elseif p.tag == 'con' then
		local n = 0
		local w = ""
		for i, v in ipairs(p.p1) do
			local t = self:getMinDeriv(v, pairCov)
			assert(t, v)
			if not t.n then
				return { n = nil, w = nil }
			end
			n = n + t.n
			if i == 1 then
				w = t.w
			else
				w = w .. ' ' .. t.w
			end
		end
		return { n = n, w = w }
	elseif p.tag == 'ord' then
		local n = nil
		local w = nil
		for i, v in ipairs(p.p1) do
			local t = self:getMinDeriv(v, pairCov)
			if t and t.n and (not n or t.n < n) then
				n = t.n
				w = t.w
				assert(t.w)
			end
		end
		return { n = n, w = w }
	elseif p.tag == 'star' or p.tag == 'opt' or p.tag == 'plus' then
		assert(false, "star " .. tostring(p.tag))
	else
		assert(false, "none " .. tostring(p.tag))
	end
end


function MinDeriv:printGraph(graph)
	local grammar = self.grammar
	local graph = self.graph
	for _, v1 in ipairs(grammar.plist) do
		io.write(v1 .. ": ")
		for _, v2 in ipairs(grammar.plist) do
			if graph[v1][v2] then
				local entry = graph[v1][v2]
				io.write(v2 .. '(' .. entry.n .. ';' .. entry.w .. ';' .. pretty.printp(entry.exp) .. '), ')
			end
		end
		io.write("\n")
	end
end


-- conExp is an array concatenation
-- p is any expression that we want to concatenate to conExp
function MinDeriv:addConExp (conExp, p)
	local n = #conExp.p1
	if p.tag == 'char' or p.tag == 'var' then
		conExp.p1[n + 1] = p
	elseif p.tag == 'con' then
		for i, v in ipairs(p.p1) do
			self:addConExp(conExp, v)
		end
	elseif p.tag == 'ord' then
		assert(false, "Unexpected ord expression " .. tostring(p.tag)) 
	else
		assert(false, "Unexpected expression " .. tostring(p.tag)) 
	end
	
	return conExp
end


-- make a concatenation with expressions p1 and p2
-- p1 and p2 are any expression
function MinDeriv:conExp (p1, p2)
	local newCon = parser.newNode('con', {})
	self:addConExp(newCon, p1)
	self:addConExp(newCon, p2)
	return newCon
end


function MinDeriv:newReplaceNonTerm (exp, var, varRHS)
	--print("replaced ", pretty.printp(exp), var, pretty.printp(varRHS))
	if exp.tag == 'var' and exp.p1 == var then
		return varRHS
	elseif exp.tag == 'var' or exp.tag == 'char' then
		return exp
	elseif exp.tag == 'con' then
		local newExp = self:newReplaceNonTerm(exp.p1[1], var, varRHS)
		for i = 2, #exp.p1 do
			local p2 = self:newReplaceNonTerm(exp.p1[i], var, varRHS)
			newExp = self:conExp(newExp, p2)
		end
		return newExp
	elseif exp.tag == 'ord' then
		assert(false, "Invalid ord expression " .. tostring(exp.tag))
	else
		assert(false, "Invalid expression " .. tostring(exp.tag))
	end
end


function MinDeriv:minDerivPath ()
	local graph = self.graph
	local grammar = self.grammar
	
	--Floyd-Warshall algorithm
	--Calculates minimum amount of derivations to get non-terminal v2 from non-terminal v1
	-- n: minimum amount of derivations
	-- w: minimum sentential form, i.e., v1 -min-> pA v2 pB -min-> w
	-- exp: expression we get after rewriting v1, i.e., v1 -min-> pA v2 pB
	for _, v1 in ipairs(grammar.plist) do
		for _, v2 in ipairs(grammar.plist) do
			for _, v3 in ipairs(grammar.plist) do
				if graph[v1][v3] and graph[v3][v2] then
					local newPath = graph[v1][v3].n + graph[v3][v2].n
					if not graph[v1][v2] or graph[v1][v2].n > newPath then
						--local newExp = parser.newSeq(graph[v1][v3].exp, graph[v3][v2].exp)
						--local newWord = graph[v1][v3].w .. ' ' .. graph[v3][v2].w
						--print("v1: ", v1, ", v3: ", v3, ", v2", v2)
						--print(pretty.printp(graph[v1][v3].exp), pretty.printp(graph[v3][v2].exp))
						local newWord = self:getMinDeriv(graph[v1][v3].exp, { v3 = graph[v3][v2].exp })
						local newExp = self:newReplaceNonTerm(graph[v1][v3].exp, v3, graph[v3][v2].exp)
						newWord = self:getMinDeriv(newExp)
						graph[v1][v2] = { n = newPath, w = newWord.w, exp = newExp }
					end
				end
			end
		end
	end
	
	--self:printGraph()
	return graph
end


function MinDeriv:pairCoverage ()
	local graph = self.graph
	local grammar = self.grammar
	local coverage = self.coverage
	local vInit = grammar.init
	
	local newNode = parser.newNode
	for _, v1 in ipairs(grammar.plist) do
		coverage[v1] = {}
		for _, v2 in ipairs(grammar.plist) do
			if graph[v1][v2] then
				local exp
				local pairCov = { [v1] = graph[v1][v2].exp }
				if vInit == v1 then
					exp = graph['s'][v2].exp
					-- checks whether v2 was already generated
					local has, _ = parser.hasSymbol(exp, v2)
					if has then -- do not need to generate v2 again
						pairCov = {}
					end
				else
				 	exp = graph['s'][v1].exp
				end
				--print("derivPairCoverage (" .. v1 .. "," .. v2 .. "): " .. pretty.printp(exp))
				local newW = self:getMinDeriv(exp, pairCov).w
				--print("derivPairCoverage w", newW)
				coverage[v1][v2] = newW
			end
		end
	end
	
	return coverage
end

function MinDeriv:buildGraph ()
	local graph = self.graph
	local grammar = self.grammar
	local minDeriv = self.minDeriv
	
	for i, v in ipairs(grammar.plist) do
		graph[v] = {}
	end
	
	for _, v1 in ipairs(grammar.plist) do
		local rhs = grammar.prules[v1]
		for _, v2 in ipairs(grammar.plist) do
			local has, exp = parser.hasSymbol(rhs, v2)
			if has then
				--print(v1 .. " -> " .. v2)
				local res = self:getMinDeriv(exp)
				--print("buildGraph ", res.n, res.w, pretty.printp(exp))
				graph[v1][v2] = { n = 1, w = res.w, exp = exp }
			end
		end
	end
	
	return graph
end


return MinDeriv
