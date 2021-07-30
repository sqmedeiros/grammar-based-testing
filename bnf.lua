local parser = require'parser'
local pretty = require'pretty'

local Bnf = {}
Bnf.__index = Bnf

local newNode = parser.newNode
local newSeq = parser.newSeq
local newOrd = parser.newOrd

function Bnf.new(grammar)
	local obj = setmetatable({}, Bnf)
	obj.grammar = grammar
	obj.suffixRep = 'rep'
	obj.suffixChoice = 'or'
	obj.varSep = '_'
	obj.countRep = 1
	obj.countChoice = 1
	return obj
end


function Bnf:getNewVarName (p, rule)
	local suffix
	local count
	local sep = self.varSep
	if parser.isRepetition(p) then
		suffix = self.suffixRep
		count = self.countRep
		self.countRep = self.countRep + 1
	else
		suffix = self.suffixChoice
		count = self.countChoice
		self.countChoice = self.countChoice + 1
	end

	local newName = rule .. sep .. suffix .. sep .. string.format("%03d", count)
	return newName
end



function Bnf:rewriteGrammar ()
	local grammar = self.grammar
	self.bnfg = parser.initgrammar()
	local bnfg = self.bnfg
	bnfg.init = grammar.init
	
	for i, var in ipairs(grammar.plist) do
		table.insert(bnfg.plist, var)
		local exp =  self:rewriteExp(grammar.prules[var], var, false)
		bnfg.prules[var] = exp 
	end
	
	return self.bnfg
end


function Bnf:rewriteExp (p, rule, inner)

	if p.tag == 'var' or p.tag == 'char' or p.tag == 'empty' then
		return newNode(p.tag, p.p1)
	elseif p.tag == 'con' then
		local listExp = {}
		for i, v in ipairs(p.p1) do
			table.insert(listExp, self:rewriteExp(v, rule, true))	
		end
		return newNode('con', listExp)			
	elseif p.tag == 'ord' then
		local varName
		if inner then
			varName = self:getNewVarName(p, rule)
			table.insert(self.bnfg.plist, varName)
		end
		
		local listExp = {}
		for i, v in ipairs(p.p1) do
			table.insert(listExp, self:rewriteExp(v, rule, true))
		end
		
		local choice = newNode('ord', listExp)
		if inner then
			self.bnfg.prules[varName] = choice
			return newNode('var', varName)
		else		
			return choice
		end
	elseif p.tag == 'star' or p.tag == 'plus' or p.tag == 'opt' then
		return self:repToRec(p, rule)
	else
		assert(false, "Invalid expression " .. tostring(p.tag))
	end
end


function Bnf:repToRec (p, rule)
	local varName = self:getNewVarName(p, rule)
	table.insert(self.bnfg.plist, varName)
	
	local exp = self:rewriteExp(p.p1, rule, true)

	local varRep = newNode('var', varName)
	local choice	
	
	if p.tag == 'star' then      -- p* -> p A / ''
		choice = newOrd(newSeq(exp, varRep), newNode('empty'))
	elseif p.tag == 'plus' then  -- p+ -> p A / p
		choice = newOrd(newSeq(exp, varRep), exp)
	elseif p.tag == 'opt' then   -- p? -> p / ''
		choice = newOrd(exp, newNode('empty'))
	else
		assert(false, "Invalid repetition " .. tostring(p.tag))
	end
	
	self.bnfg.prules[varName] = choice
	return varRep
end


return Bnf
