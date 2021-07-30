local parser = require'parser'
local bnf = require'bnf'
local minderiv = require'minderiv'

local g = parser.match[[
			graph             <-   'strict'? ('graph'   /  'digraph') id? '{' stmt_list '}' 
			stmt_list         <-   (stmt ';'? )* 
			stmt              <-   id '=' id   /  edge_stmt   /  node_stmt  /  attr_stmt   /   subgraph 
			attr_stmt         <-   ('graph'   /  'node'   /  'edge' ) attr_list 
			attr_list         <-   ('[' a_list? ']' )+ 
			a_list            <-   (id ('=' id )? ','? )+ 
			edge_stmt         <-   (node_id   /  subgraph ) edgeRHS attr_list? 
			edgeRHS           <-   (edgeop (node_id   /  subgraph ) )+ 
			edgeop            <-   '->'   /  '--' 
			node_stmt         <-   node_id attr_list? 
			node_id           <-   id port? 
			port              <-   ':' id (':' id )? 
			subgraph          <-   ('subgraph' id? )? '{' stmt_list '}'
			id                <-   'a'   /  '"a"'   /  '<a>'   /  '1'
]]

local bnfg = bnf.new(g)
local newg = bnfg:rewriteGrammar()

local mind = minderiv.new(newg)
mind:calcMinDeriv()
mind:buildGraph()
mind:minDerivPath()
local pairCov = mind:pairCoverage()

local idxSlash = string.find(arg[0], '/')
local lastSlash = nil
while idxSlash ~= nil do
	lastSlash = idxSlash
	idxSlash = string.find(arg[0], '/', idxSlash + 1)
end


print("Dir = ", dir, lastSlash, string.sub(arg[0], 1, lastSlash))
local dir = string.sub(arg[0], 1, lastSlash)

mind:generate({ file = true, ext = 'dot', dir = dir} )


