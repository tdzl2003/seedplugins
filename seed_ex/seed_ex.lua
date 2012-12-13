--[[
Seed基础插件：seed_ex

	版本：
		0.21

	最后修改日期：
		2012-12-13
	
	更新记录：
		2012-12-13:
			恢复了误删的函数 _callobj

		2012-12-12：
			可以支持Fangus框架
]]

require("lua_ex")
local stringize = require("stringize")
local classes = {}
local weakClasses = newWeakValueTable()
local Class

local function _dumpobj(obj)
	return "Object " .. (obj.type.name or "(noname)")-- .. "\n" .. (stringize(obj) or '')
end

local function _callobj(obj, ...)
	local f = obj.__call or error("Object " .. ((obj.type and obj.type.name) or "(noname)") .. " do not have a __call method while be called.")
	return f(obj, ...)
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
		super = requireClass(super)
	end
	
	assert(name)
	
	local ret = statics or  {}
	setmetatable(methods, super)
	
	ret.name = name
	ret.super = super
	ret.methods = methods
	ret.__index = methods
	methods.type = ret
	ret.__tostring = ret.__tostring or _dumpobj

	ret.__call = ret.__call or _callobj
	
	if (Class) then
		setmetatable(ret, Class)
	end
	
	if (name) then
		classes[name] = ret
		weakClasses[name] = ret
	end
	
	return ret
end

function define_type(name, methods, statics)
	return extend_type(name, methods, nil, statics)
end


local _Class = {}

function _Class:isDerived(super)
	local thiz = self
	repeat
		if (thiz == super) then
			return true
		end
		thiz = thiz.super
	until not thiz
	return false
end

Class = define_type("Class", _Class)
_Class.type = Class
setmetatable(Class, {__index == _Class, __tostring = _dumpobj})
Class.name = "Class"
Class.type = Class

function Class.__index(t, k)
	if (type(k) == 'string') then
		local newWith = k:match("new(%w*)")
		if (newWith) then
			local init = t.methods["__init__" .. newWith]
			if (init or (newWith == '')) then
				return function(...)
					local obj = {}
					setmetatable(obj, t)
					return (init and init(obj, ...)) or obj
				end
			end
		end
	end
	return _Class[k]
end

local function checkClass(cls)
	local ret
	return cls and cls.type == Class
end

function requireClass(name)
	local ret = weakClasses[name]
	if (ret) then
		if (not classes[name]) then
			classes[name] = ret
		end
		return ret
	end
	--print("loading Class " .. name)
	ret = doscript(name) or weakClasses[name]
	assert(ret and checkClass(ret), 'Module ' .. name.. " does not provide a class")
	
	classes[name] = ret
	weakClasses[name] = ret
	return ret
end

function releaseUnusedClasses()
	classes = {}
end

require("director").enterModule:addListener(releaseUnusedClasses)
