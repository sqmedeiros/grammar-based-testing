local parser = require'parser'
local bnf = require'bnf'
local minderiv = require'minderiv'

local g = parser.match[[
rulelist   <-   rule_*
rule_   <-   ID '=' '/'? elements 
elements   <-   alternation 
alternation   <-   concatenation ('/' concatenation )* 
concatenation   <-   repetition+ 
repetition   <-   repeat? element 
repeat   <-   INT   /  (INT? '*' INT? ) 
element   <-   ID   /  group   /  option   /  string   /  NumberValue   /  ProseValue 
group   <-   '(' alternation ')' 
option   <-   '[' alternation ']' 
--NumberValue   <-   '%' (BinaryValue  /  DecimalValue  /  HexValue)
NumberValue       <- NumberValueBin1 / NumberValueBin2 / NumberValueDec1 / NumberValueDec2 / NumberValueHex1 / NumberValueHex2
NumberValueBin1   <-   '%b0.022'
NumberValueBin2   <-   '%b1'
NumberValueDec1   <-   '%d2-34'
NumberValueDec2   <-   '%d0'
NumberValueHex1   <-   '%xf.ff.3.4'
NumberValueHex2   <-   '%xa'
--BinaryValue   <-   'b' BIT+ (('.' BIT+)+  /  ('-' BIT+))?
--DecimalValue   <-   'd' DIGIT+ (('.' DIGIT+)+  /  ('-' DIGIT+))?
--HexValue   <-   'x' HEX_DIGIT+ (('.' HEX_DIGIT+)+  /  ('-' HEX_DIGIT+))?
ProseValue   <-   '<' 'muito texto' '>'
ID   <-   'a'
INT   <-   '1'
COMMENT   <-   ';' 'line comment' '\n'
string   <-   ('%s'  /  '%i')? '"' 'a' '"'
LETTER   <-   'a'
BIT   <-   '0' / '1'
DIGIT   <-   '1'
HEX_DIGIT   <-   ('1'  /  'f'  /  'F')
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

mind:generate({ file = true, ext = 'abnf', dir = dir} )


