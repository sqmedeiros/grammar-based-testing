local pretty = {}

local parser = require'parser'

local property

local function printProp (p)
	if property and p[property] then
		return '_' .. tostring(property)
	end
	return ''
end


local function toString (p)
	if p.tag == 'empty' then
		return ''
	elseif p.tag == 'char' then
		return p.p1
	elseif p.tag == 'con' then
		local s = ''
		for i, v in ipairs(p.p1) do
			s = s .. toString(v)
		end
		return s
	else
		print("tou aqui", p, p.tag)
		error("Unknown tag: " .. tostring(p.tag))
	end
end


local function printp (p)
	if p.tag == 'empty' then
		return "''"
	elseif p.tag == 'char' then
		return "'" .. p.p1 .. "'"
	elseif p.tag == 'any' then
		return "."
	elseif p.tag == 'set' then
		return "[" .. table.concat(p.p1) .. "]"
	elseif p.tag == 'var' then
		return p.p1
	elseif p.tag == 'ord' then
		local l = {}
		for k, v in ipairs(p.p1) do
			l[#l + 1] = printp(v)	
		end
		return table.concat(l, ' / ')
	elseif p.tag == 'con' then
		local l = {}
		for k, v in ipairs(p.p1) do
			l[#l + 1] = printp(v)	
		end
		return table.concat(l, ' ')
	else
		print(p, p.tag)
		error("Unknown tag: " .. p.tag)
	end
end

local function printg (g, flagthrow, k, notLex)
	property = k
	print("Property ", k)
	local t = {}
	for i, v in ipairs(g.plist) do
		if not parser.isLexRule(v) or not notLex then
			table.insert(t, string.format("%-15s <-  %s", v, printp(g.prules[v], flagthrow)))
		end
	end
	return table.concat(t, '\n')
end


local function prefix (p1, p2)
	local s1 = printp(p1)
	local s2 = printp(p2)
	local pre = ""
	local i = 1
	while string.sub(s1, 1, i) == string.sub(s2, 1, i) do
		i = i + 1
	end
	pre = string.sub(s1, 1, i - 1)
	if i > 1 then
		print("s1 = ", s1, "s2 = ", s2, p1.p1, p1.p1.tag)
		print("Prefixo foi ", pre)
	end
	return pre
end


local preDefault = [==[
local m = require 'pegparser.parser'
local coder = require 'pegparser.coder'
local util = require'pegparser.util'

g = [[
]==] 

local posDefault = [==[
]]

local g = m.match(g)
local p = coder.makeg(g, 'ast')

local dir = util.getPath(arg[0])

util.testYes(dir .. '/test/yes/', 'source', p)
]==]

local endDefaultNoRecovery = [==[
util.testNo(dir .. '/test/no/', 'source', p)
]==]

local endDefaultWithRecovery = [==[
util.setVerbose(true)
util.testNoRec(dir .. '/test/no/', 'source', p)
]==]


local function printToFile (g, file, ext, rec, pre, pos)
	file = file or 'out.lua'
	local f = io.open(file, "w")

	pre = pre or preDefault
	local s = preDefault ..  printg(g, true)
	print(f)
	if not pos then
		pos = string.gsub(posDefault, 'source', ext)
		local endPos = endDefaultNoRecovery
		if rec then
			endPos = endDefaultWithRecovery
		end
		pos = pos .. string.gsub(endPos, 'source', ext)
	end

	f:write(s .. '\n' .. pos)

	f:close()
end


return {
	printp = printp,
	printg = printg,
	prefix = prefix,
	printToFile = printToFile,
	toString = toString
}
