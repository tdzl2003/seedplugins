require("lua_ex")
local stringize = require("stringize")

local function _dumpobj(obj)
	return "Object " .. (obj.type.name or "(noname)") .. "\n" .. (stringize(obj) or '')
end

local function _init_newfuncs(clazz, methods)
	for k,v in pairs(methods) do
		if (type(k) == 'string' and is_function(v) and
			k:sub(1, 8) == '__init__') then
			
			clazz['new'..k:sub(9)] = function(...)
				local obj = {}
				setmetatable(obj, clazz)
				return v(obj, ...) or obj
			end

		end
	end

	clazz.new = clazz.new or function()
		local obj = {}
		setmetatable(obj, clazz)
		return obj
	end
end

function define_type(name, methods, statics)
	local ret = statics or  {}
	
	ret.name = name
	ret.methods = methods
	ret.__index = methods
	ret.__index.type = ret
	ret.__tostring = ret.__tostring or _dumpobj
	_init_newfuncs(ret, methods)
	
	load(name..'=...')(ret)
	return ret
end

function extend_type(name, methods, super, statics)
	local ret = statics or  {}
	setmetatable(methods, super)
	
	ret.name = name
	ret.super = super
	ret.methods = methods
	ret.__index = methods
	ret.__index.type = ret
	ret.__tostring = ret.__tostring or _dumpobj
	_init_newfuncs(ret, methods)
	
	load(name..'=...')(ret)
	return ret
end
