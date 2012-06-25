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

local unpack = table.unpack
function bind(f, ...)
    local args = {...}
    return function (...)
        local v = table.pack(unpack(args))
        for i = 1, select('#', ...) do
            local v1 = select(i, ...)
            table.insert(v, v1)
        end
        return f(unpack(v))
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

function printTable(t, lv)
	max_level = lv or 8
	if t == nil then
		print(t)
		return
	end
	for k, v in pairs(t) do	
		if type(k) == "number" then k = "[" .. k .. "]" end
		print(_getSpace(level_), k, "=" , v)
		if type(v) == "table" then
			level_ = level_ + 1
			if level_ <= max_level then
				printTable(v)
			else
				level_ = 1
				return
			end
			level_ = level_ - 1
		end
	end
end

