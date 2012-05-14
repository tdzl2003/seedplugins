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

function linearAttrPeriod(target, attr, time, from, to)
	target[attr] = from
	if (time > 0) then
		timePeriod(time, function(t)
			target[attr] = (t / time) * (to - from) + from
		end)
	end
	target[attr] = to
end

function linearAttrPeriodEx(target, time, attrs)
    for k,v in ipairs(attrs) do 
    	target[v[1]] = v[2]
    end
	if (time > 0) then
		timePeriod(time, function(t)
            for k,v in ipairs(attrs) do 
                target[v[1]] = (t / time) * (v[3] - v[2]) + v[2]
            end
		end)
	end
    for k,v in ipairs(attrs) do 
    	target[v[1]] = v[3]
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

