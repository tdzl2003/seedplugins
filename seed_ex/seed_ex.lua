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
	
	local super = clazz.super
	
	while (super) do
		for k,v in pairs(super.methods) do
			if (type(k) == 'string' and is_function(v) and
				k:sub(1, 8) == '__init__') then
				local n = 'new'..k:sub(9)
				clazz[n] = clazz[n] or function(...)
					local obj = {}
					setmetatable(obj, clazz)
					return v(obj, ...) or obj
				end

			end
		end
		super = super.super
	end

	clazz.new = clazz.new or function()
		local obj = {}
		setmetatable(obj, clazz)
		return obj
	end
end

local function isDerived(thiz, super)
	repeat
		if (thiz == super) then
			return true
		end
		thiz = thiz.super
	until not thiz
	return false
end

function extend_type(name, methods, super, statics)
	if (type(super) == 'string') then
		super = getGlobal(super) or require(super)
	end
	
	local ret = statics or  {}
	setmetatable(methods, super)
	
	ret.name = name
	ret.super = super
	ret.methods = methods
	ret.__index = methods
	ret.__index.type = ret
	ret.__tostring = ret.__tostring or _dumpobj
	ret.isDerived = isDerived
	_init_newfuncs(ret, methods)
	
	if (name) then
		setGlobal(name, ret)
	end
	return ret
end

function define_type(name, methods, statics)
	return extend_type(name, methods, nil, statics)
end


