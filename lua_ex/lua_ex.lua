--[[
Seed基础插件：lua_ex

	版本：
		0.2

	最后修改日期：
		2012-12-12
	
	更新记录：
		2012-12-12：
			修改了bind函数
			增加了弱key and value引用表
			增加了warning，assert函数
			增加utf-8向unicode的转换函数
]]

function nop()
end

function values(...)
    return ...
end

function toboolean(v)
	return (v and true) or false
end

function is_function(v)
	return 
		type(v) == 'function' or
			((type(v) == 'table' or type(v) == 'userdata') and
				getmetatable(v) and is_function(getmetatable(v).__call))
end

local wkt = {__mode = "k"}
local wvt = {__mode = "v"}
local wwt = {__mode = "kv"}
function newWeakKeyTable()
	local ret = {}
	setmetatable(ret, wkt)
	return ret
end

function newWeakValueTable()
	local ret = {}
	setmetatable(ret, wvt)
	return ret
end

function newWholeWeakTable()
	local ret = {}
	setmetatable(ret, wwt)
	return ret
end
local unpack = table.unpack
function bind(f, ...)
    local args = {...}
    return function ()
        return f(unpack(args))
    end
end

function true_()
    return true
end

function false_()
    return false;
end

function string:topattern()
    local ret = self:gsub("%p", "%%%1")
    return ret
end

function string:replace(str, repl)
    local ret= self:gsub(str:topattern(), repl:topattern())
	return ret
end

