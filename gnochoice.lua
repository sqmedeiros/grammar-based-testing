local pretty = require"pretty"
local parser = require"parser"

local GNoChoice = {}
GNoChoice.__index = GNoChoice

function GNoChoice.new ()
	local obj = setmetatable({}, GNoChoice)
	obj.ruleList = {}
	obj.ruleMap = {}
	return obj
end


function GNoChoice:withChoiceToNoChoice(gWithChoice)
	for i, var in ipairs(gWithChoice.plist) do
		local rhs = gWithChoice.prules[var]
		if rhs.tag == 'ord' then
			for i, iExp in ipairs(rhs.p1) do
				self:addRule(var, iExp)
			end
		else
			self:addRule(var, rhs)
		end
	end
	
	return self
end


function GNoChoice:addRule (var, rhs)
	if not self.ruleMap[var] then
		table.insert(self.ruleList, var)
		self.ruleMap[var] = {}
	end
	
	table.insert(self.ruleMap[var], rhs)
	
	return self
end


function GNoChoice:printG ()
	local t = {}
	for i, v in ipairs(self.ruleList) do
		if not parser.isLexRule(v) then
			table.insert(t, string.format("%-15s <-  %s", v, self:printRHS(self.ruleMap[v])))
		end
	end
	return table.concat(t, '\n')
end


function GNoChoice:printRHS (rhs)
	local t = {}
	for i, v in pairs(rhs) do
		table.insert(t, pretty.printp(v))		
	end
	return table.concat(t, ' | ')
end

return GNoChoice
