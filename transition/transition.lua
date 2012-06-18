--[[
Seed插件：
	transition - 用来控制物体在确定时间内，状态的平滑变化，常用于node的移动、旋转、缩放
	包含文件：
		transition.lua
	依赖于：
		无
	最后修改日期：
		2012-6-18
	更新记录：
			
]]
module(..., package.seeall)

local c_create = coroutine.create
local c_resume = coroutine.resume
local c_yield = coroutine.yield
local c_running = coroutine.running

local t_insert = table.insert

local runnings = {}
setmetatable(runnings, {__mode = "k"})

function current()
	local co = c_running()
	return runnings[co]
end

local trmt = {
	__index = {
		addFinalizer = function(self, func)
			t_insert(self.finstack, func)
		end,
		doFinalizer = function(self)
			local s = self.finstack
			local len = #s
			if (len > 0) then
				s[len](self)
				s[len] = nil
				return true
			end
			return false
		end,
	}
}

local resume = function(self, ...)
	local co, ma = c_running()
	local st, er = c_resume(self.co, ...)
	if (not st) then
		print("error occured in transition:")
		print(debug.traceback(self.co, er))
		runnings[self.co] = nil
		while(self:doFinalizer()) do
		end
	end
end

local function bind(f, s)
	return function(...)
		f(s, ...)
	end
end

local function entry(tr, f, pars)
	runnings[tr.co] = tr
	f(table.unpack(pars))
	runnings[tr.co] = nil
end

function start(rt, f, ...)
	local pars = {...}
	local co = c_create(entry)
	local ret = {
		runtime = rt,
		co = co,
		finstack = {},
		onerror = event.Dispatcher.new()
	}
	setmetatable(ret, trmt)
	
	resume(ret, ret, f, pars)
	return ret
end

function pausePeriod(tr)
	if (tr.rel) then
		local f = tr.rel
		tr.rel = nil
		return f(tr), f
	end
end

function recoverPeriod(tr, ups, rel)
	if (ups) then
		ups(tr)
	end
	tr.rel = rel
end

function wait(time)
	local tr = current()
	local upstate, rel = pausePeriod(tr)
	tr.rel = bind(error, "should not pause in wait period")
	tr.runtime:setTimeout(function()
		resume(tr)
	end, time)
	c_yield()
	recoverPeriod(tr, upstate, rel)
end

local function timePeriod_Finalizer(tr)
	local ef = tr.runtime.enterFrame
	ef:removeListener(tr.do_resume)
end

function timePeriod(time, update)
	local tr = current()
	local upstate, rel = pausePeriod(tr)
	
	local st = tr.runtime:getTime()
	local ef = tr.runtime.enterFrame
	local c = 0

	local do_resume = bind(resume, tr)
	local function remove_event()
		ef:removeListener(do_resume)
	end
	ef:addListener(do_resume)
	tr:addFinalizer(remove_event)
	tr.rel = function()
		ef:removeListener(do_resume)
		return function()
			ef:addListener(do_resume)
		end
	end
	while (true) do
		local t, dt = c_yield()
		c = c + dt
		if (c >= time) then
			break
		end
		update(c, dt)
	end
	tr:doFinalizer()
	
	recoverPeriod(tr, upstate, rel)
end

--[[
函数linearAttrPeriod
令某对象的某个属性在一段时间内进行线性变化：
	参数：
		target - 目标对象
		attr - 属性名称
		time - 变化时间
		from - 属性的初始值
		to - 属性的结束值

		attr也可使用函数类型，这样from就是初始状态的函数参数，to就是结束状态的参数
]]--

function linearAttrPeriod(target, attr, time, from, to)
	if type(target[attr])=="number" then
		target[attr] = from
		if (time > 0) then
			timePeriod(time, function(t)
				target[attr] = (t / time) * (to - from) + from
			end)
		end
		target[attr] = to
	else
		target[attr](target, from)
		if (time > 0) then
			timePeriod(time, function(t)
				target[attr](target, (t / time) * (to - from) + from)
			end)
		end
		target[attr](target, to)
	end
end

--[[
函数linearAttrPeriodEx
令某对象的若干个属性在一段时间内共同进行线性变化：
	参数：
		target - 目标对象
		time - 变化时间
		attrs - attrs是一个table，包含如下内容：
			{
				{属性1名称, 初始值, 结束值},
				{属性2名称, 初始值, 结束值},
				{属性3名称, 初始值, 结束值},
				...
			}

		“属性名称”也可使用函数类型，这样“初始值”就是初始状态的函数参数，“结束值”就是结束状态的参数
]]--

function linearAttrPeriodEx(target, time, attrs)
    for k,v in ipairs(attrs) do 
		if type(target[v[1]])=="number" then 
			target[v[1]] = v[2]
		else 
			target[v[1]](target, v[2])
		end
    end
	if (time > 0) then
		timePeriod(time, function(t)
            for k,v in ipairs(attrs) do 
				if type(target[v[1]])=="number" then 
					target[v[1]] = (t / time) * (v[3] - v[2]) + v[2]
				else
					target[v[1]](target, (t / time) * (v[3] - v[2]) + v[2])
				end
            end
		end)
	end
    for k,v in ipairs(attrs) do 
		if type(target[v[1]])=="number" then 
			target[v[1]] = v[3]
		else 
			target[v[1]](target, v[3])
		end
    end
end

function playActionPeriod(u, a, flag)
	local tr = current()
	local upstate, rel = pausePeriod(tr)
	tr.rel = bind(error, "should not pause in wait period")
	u:playAction(a, function()
		if (flag) then
			resume(tr)
			return true
		end
		tr.runtime:setTimeout(function()
			resume(tr)
		end)
		return false
	end, function()
			resume(tr, true)
		end)
	local canceled = c_yield()
	recoverPeriod(tr, upstate, rel)
	return not canceled
end

function playActionListPeriod(u, al, flag)
	local tr = current()
	local upstate, rel = pausePeriod(tr)
	tr.rel = bind(error, "should not pause in wait period")
	
	for i,a in ipairs(al) do
		u:playAction(a, function()
			if (i < #al) then
				resume(tr)
				return true
			else
				if (flag) then
					resume(tr)
					return true
				end
				tr.runtime:setTimeout(function()
					resume(tr)
				end)
				return false
			end
		end, function()
			resume(tr, true)
		end)
		local canceled = c_yield()
		if (canceled) then
			recoverPeriod(tr, upstate, rel)
			return false
		end
	end
	recoverPeriod(tr, upstate, rel)
	return true
end