function string:split(pattern, plain, trimEmpty)
    if (plain) then
        pattern = pattern:topattern()
    end
    local t={}
    local p=1
    for pos,to in string.gmatch(self, "()"..pattern.."()") do
        if ((not trimEmpty) or (p ~= pos)) then
            table.insert(t, self:sub(p,pos - 1))
        end
        p = to
    end
    if ((not trimEmpty) or (p<=#self)) then
        table.insert(t, self:sub(p))
    end
    return t
end

function string:startsWith(t)
	return self:sub(1, #t) == t
end

function string:endsWith(t)
	return self:sub(-#t ) == t
end

function table:keys()
    local ret = {}
    for k,v in pairs(self) do
        table.insert(ret, k)
    end
    return ret
end

function table:find(val)
	for i,v in ipairs(self) do
		if (v == val) then
			return i
		end
	end
end

function table:findVal(val)
	for k,v in pairs(self) do
		if (v == val) then
			return k
		end
	end
end

function table:removeVal(val)
	if val == "nil" then 
		error("shoule give a value,got nil")
	end
	table.remove(self,table.findVal(self,val))
end
function table:clone()
	local ret = {}
	for k,v in pairs(self) do
		ret[k] = v
	end
	return ret
end

function table:findFirst()
	for k, v in pairs(self) do
		if k and v then	
			return k, v
		end
	end
end

function table:getLength()
	local ret = 0
	for k, v in pairs(self) do
		ret = ret + 1
	end
	return ret
end

function math.sign(n)
	if (n > 0) then
		return 1
	elseif (n < 0) then
		return -1
	else
		return 0
	end
end

function __FILE__(lvl) 
	lvl = lvl or 1
    local s = debug.getinfo(lvl+1,'S').source 
    if (s:sub(1,1) ~= '@') then
		return '/'
    end
    return s:sub(2)
end

function __LINE__(lvl) 
	lvl = lvl or 1
    return debug.getinfo(lvl+1, 'l').currentline 
end

function __FUNCTION__(lvl) 
	lvl = lvl or 1
    return debug.getinfo(lvl+1, 'n').name
end

local level_ = 1

local function _getSpace(level)
	local ret = ""
	for i = 1, level do
		ret = ret .. "    "
	end
	if level > 1 then
		ret = ret-- .. "|-  "
	end
	return ret
end

function printTable(t, maxLevel)
	maxLevel = maxLevel or 6
	if t == nil then
		print(t)
		return
	end
	for k, v in pairs(t) do
		if type(k) == "number" then k = "[" .. k .. "]" end
		if maxLevel < level_ then
			return 
		end
		print(_getSpace(level_), k, "=" , v)
		if type(v) == "table" then
			level_ = level_ + 1
			printTable(v, maxLevel)
			level_ = level_ - 1
		end
	end
end

function outTable(t, maxLevel)
	maxLevel = maxLevel or 6
	if t == nil then
		print(t)
		return
	end
	local v_str
	for k, v in pairs(t) do
		if type(k) == "number" then k = "[" .. k .. "]" end
		if maxLevel < level_ then
			return 
		end
		if not v then
			v_str = "nil,"
		end
		if type(v) == "string" then
			v_str = '\"' .. v .. '\",'
		elseif type(v) == "table" then
			v_str = "{"
		elseif type(v) == "boolean" then
			v_str = (v and "true") or "false" .. ","
		else
			v_str = v .. ","
		end
		print(_getSpace(level_) .. k, "=" , v_str)
		if type(v) == "table" then
			level_ = level_ + 1
			outTable(v, maxLevel)
			level_ = level_ - 1
			print(_getSpace(level_) .. "},")
		end
	end
end

--是否近似相等，浮点数在经过运算后会产生误差，通常它们之间的比较都使用近似相等
function math.epsEqual(a, b)
	local eps = 0.000001
	local r = a - b
	return -eps < r and r < eps
end

function getGlobal(name, _initTbl)
	local pkg, rn = name:match("(.+)%.(%w*)")
	if (pkg) then
		pkg = getGlobal(pkg, _initTbl)
		if (not pkg) then
			return nil
		end
	else
		pkg = _G
		rn = name
	end
	if (_initTbl and not pkg[rn]) then
		pkg[rn] = {}
	end
	return pkg[rn]
end

function setGlobal(name, val)
	local pkg, rn = name:match("(.+)%.(%w*)")
	if (pkg) then
		pkg = getGlobal(pkg, true)
	else
		pkg = _G
		rn = name
	end
	pkg[rn] = val
end

function warning(msg)
	print('Warning: '..msg..'\n'..debug.traceback())
end

function assert(cond, msg)
	if (not cond) then
		warning(msg or 'Assertion Failed.')
	end
end

function _G:addEventListener(name, ...)
	local ev = self[name]
	if (ev == nop or not ev) then
		ev = event.Dispatcher.new()
		self[name] = ev
	end
	ev:addListener(...)
end

function _G:removeEventListener(name, ...)
	local ev = rawget(self, name)
	if (ev) then
		ev:removeListener(...)		
	else
		warning("Listener was not added.")
	end
end

function _G:dispatchEvent(name, ...)
	local ev = rawget(self, name)
	if (ev) then
		ev(...)
	end
end

function _G:dispatchEventWithSelf(name, ...)
	local ev = rawget(self, name)
	if (ev) then
		ev(self, ...)
	end
end

function copyMap(map, to)
	to = to or {}
	for k,v in pairs(map) do
		to[k] = v
	end
	return to
end

function mergeMap(base, override)
	return copyMap(override, copyMap(base))
end

--[[
read lines from a stream.
sample:
local fd = io.open("res://main.lua", "r")
local i = 0
for line in fd:lines() do -- or lines(fd)
	i = i +1
	print(i..':\t', line)
end
fd:close()
]]
function lines(fd)
	local buf = ""
	local function get_line()
		if (not buf) then
			return buf
		end
		while (true) do
			local line, rest
			line, rest = buf:match("([^%\n]*)%\n(.*)")
			if (line) then
				buf = rest
				return line
			end

			local tmp = fd:read(512)
			if (not tmp) then
				tmp, buf = buf, nil
				return tmp
			end

			buf = buf..tmp
		end
	end
	return get_line, nil, nil
end

io.InputFileStream.methods.lines = lines

function utf8_2_unicode(str)
	local ret = {}

	local i = 1
	local l = #str
	while (i<=l) do
		local ch = str:byte(i) or 0

		if (ch < 0x80) then
		elseif (ch < 0xC0) then
			ch = 63  -- '?' char
		elseif (ch < 0xE0) then
			local ch1 = str:byte(i) or 0
			i = i+1
			ch = bit32.lshift(bit32.band(ch, 0x1F), 6) + bit32.band(ch1, 0x3F)
		elseif (ch < 0xF0) then
			local ch1 = str:byte(i+1) or 0
			local ch2 = str:byte(i+2) or 0
			i = i+2
			ch = bit32.lshift(bit32.band(ch, 0x1F), 12) 
				+ bit32.lshift(bit32.band(ch1, 0x3F), 6) 
				+ bit32.band(ch2, 0x3F)
		end
		
		table.insert(ret, ch)

		i = i+1
	end

	return ret
end
