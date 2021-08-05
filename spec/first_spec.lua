local set = require'set'
local parser = require'parser'
local first = require'first'

local empty = first.empty
local any = first.any

describe("Testing #first", function()
	
	test("FIRST set of lexical rules", function()
		local g = parser.match[[
			A   <- 'a'
			B   <- 'b'
			XYZ <- 'w']]
					
		local objFst = first.new(g)
		objFst:calcFstG()
		
		local setFirst = {}
		for i, v in ipairs(g.plist) do
			setFirst[v] = set.new( { objFst:lexKey(v) } )
		end
		
		assert.same(objFst.FIRST, setFirst)
	end)
		
		
	test("FIRST set of simple syntactical rules", function()
		local g = parser.match[[
			s   <- 'a'
			a   <- 'b'
			xyz <- .]]
					
		local objFst = first.new(g)
		objFst:calcFstG()
		
		local setFirst = {}
		setFirst['s'] = set.new { 'a' }
		setFirst['a'] = set.new { 'b' }
		setFirst['xyz'] = set.new { any }
		
		assert.same(objFst.FIRST, setFirst)
	end)
	
	test("FIRST set of concatenation", function()
		local g = parser.match[[
			s   <- 'a' a
			a   <- xyz 'b'
			b   <- y xyz s
			xyz <- ''
			y   <- '']]
					
		local objFst = first.new(g)
		objFst:calcFstG()
		
		local setFirst = {}
		setFirst['s'] = set.new { 'a' }
		setFirst['a'] = set.new { 'b' }
		setFirst['b'] = set.new { 'a' }
		setFirst['xyz'] = set.new { empty }
		setFirst['y'] = set.new { empty }
		
		assert.same(objFst.FIRST, setFirst)
	end)
	
	test("FIRST set of choice", function()
		local g = parser.match[[
			s   <- 'a' a / 'x'
			a   <- xyz 'b' / 'otherA'
			b   <- y xyz s / 'otherB1' / xyz a / y
			xyz <- 'X' / ''
			y   <- '' / 'Y']]
					
		local objFst = first.new(g)
		objFst:calcFstG()
		
		local setFirst = {}
		setFirst['s'] = set.new { 'a', 'x' }
		setFirst['a'] = set.new { 'X', 'b', 'otherA' }
		setFirst['b'] = set.new { 'Y', 'X', 'a', 'x', 'otherB1', 'b', 'otherA', empty }
		setFirst['xyz'] = set.new { 'X', empty }
		setFirst['y'] = set.new { empty, 'Y' }
		
		assert.same(objFst.FIRST, setFirst)
	end)
	
	test("FIRST set of repetitions", function()
		local g = parser.match[[
			s   <- ('a' / 'b')*
			a   <- b?
			b   <- 'c' 'd' / 'e' / 'x'+]]
					
		local objFst = first.new(g)
		objFst:calcFstG()
		
		local setFirst = {}
		setFirst['s'] = set.new { 'a', 'b', empty }
		setFirst['a'] = set.new { 'c', 'e', 'x', empty }
		setFirst['b'] = set.new { 'c', 'e', 'x' }
		
		assert.same(objFst.FIRST, setFirst)
	end)
	
	test("Calculating FIRST of a DOT grammar", function()	
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
    
		local objFst = first.new(g)
		objFst:calcFstG()
		
		local setFirst = {}
		setFirst['graph'] = set.new { 'strict', 'graph', 'digraph' }
		setFirst['stmt_list'] = set.new { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge', empty }
		setFirst['stmt'] = set.new { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge' }
		setFirst['attr_stmt'] = set.new { 'graph', 'node', 'edge' }
		setFirst['attr_list'] = set.new { '[' }
		setFirst['a_list'] = set.new { 'a', '"a"', '<a>', '1' }
		setFirst['edge_stmt'] = set.new { 'a', '"a"', '<a>', '1', 'subgraph', '{' }
		setFirst['edgeRHS'] = set.new { '->', '--' }
		setFirst['edgeop'] = set.new { '->', '--' }
		setFirst['node_stmt'] = set.new { 'a', '"a"', '<a>', '1' }
		setFirst['node_id'] = set.new { 'a', '"a"', '<a>', '1' }
		setFirst['port'] = set.new { ':' }
		setFirst['subgraph'] = set.new { 'subgraph', '{' }
		setFirst['id'] = set.new { 'a', '"a"', '<a>', '1' }
		
		assert.same(objFst.FIRST, setFirst)    
	end)	
end)


