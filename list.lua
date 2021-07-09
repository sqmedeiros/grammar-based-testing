local List = {}
List.__index = List

local equalFn = function (x, y) return x == y end


function List.new (...)
	local list = { value = "head", nexxt = nil }
	
	setmetatable(list, List)
	
	return list:add(...)
end


function List:isEmpty ()
	return self.nexxt == nil
end


function List:head ()
	return self.nexxt.value
end


function List:tail ()
	return self.nexxt
end


function List:find (v, f)
	local equal = f or equalFn
	local aux = self
	while aux.nexxt ~= nil and not equal(aux.nexxt.value, v) do
		aux = aux.nexxt
	end
	
	return aux
end


function List:contains (v, f)
	local equal = f or equalFn
	local aux = self:find(v, f)		
	return aux.nexxt ~= nil and equal(aux.nexxt.value, v)
end


function List:add (...)
	local ele = { ... }
	
	local aux = self
	
	local lastNext = self.nexxt
	for i, v in ipairs(ele) do
		aux.nexxt = List.new()
		aux.nexxt.value = v
		aux = aux.nexxt
	end
	
	aux.nexxt = lastNext
	return self
end


function List:remove (v)
	self:replace(v)
	return self
end


function List:replace (v, ...)
	if self:contains(v) then
		local l = self:find(v)
		l.nexxt = l.nexxt.nexxt
		l:add(...)
	end
	
	return self
end


function List:toString (start, endd, sep, printFn)
	local start = start or ''
	local endd = endd or ''
	local sep = sep or ''
	
	local arr = {}
	local aux = self
	while aux.nexxt ~= nil do
		local v = aux.nexxt.value
		if printFn then
			v = printFn(v)
		end
		arr[#arr + 1] = v
		aux = aux.nexxt
	end

	return start .. table.concat(arr, sep) .. endd
end

function List:__tostring()
	return self:toString('{ ', ' }', ', ')
end

return List

