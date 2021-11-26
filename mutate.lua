local parser = require"parser"
local first = require"first"
local pretty = require"pretty"
local set = require"set"

local Mutate = {}
Mutate.__index = Mutate

local newNode = parser.newNode

-- assumes grammar is a BNF grammar
function Mutate.new (grammar)
	local self = {}
	self = setmetatable(self, Mutate)
	self.grammar = grammar
	self:calcGrammarSets()
	return self
end

function Mutate:calcGrammarSets ()
	local grammar = self.grammar
	local objFst = first.new(grammar)
	self.FIRST = objFst:calcFirstG()
	self.FOLLOW = objFst:calcFollowG()
	self.LAST = objFst:calcLastG()
	self.PRECEDE = objFst:calcPrecedeG()
	self.LEFT = objFst:calcLeftG()
	self.RIGHT = objFst:calcRightG()
end

function Mutate:mutateG ()
	local grammar = self.grammar
	self.gmutated = parser.initgrammar()
	local gmutated = self.gmutated
	gmutated.init = grammar.init
	
	for i, var in ipairs(grammar.plist) do
		table.insert(gmutated.plist, var)
		if parser.isLexRule(var) then
			gmutated.prules[var] = grammar.prules[var] --TODO: generate a copy of rhs
		else
			local exp =  self:mutateExp(grammar.prules[var], var .. ':')
			gmutated.prules[var] = exp
		end
	end
	
	return self.gmutated
end

function Mutate:mutateCon (exp, key)
	print("mutatedCon", pretty.printp(exp), key)
	local mutatedExp = newNode('con')
	for _, iExp in ipairs(exp.p1) do
		if iExp.tag ~= 'var' then -- grammar is BNF, exp can not be a choice
			table.insert(mudatedExp, newNode(exp.tag, exp.p1))
		else
			key = key .. first.prefixKey .. pretty.printp(iExp)
			print("newKey = ", key, self.LEFT[key])
			local left = self.LEFT[key]
    	local right = self.RIGHT[key]
    	local followLeft = set.new()
    	for ele, _ in pairs(left:getAll()) do
    		local eleKey = ele:sub(4)
    		local followEle = self.FOLLOW[eleKey]
    		print("ele", ele, eleKey, followEle)
    		if followEle ~= nil then
    			followLeft = followLeft:union(followEle)
    		end
    	end
    	if followLeft:disjoint(right) then -- can remove
    		print("Mutated " .. iExp.p1 .. " in: " .. pretty.printp(exp))
    		table.insert(mutatedExp, newNode'empty')
    	else
    		table.insert(mutatedExp, iExp)
    	end
		end
	end
	
	return mutatedExp
end

function Mutate:mutateExp (exp, key)
	if exp.tag == 'empty' or exp.tag == 'any' or exp.tag == 'char' or exp.tag == 'var' then
		return newNode(exp.tag, exp.p1)
  elseif exp.tag == 'con' then
  	return self:mutateCon(exp, key)
  elseif exp.tag == 'ord' then
  	local mutatedChoice = newNode('ord') 
		for _, iExp in ipairs(exp.p1) do
			table.insert(mutatedChoice, self:mutateExp(iExp, key))
		end
		return mutatedChoice
  else
		print(exp, exp.tag, exp.empty, exp.any)
		error("Unknown tag: " .. exp.tag)
	end
end

return Mutate


