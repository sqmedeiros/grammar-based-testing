local m = require'lpeglabel'
local re = require'relabel'
local errinfo = require'syntax_errors'
local predef = require'predef'

local g = {}
local defs = {}
local lasttk = {}

local function copyp (p)
	local aux = p
	for k, v in pairs(p) do
		aux.k = v
	end
	aux.p1, aux.p2 = nil, nil
	return aux
end

local newNode = function (tag, p1, p2)
	assert(tag, "Node with an invalid tag: " .. tostring(tag))
	if type(tag) == "table" then
		local newp = copyp(tag)
		newp.p1, newp.p2 = p1, p2
		return newp	
	else
		return { tag = tag, p1 = p1, p2 = p2 }
	end
end

defs.newEsqSeq = function (v1, v2)
	--print ("newEsqSeq = ", v1, #v1, #"\t")
	--return "\t"
	return v1
end

defs.newString = function (v, quote)
	if #v == 0 then
		return newNode('empty')
	end
	g.tokens[v] = true
	lasttk[v] = true
	return newNode('char', v)
	--return newNode('char', v, quote or "'")
end

defs.newAny = function (v)
	return newNode('any')
end

defs.newVar = function (v)
	g.vars[#g.vars + 1] = v
	return newNode('var', v)
end

defs.newClass = function (l)
	return newNode('set', l)
end

defs.newAnd = function (p)
	return newNode('and', p)
end

defs.newNot = function (p)
	assert(p ~= nil)
	return newNode('not', p)
end

defs.newSeq = function (...)
	if #{...} > 1 then
		return newNode('con', {...})
	else
		return ...
	end
end

defs.newOrd = function (...)
	if #{...} > 1 then
		return newNode('ord', {...})
	else
		return ...
	end
end

defs.newDef = function (v)
	if not predef[v] then
		error("undefined name: " .. tostring(v))
	end
	return newNode('def', v)
end

defs.newThrow = function (lab)
	return newNode('throw', lab)
end

defs.newConstCap = function (p)
	return newNode('constCap', p)
end

defs.newPosCap = function ()
	return newNode('posCap')
end

defs.newSimpCap = function (p)
	return newNode('simpCap', p)
end

defs.newTabCap = function (p)
	return newNode('tabCap', p)
end

defs.newAnonCap = function (p)
	return newNode('anonCap', p)
end

defs.newNameCap = function (p1, p2)
	return newNode('nameCap', p1, p2)
end

defs.newDiscardCap = function (p)
	return newNode('funCap', p)
end


defs.newSuffix = function (p, ...)
  local l = { ... }
	local i = 1
	while i <= #l do
		local v = l[i]
		if v == '*' then
			p = newNode('star', p)
			i = i + 1
		elseif v == '+' then
			p = newNode('plus', p)
			i = i + 1
		elseif v == '?' then
			p = newNode('opt', p)
			i = i + 1
		else
			p = newNode('ord', p, defs.newThrow(l[i+1]))
			i = i + 2
		end
	end
	return p
end 


defs.isLexRule = function (s)
	local ch = string.sub(s, 1, 1)
	return ch >= 'A' and ch <= 'Z'
end


defs.isErrRule = function (s)
	return string.find(s, 'Err_')
end

defs.newRule = function (k, v)
	g.prules[k] = v
	g.plist[#g.plist + 1] = k
	if defs.isLexRule(k) then
		for k, v in pairs(lasttk) do
			g.tokens[k] = nil
		end
	end
	lasttk = {}
end

defs.addRuleG = function (g, k, v, frag)
	g.prules[k] = v
	g.plist[#g.plist + 1] = k
	if defs.isLexRule(k) and not frag then
	  g.tokens[k] = true
	end
end


defs.isSimpleExp = function (p)
	local tag = p.tag
	return tag == 'empty' or tag == 'char' or tag == 'any' or
         tag == 'set' or tag == 'var' or tag == 'throw' or
         tag == 'posCap' or tag == 'def'
end


defs.hasSymbol = function (p, symbol, alsoChar)
	if p.tag == 'var' or (p.tag == 'char' and alsoChar) then
		return p.p1 == symbol, p
	elseif p.tag == 'con' or p.tag == 'ord' then
		for k, v in pairs(p.p1) do
			if defs.hasSymbol(v, symbol, alsoChar) then
				if p.tag == 'con' then
					return true, p
				else
					return true, v
				end
			end
		end
		return false
	elseif p.tag == 'star' or p.tag == 'opt' or p.tag == 'plus' then
		return defs.hasSymbol(p.p1, v, alsoChar), p
	else
		return false
	end
end


defs.isDerivable = function (p)
	if p.tag == 'var' and not defs.isLexRule(p.p1) then
		return true
	elseif p.tag == 'con' or p.tag == 'ord' then
		for i, v in ipairs(p.p1) do
			if defs.isDerivable(v) then
				return true
			end
		end
		return false
	elseif p.tag == 'star' or p.tag == 'opt' or p.tag == 'plus' then
		return defs.isDerivable(p.p1)
	else
		return false
	end
end


defs.isDerivSimp = function (p)
	return p.tag == 'var' and not defs.isLexRule(p.p1)
end


defs.repSymbol = function (p)
	local tag = p.tag
	assert(tag == 'opt' or tag == 'plus' or tag == 'star', p.tag)
	if p.tag == 'star' then
		return '*'
	elseif p.tag == 'plus' then
		return '+'
	else
		return '?'
	end
end

defs.predSymbol = function (p)
	local tag = p.tag
	assert(tag == 'not' or tag == 'and', p.tag)
	if p.tag == 'not' then
		return '!'
	else
		return '&'
	end
end


defs.matchEmpty = function (p)
	local tag = p.tag
	if tag == 'empty' or tag == 'not' or tag == 'and' or
     tag == 'posCap' or tag == 'star' or tag == 'opt' or
		 tag == 'throw' then
		return true
	elseif tag == 'def' then
		return false
	elseif tag == 'char' or tag == 'set' or tag == 'any' or
         tag == 'plus' then
		return false
	elseif tag == 'con' then
		return defs.matchEmpty(p.p1) and defs.matchEmpty(p.p2)
	elseif tag == 'ord' then
		return defs.matchEmpty(p.p1) or defs.matchEmpty(p.p2)
	elseif tag == 'var' then
		return defs.matchEmpty(g.prules[p.p1])
	elseif tag == 'simpCap' or tag == 'tabCap' or tag == 'anonCap' then
		return defs.matchEmpty(p.p1)
	elseif tag == 'nameCap' then
		return defs.matchEmpty(p.p2)
	else
		print(p)
		error("Unknown tag" .. tostring(p.tag))
	end
end


local function setSkip (g)
	local space = defs.newClass{' ','\t','\n','\v','\f','\r'}
	if g.prules['COMMENT'] then
		space =	defs.newOrd(space, defs.newVar('COMMENT'))
	end
	local skip = defs.newSuffix(space, '*')

	local s = 'SPACE'
	if not g.prules[s] then
		g.plist[#g.plist+1] = s
	end
	g.prules[s] = space

	local s = 'SKIP'
	if not g.prules[s] then
		g.plist[#g.plist+1] = s
	end
	g.prules[s] = skip
end

local function setEOF (g, s)
	s = s or 'EOF'
	if not g.prules[s] then
		g.plist[#g.plist+1] = s
	end
	g.prules[s] = defs.newNot(defs.newAny())
end


local peg = [[
	grammar       <-   S rule+^Rule (!.)^Extra

  rule          <-   (name S arrow^Arrow exp^ExpRule)   -> newRule

  exp           <-   (seq ('/' S seq^SeqExp)*) -> newOrd

  seq           <-   (prefix (S prefix)*) -> newSeq

  prefix        <-   '&' S prefix^AndPred -> newAnd  / 
                     '!' S prefix^NotPred -> newNot  /  suffix

  suffix        <-   (primary ({'+'} S /  {'*'} S /  {'?'} S /  {'^'} S name)*) -> newSuffix

  primary       <-   '(' S exp^ExpPri ')'^RParPri S  /  string  /  class  /  any  /  var / def / throw 

  string        <-   ("'" {escseq / (!"'"  .)*} {"'"}^SingQuote  S  /
                      '"' {escseq / (!'"'  .)*} {'"'}^DoubQuote  S) -> newString

	class         <-   '[' {| (({(.'-'!']'.)} / (!']' {.}))+)^EmptyClass |} -> newClass ']'^RBraClass S

  any           <-   '.' -> newAny S
  
  esc           <-   [\\]
  
  --escseq        <-    '\t' -> newEsqSeq
  escseq        <-    !'\t''\t' -> newEsqSeq

  var           <-    name -> newVar !arrow  

  name          <-   {[a-zA-Z_] [a-zA-Z0-9_]*} S
 
  def           <-   '%' S name -> newDef

  throw         <-   '%{' S name^NameThrow -> newThrow '}'^RCurThrow S

  arrow         <-   '<-' S

  S             <-   (%s  /  '--' [^%nl]*)*  --spaces and comments
]]

local ppk = re.compile(peg, defs)

defs.initgrammar = function(t)
	local g = {}
	if t then
		for k, v in pairs(t) do
			g[k] = v
		end
	else
		g.plist = {}
		g.prules = {}
		g.tokens = {}
		g.vars = {}
		g.unique = {}
	end

	return g
end



defs.match = function (s, noSkip)
	g = defs.initgrammar()
	local r, lab, pos = ppk:match(s)
  if not r then
		local line, col = re.calcline(s, pos)
		local msg = line .. ':' .. col .. ':'
		return r, msg .. (errinfo[lab] or lab), pos
	else
		if false then
			setSkip(g)
			setEOF(g)
			print("entrei aqui")
		end
		for i, v in ipairs(g.vars) do
			if (g.prules[v] == nil) then
				error("Rule '" .. v .. "' was not defined")
			end
		end
		g.init = g.plist[1]
		return g 
	end
end


defs.newNode = newNode
return defs
