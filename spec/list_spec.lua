local list = require'list'

describe("Testing the #list structure", function()
	
	test("New list", function()
		assert.same(list.new(), { value = "head", next = nil})
	end)
	
	test("Inserting single element in an empty list", function()
		local l = { value = "head", nexxt = { value = 42, nexxt = nil }}
		assert.same(list.new():add(42), l)
	end)
	
	test("Creating a list with a single element", function()
		local l = { value = "head", nexxt = { value = 42, nexxt = nil }}
		assert.same(list.new(42), l)
	end)
	
	test("Inserting multiple elements in an empty list", function()
		local l = { value = "head",
		            nexxt = { value = 42,
		                      nexxt = { value = 50,
		                                nexxt = nil}}}
		assert.same(list.new():add(42, 50), l)
	end)
	
	test("Creating a list with multiple elements", function()
		local l = { value = "head",
		            nexxt = { value = 42,
		                      nexxt = { value = 50,
		                                nexxt = nil}}}
		assert.same(list.new(42, 50), l)
	end)
	
	test("Searching the sublist that starst with a given element", function()
		local l = { value = 42,
		            nexxt = { value = 50,
		                      nexxt = nil}}
		assert.same(list.new(42, 50):find(50), l)
	end)
	
	 test("Searching for an absent element", function()
		local l = { value = 50,
		            nexxt = nil}
		assert.same(list.new(42, 50):find(11), l)
	end)
			
	test("Checking if the list has a given element (it is the first list element)", function()
		assert.True(list.new("first", "last"):contains("first"))
	end)
	
	test("Checking if the list has a given element (it is the second list element)", function()
		assert.True(list.new("first", "last"):contains("last"))
	end)
	
	test("Checking if an empty list has a given element", function()
		assert.False(list.new():contains(1))
	end)
	
	test("Checking for an absent element", function()
		assert.False(list.new(1):contains(2))
	end)
	
	test("Checking for an absent element", function()
		assert.False(list.new("first", 2):contains("last"))
	end)
	
	test("Checking for a table element will return false, unless it is the same element", function()
	  local t = { "first" }
		assert.True(list.new(t):contains(t))
	end)
	
	test("Checking for a table element will return false, unless it is the same element", function()
		assert.False(list.new({"first"}):contains({"first"}))
	end)
	
	test("Removing the first element from a list", function()
		local l = { value = "head",
		            nexxt = { value = 50,
		                      nexxt = nil}}
		assert.same (list.new(42, 50):remove(42), l)
	end)
	
	test("Removing the last element from a list", function()
		local l = { value = "head",
		            nexxt = { value = 42,
		                      nexxt = nil}}
		assert.same (list.new(42, 50):remove(50), l)
	end)
	
	test("Removing an absent element from a list", function()
		local l = { value = "head",
		            nexxt = { value = 42,
		                      nexxt = { value = 50,
		                                nexxt = nil}}}
		assert.same (list.new(42, 50):remove(10), l)
	end)
	
	test("Replacing the first element from a list", function()
		local l = { value = "head",
		            nexxt = { value = "novo",
		                      nexxt = { value = 50,
		                                nexxt = nil}}}
		assert.same (list.new(42, 50):replace(42, "novo"), l)
	end)
	
	test("Replacing the first element with two elements", function()
		local l = { value = "head",
		            nexxt = { value = "novo",
		                      nexxt = { value = "novissimo",
		                                nexxt = { value = 50,
		                                          nexxt = nil}}}}
		assert.same (list.new(42, 50):replace(42, "novo", "novissimo"), l)
	end)
	
	test("Replacing the last element with two elements", function()
		local l = { value = "head",
		            nexxt = { value = "first",
		                      nexxt = { value = "novo",
		                                nexxt = { value = "novissimo",
		                                          nexxt = nil}}}}
		assert.same (list.new("first", "last"):replace("last", "novo", "novissimo"), l)
	end)
	
	test("Replacing an absent element from a list", function()
		local l = { value = "head",
		            nexxt = { value = 42,
		                      nexxt = { value = 50,
		                                nexxt = nil}}}
		assert.same(list.new(42, 50):replace(10), l)
	end)
	
	test("Value of the first element a list", function()
		assert.same(list.new(42, 50):head(), 42)
		assert.same(list.new({44}, 50):head(), {44})
	end)
	
	test("Tail of a list", function()
		local l = { value = 42,
		            nexxt = { value = 50,
		                      nexxt = nil}}
		assert.same(list.new(42, 50):tail(), l)
		
		local l2 = list.new(42, 50)
		assert.equal(l2:tail(), l2.nexxt)
	end)
	
end)
