local set = require'set'
local parser = require'parser'
local first = require'first'

local empty = first.empty
local any = first.any
local endInput = first.endInput

describe("Testing #first", function()
	
	test("FIRST set of lexical rules", function()
		local g = parser.match[[
			A   <- 'a'
			B   <- 'b'
			XYZ <- 'w']]
					
		local objFst = first.new(g)
		objFst:calcFirstG()
		
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
		objFst:calcFirstG()
		
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
		objFst:calcFirstG()
		
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
		objFst:calcFirstG()
		
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
		objFst:calcFirstG()
		
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
		objFst:calcFirstG()
		
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


describe("Testing #follow", function()

	test("FOLLOW set of start rule", function()
		local g = parser.match[[
			s   <- 'a'
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcFollowG()

		local setFlw = {}
		setFlw['s'] = set.new{ endInput }

		assert.same(objFst.FOLLOW, setFlw)
	end)

	test("Grammar with concatenation 1", function()
		local g = parser.match[[
			s   <- A 'a' A B
			A   <- 'x'
			B   <- 'B' / A
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcFollowG()

		local setFlw = {}
		setFlw['s'] = set.new{ endInput }
		setFlw['A'] = set.new{ 'a', objFst:lexKey('B') }
		setFlw['B'] = set.new{ endInput }

		assert.same(objFst.FOLLOW, setFlw)
	end)


	test("Grammar with choice", function()
		local g = parser.match[[
			s   <- a 'a' a b
			a   <- 'x'
			b   <- 'B' / a b a
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcFollowG()

		local setFlw = {}
		setFlw['s'] = set.new{ endInput }
		setFlw['a'] = set.new{ 'a', 'B', 'x', endInput }
		setFlw['b'] = set.new{ endInput, 'x' }

		assert.same(objFst.FOLLOW, setFlw)
	end)


	test("Grammar with empty string", function()
		local g = parser.match[[
			s   <- a b c
			a   <- 'a'
			b   <- 'b'
			c   <- 'c' / ''
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcFollowG()

		local setFlw = {}
		setFlw['s'] = set.new{ endInput }
		setFlw['a'] = set.new{ 'b' }
		setFlw['b'] = set.new{ 'c', endInput }
		setFlw['c'] = set.new{ endInput }

		assert.same(objFst.FOLLOW, setFlw)
	end)


	test("Grammar with empty string 2", function()
		local g = parser.match[[
			s   <- a b c d
			a   <- 'a'
			b   <- 'b'
			c   <- 'c' / ''
			d   <- 'd' / ''
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcFollowG()

		local setFlw = {}
		setFlw['s'] = set.new{ endInput }
		setFlw['a'] = set.new{ 'b' }
		setFlw['b'] = set.new{ 'c', 'd', endInput }
		setFlw['c'] = set.new{ 'd', endInput }
		setFlw['d'] = set.new{ endInput }

		assert.same(objFst.FOLLOW, setFlw)
	end)


	test("Grammar repetition: star", function()
		local g = parser.match[[
			s   <- a* 'A' b* c*
			a   <- 'x' / 'y'
			b   <- 'b'
			c   <- 'c'
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcFollowG()

		local setFlw = {}
		setFlw['s'] = set.new{ endInput }
		setFlw['a'] = set.new{ 'x', 'y', 'A' }
		setFlw['b'] = set.new{ endInput, 'b', 'c' }
		setFlw['c'] = set.new{ endInput, 'c' }

		assert.same(objFst.FOLLOW, setFlw)
	end)

	test("Grammar repetition: plus", function()
		local g = parser.match[[
			s   <- a+ 'A' b+ c+
			a   <- 'x' / 'y'
			b   <- 'b'
			c   <- 'c'
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcFollowG()

		local setFlw = {}
		setFlw['s'] = set.new{ endInput }
		setFlw['a'] = set.new{ 'x', 'y', 'A' }
		setFlw['b'] = set.new{ 'b', 'c' }
		setFlw['c'] = set.new{ endInput, 'c' }

		assert.same(objFst.FOLLOW, setFlw)
	end)


	test("Grammar repetition: question/optional", function()
		local g = parser.match[[
			s   <- a? 'A' b? c?
			a   <- 'x' / 'y'
			b   <- 'b'
			c   <- 'c'
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcFollowG()

		local setFlw = {}
		setFlw['s'] = set.new{ endInput }
		setFlw['a'] = set.new{ 'A' }
		setFlw['b'] = set.new{ 'c', endInput}
		setFlw['c'] = set.new{ endInput }

		assert.same(objFst.FOLLOW, setFlw)
	end)


	test("Grammar repetition", function()
		local g = parser.match[[
			s   <- a* 'A'
			a   <- b / 'o' c 'd'
			b   <- 'B'? 'x' c+ 'u'
			c   <- 'y' a 'z'?
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcFollowG()

		local setFlw = {}
		setFlw['s'] = set.new{ endInput }
		setFlw['a'] = set.new{ 'B', 'x', 'o', 'A', 'z', 'd', 'u', 'y' }
		setFlw['b'] = set.new{ 'B', 'x', 'o', 'A', 'z', 'd', 'u', 'y' }
		setFlw['c'] = set.new{ 'y', 'u', 'd' }

		assert.same(objFst.FOLLOW, setFlw)
	end)

	test("Calculating FOLLOW of a DOT grammar", function()
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
		objFst:calcFirstG()
		objFst:calcFollowG()

		local setFlw = {}
		setFlw['graph'] = set.new { endInput  }
		setFlw['stmt_list'] = set.new { '}' }
		setFlw['stmt'] = set.new      { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge', ';', '}' }
		setFlw['attr_stmt'] = set.new { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge', ';', '}' }
		setFlw['attr_list'] = set.new { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge', ';', '}' }
		setFlw['a_list'] = set.new    { ']' }
		setFlw['edge_stmt'] = set.new { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge', ';', '}' }
		setFlw['edgeRHS'] = set.new   { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge', ';', '}', '[' }
		setFlw['edgeop'] = set.new    { 'a', '"a"', '<a>', '1', 'subgraph', '{' }
		setFlw['node_stmt'] = set.new { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge', ';', '}' }
		setFlw['node_id'] = set.new   { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge', ';', '}', '[', '->', '--' }
		setFlw['port'] = set.new      { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge', ';', '}', '[', '->', '--' }
		setFlw['subgraph'] = set.new  { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge', ';', '}', '[', '->', '--', '{' }
		setFlw['id'] = set.new        { 'a', '"a"', '<a>', '1', 'subgraph', '{', 'graph', 'node', 'edge', ';', '}', '=', ',', '->', '--', ':' , '[', ']'}

		assert.same(objFst.FOLLOW, setFlw)
	end)
end)


describe("Testing #last", function()

	test("LAST set of simple expresions", function()
		local g = parser.match[[
			s   <- 'a'
			a   <- .
			b   <- ''
			C   <- 'c'
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcLastG()

		local setLst = {}
		setLst['s'] = set.new{ 'a' }
		setLst['a'] = set.new{ first.any }
		setLst['b'] = set.new{ first.empty }
		setLst['C'] = set.new{ objFst:lexKey('C') }

		assert.same(objFst.LAST, setLst)
	end)

	test("LAST set of choice expresion", function()
		local g = parser.match[[
			s   <- a / b
			a   <- b / c
			b   <- 'b' / 'B'
			c   <- '' / 'c'
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcLastG()

		local setLst = {}
		setLst['s'] = set.new{ 'b', 'B', empty, 'c', }
		setLst['a'] = set.new{ 'b', 'B', empty, 'c' }
		setLst['b'] = set.new{ 'b', 'B' }
		setLst['c'] = set.new{ empty, 'c' }

		assert.same(objFst.LAST, setLst)
	end)

	test("LAST set of choice expresion", function()
		local g = parser.match[[
			id                <-   'a'   /  '"a"'   /  '<a>'   /  '1'
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcLastG()

		local setLst = {}
		setLst['id'] = set.new{ 'a', '"a"', '<a>', '1' }

		assert.same(objFst.LAST, setLst)
	end)


	test("LAST set of concatenation", function()
		local g = parser.match[[
			s   <- a c / b d
			a   <- 'a' / 'A'
			b   <- 'b' / 'B'
			c   <- '' / 'c'
			d   <- '' 'e' 'f' / 'e' ''
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcLastG()

		local setLst = {}
		setLst['s'] = set.new{ 'a',  'A', 'c', 'f', 'e' }
		setLst['a'] = set.new{ 'a', 'A' }
		setLst['b'] = set.new{ 'b', 'B' }
		setLst['c'] = set.new{ empty, 'c' }
		setLst['d'] = set.new{ 'f', 'e' }

		assert.same(objFst.LAST, setLst)
	end)


	test("LAST set of concatenation 2", function()
		local g = parser.match[[
			x   <- y '' / z ''
			y   <- 'a' / 'A' / z
			z   <- 'b' / 'B'
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcLastG()

		local setLst = {}
		setLst['x'] = set.new{ 'a',  'A', 'b', 'B' }
		setLst['y'] = set.new{ 'a', 'A', 'b', 'B' }
		setLst['z'] = set.new{ 'b', 'B' }

		assert.same(objFst.LAST, setLst)
	end)


	test("LAST set of repetition", function()
		local g = parser.match[[
			s   <- 'b' 'a'*
			a   <- 'B'+
			b   <- ('c' / 'C')?
		]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcLastG()

		local setLst = {}
		setLst['s'] = set.new{ 'a', 'b' }
		setLst['a'] = set.new{ 'B' }
		setLst['b'] = set.new{ 'c', 'C', empty }

		assert.same(objFst.LAST, setLst)
	end)


	test("Calculating LAST of id", function()
		local g = parser.match[[
			a_list            <-   ('=' id)?
			id                <-   'a'   /  '"a"'   /  '<a>'   /  '1'
    ]]

		local objFst = first.new(g)
		objFst:calcFirstG()
		objFst:calcLastG()

		local setLst = {}
		setLst['a_list'] = set.new    { 'a', '"a"', '<a>', '1', empty }
		setLst['id'] = set.new        { 'a', '"a"', '<a>', '1' }

		assert.same(objFst.LAST, setLst)
	end)


	test("Calculating LAST of a DOT grammar", function()
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
		objFst:calcFirstG()
		objFst:calcLastG()


		local setLst = {}
		setLst['graph'] = set.new { '}'  }
		setLst['stmt_list'] = set.new { empty, ';', 'a', '"a"', '<a>', '1', ']', '}' }
		setLst['stmt'] = set.new      { 'a', '"a"', '<a>', '1', ']', '}' }
		setLst['attr_stmt'] = set.new { ']' }
		setLst['attr_list'] = set.new { ']' }
		setLst['a_list'] = set.new    { 'a', '"a"', '<a>', '1', ',' }
		setLst['edge_stmt'] = set.new { ']', 'a', '"a"', '<a>', '1', '}' }
		setLst['edgeRHS'] = set.new   { 'a', '"a"', '<a>', '1', '}' }
		setLst['edgeop'] = set.new    { '->', '--' }
		setLst['node_stmt'] = set.new { 'a', '"a"', '<a>', '1', ']' }
		setLst['node_id'] = set.new   { 'a', '"a"', '<a>', '1' }
		setLst['port'] = set.new      { 'a', '"a"', '<a>', '1' }
		setLst['subgraph'] = set.new  { '}' }
		setLst['id'] = set.new        { 'a', '"a"', '<a>', '1' }

		assert.same(objFst.LAST, setLst)
	end)

end)

