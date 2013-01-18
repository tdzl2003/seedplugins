-------------------------------------
-- 插件名称：transition
-- 插件版本：ver.0.2.0
-- 插件作者：Seed_ForthBlue
-- 最后修改：Seed_ForthBlue
-- 最后修改日期：2012-12-14
-------------------------------------
require("lua_ex")

local Transition = {}
local TransitionType = {
	name = "transition.Transition",
	__index = Transition,
}
Transition.type = TransitionType

local function cancelTransition(self)
	self.rtAgent.enterFrame:removeListener(self.worker)
end
Transition.cancel = cancelTransition

local function startTransition(rtAgent, worker)
	local ret = {
		worker = worker,
		rtAgent = rtAgent,
	}
	setmetatable(ret, TransitionType)

	rtAgent.enterFrame:addListener(worker)
	return ret
end

local function clamp(v, min, max)
	if (v < min) then
		return min
	elseif (v > max) then
		return max
	else
		return v
	end
end

local function interpolationTransition(rtAgent, target, time, fields, inter, callback)
	local workers = event.Dispatcher.new()
	local startTime = rtAgent:getTime()

	for k,v in pairs(fields) do
		if (type(target[k]) == 'function') then
			local startv = v.from
			local endv = v.to
			local func = target[k]
			local function work(now)
				func(target, inter(startv, endv, now))
			end
			workers:addListener()
		else
			local startv = v.from or target[k]
			local endv = v.to or target[k]
			local function work(now)
				target[k] = inter(startv, endv, now)
			end
			workers:addListener(work)
		end
	end

	local ret
	ret = startTransition(rtAgent, function (t, dt)
		local now = clamp((t - startTime)/time, 0, 1)
		if (now >= 1) then
			cancelTransition(ret)
			workers(now)
			return callback and callback(ret)
		end
		return workers(now)
	end)
	return ret
end


local function linearInter(v0, v1, x)
	return v0*(1-x) + v1*x
end

--根据传入的函数决定移动方式
local function interManager(func,ratio)
	local ratio = ratio or 1
	local func = func or values
	local function inter(v0,v1,x)
		local x = x * ratio
		local p = v0 + func(x) * (v1-v0)
		return p
	end 
	return inter
end

local function change(rtAgent, target, time, att, from, to,callback,inter)
	local inter = inter or linearInter
	return interpolationTransition(rtAgent, target, time, {
			[att] = {
				from = from,
				to = to,
			}
		}, inter, callback) 
end
local function move(rtAgent, target, time, x0, y0, x1, y1, callback)
	return interpolationTransition(rtAgent, target, time, {
			x = {
				from = x0,
				to = x1,
			}, 
			y = {
				from = y0,
				to = y1,
			}
		}, linearInter, callback)
end

local function moveTo(rtAgent, target, time, x1, y1, callback)
	return move(rtAgent, target, time, nil, nil, x1, y1, callback)
end

return {
	Transition = TransitionType,
	startTransition = startTransition,
	interpolationTransition = interpolationTransition,
	linearInter = linearInter,
	move = move,
	moveTo = moveTo,
	change = change,
	interManager = interManager,
}
