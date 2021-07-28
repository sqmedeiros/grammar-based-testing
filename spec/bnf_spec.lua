local parser = require'parser'
local pretty = require'pretty'
local bnf = require'bnf'

local function removeSpace (s)
	return s:gsub("[ \t\n\r]", "")
end

local function sameGrammar (auto, manual)
	local bnfg = bnf.new(auto)
	local newg = bnfg:rewriteGrammar()
	assert.same(removeSpace(manual), removeSpace(pretty.printg(newg)))
end

describe("Bnf grammar", function()
	
	test("Rewriting a grammar without repetition", function()
		local g = parser.match([[a <- 'b']])
		
		local manualg = [[a <- 'b']]
		
		sameGrammar(g, manualg)
	end)
	
	test("Rewriting a grammar with a single '*' repetition", function()	
		local g = parser.match[[s <- 'a'*]]
		
		local manualg = [[
			s         <- s_rep_001 
		  s_rep_001 <- 'a' s_rep_001 / '']]
		
		sameGrammar(g, manualg)
	end)
	
	test("Rewriting a grammar with a single '+' repetition", function()	
		local g = parser.match[[s <- 'a'+]]
		
		local manualg = [[
			s         <- s_rep_001 
		  s_rep_001 <- 'a' s_rep_001 / 'a']]
		
		sameGrammar(g, manualg)
	end)
	
	test("Rewriting a grammar with a single '?' repetition", function()	
		local g = parser.match[[s <- 'a'?]]
		
		local manualg = [[
			s         <- s_rep_001 
		  s_rep_001 <- 'a' / '']]
		
		sameGrammar(g, manualg)
	end)
	
	test("Rewriting a grammar with where two rules have repetition", function()	
		local g = parser.match[[s <- a? 'x'
		                        a <- 'b'*]]
		
		local manualg = [[
			s         <- s_rep_001 'x'
			s_rep_001 <- a / ''
			a         <- a_rep_002
		  a_rep_002 <- 'b' a_rep_002 / '']]
		
		sameGrammar(g, manualg)
	end)

	
	
	test("Rewriting a grammar with several repetitions", function()	
		local g = parser.match[[
			s     <- ('a'? x)+ c* d
		  c     <- 'c'* 'C'
		  d     <- 'd'+ / 'D'+
		  x     <- 'x']]
		
		local manualg = [[
			s         <- s_rep_001 s_rep_003 d
			s_rep_001 <- s_rep_002 x s_rep_001 / s_rep_002 x
			s_rep_002 <- 'a' / ''
			s_rep_003 <- c s_rep_003 / ''
		  c         <- c_rep_004 'C'
		  c_rep_004 <- 'c' c_rep_004 / ''
		  d         <- d_rep_005 / d_rep_006
		  d_rep_005 <- 'd' d_rep_005 / 'd'
		  d_rep_006 <- 'D' d_rep_006 / 'D'
		  x         <- 'x'
]]		
		
		sameGrammar(g, manualg)
	end)
	
	test("Rewriting a grammar with one inner choice", function()	
		local g = parser.match[[s <- 'a' ('b' / 'c')]]
		
		local manualg = [[
			s         <- 'a' s_or_001 
		  s_or_001  <- 'b' / 'c']]
		
		sameGrammar(g, manualg)
	end)
	
	test("Rewriting a grammar with two inner choices", function()	
		local g = parser.match[[s <- a
		                        a <- ('x' / 'y' ('A' / 'B')) 'd' / 'b']]
		
		local manualg = [[
			s         <- a
			a         <- a_or_001 'd' / 'b'
		  a_or_001  <- 'x' / 'y' a_or_002
		  a_or_002  <- 'A' / 'B']]
		
		sameGrammar(g, manualg)
	end)
	
	
	test("Rewriting a grammar with repetitions and inner choices", function()	
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

		
		local manualg = [[
			graph             <-   graph_rep_001 graph_or_001 graph_rep_002 '{' stmt_list '}'
			graph_rep_001     <-   'strict' / ''
			graph_or_001      <-   'graph' / 'digraph'
			graph_rep_002     <-   id / ''
			stmt_list         <-   stmt_list_rep_003
			stmt_list_rep_003 <-   stmt stmt_list_rep_004 stmt_list_rep_003 / ''
			stmt_list_rep_004 <-   ';' / ''
			stmt              <-   id '=' id   /  edge_stmt   /  node_stmt  /  attr_stmt   /   subgraph 
			attr_stmt         <-   attr_stmt_or_002 attr_list
			attr_stmt_or_002  <-   'graph'   /  'node'   /  'edge' 
			attr_list         <-   attr_list_rep_005
			attr_list_rep_005 <-   '[' attr_list_rep_006 ']' attr_list_rep_005 /  '[' attr_list_rep_006 ']'
			attr_list_rep_006 <-   a_list / ''
			a_list            <-   a_list_rep_007
			a_list_rep_007    <-   id a_list_rep_008 a_list_rep_009 a_list_rep_007 / id a_list_rep_008 a_list_rep_009
			a_list_rep_008    <-   '=' id / ''
			a_list_rep_009    <-   ',' / ''
			edge_stmt         <-   edge_stmt_or_003 edgeRHS edge_stmt_rep_010
			edge_stmt_or_003  <-   node_id   /  subgraph
			edge_stmt_rep_010 <-   attr_list / ''
			edgeRHS           <-   edgeRHS_rep_011
			edgeRHS_rep_011   <-   edgeop edgeRHS_or_004 edgeRHS_rep_011 /  edgeop edgeRHS_or_004
			edgeRHS_or_004    <-   node_id   /  subgraph
			edgeop            <-   '->'   /  '--' 
			node_stmt         <-   node_id node_stmt_rep_012
			node_stmt_rep_012 <-   attr_list / ''
			node_id           <-   id node_id_rep_013 
			node_id_rep_013   <-   port / ''
			port              <-   ':' id port_rep_014
			port_rep_014      <-   ':' id / ''
			subgraph          <-   subgraph_rep_015 '{' stmt_list '}'
			subgraph_rep_015  <-   'subgraph' subgraph_rep_016  / ''
			subgraph_rep_016  <-   id / ''
			id                <-   'a'   /  '"a"'   /  '<a>'   /  '1'
			
]]		
		sameGrammar(g, manualg)
	end)
	
	
end)
