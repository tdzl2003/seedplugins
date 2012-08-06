--[[
Seed 插件
	input_ex

	包含文件：
		input_ex.lua - 提供各种按钮或其他对象的点击、长按、拖拽等事件

	依赖组件：
		无

	最后修改日期：
		2012-8-6

	更新记录：
		2012-8-6：
			当触发onTouchUp事件时，事件的参数args.x, args.y会更新为当前光标位置。

]]--

module(..., package.seeall)
local event = require("event")

local updateEvent
local handlers = {}
handlers[0] = 1

--新建一个input_ex对象
function new(runtime)
	local ret = {
	}
	setmetatable(ret, {__index = input_ex})
	local function tl(ev)
		ret:dispatchEvent(ev)
	end
	
	input.touch:addEventListener(tl)
	
	local el = function(t, dt)
		for i = 1, handlers[0] do
			local v = handlers[i]
			if (v) then
				v.time = v.time + dt
				updateEvent(v)
			end
		end
	end
	runtime.enterFrame:addEventListener(el)
	
	local e2 = function()
		ret:remove()
	end
	runtime.destroy:addEventListener(e2)
	
	function ret.remove()
		input.touch:removeEventListener(tl)
		runtime.enterFrame:removeEventListener(el)
		runtime.destroy:removeEventListener(e2)
	end
	return ret
end

-- 增加新的Node
function addNode(input, node)
	assert(not node.host)
	node.host = input
	if (not input.first) then
		input.first = node
		input.last = node
	else
		node.prev = input.last
		input.last.next = node
		input.last = node
	end
end

--移除Node
function removeNode(input, node)
	assert(node.host == input)
	if (input.first == node) then
		input.first = node.next
	end
	if (input.last == node) then
		input.last = node.prev
	end
	if (node.prev) then
		node.prev.next = node.next
	end
	if (node.next) then
		node.next.prev = node.prev
	end
	node.host = nil
	node.prev = nil
	node.next = nil
end

local nodemt = {
	__index = {
		remove = function(n)
			if (n.host) then
				n.host:removeNode(n)
			end
		end,
		testHit = function(n, x, y)
			return true
		end
	}
}

local circle_testhit = function(n, x, y)
			local dx = n.x - x
			local dy = n.y - y
			return (dx*dx + dy*dy <= n.sr)
		end

local rect_testhit = function(n,x,y)
			return (x > n.x and x < n.r and y > n.y and y < n.b)
		end

--事件列表
local events = {"onTap", "onHold", "onDragBegin", "onDragging", "onDragEnd", "onTouchDown", "onTouchUp"}

local function initNode(n)
	for i,v in ipairs(events) do
		n[v] = event.Dispatcher.new()
	end
	n.hitable = true
	--n.dragable = nil
	--n.holdable = nil
	setmetatable(n, nodemt)
end

--增加一个圆形的判定区域
function addCircle(input, x, y, r)
	local ret = {x = x, y = y, r = r, sr = r*r}
	initNode(ret)
	ret.testHit = circle_testhit
	addNode(input, ret)
	return ret
end

--增加矩形判定区域
function addRect(input, x, y, w, h)
	local ret = {x = x, y = y, w = w, h = h, r= x + w, b = y + h ,sr = w*h}
	initNode(ret)
	ret.testHit = rect_testhit
	addNode(input,ret)
	return ret
end

--为整个屏幕创建一个判定区域
function addScreenMask(input)
	local ret = {}
	initNode(ret)
	addNode(input,ret)
	return ret
end

local function sc_testhit(n, x, y)
	if (not n.sprite:isVisible()) then
		return false
	end
	x,y = n.sprite:screenToLocal(x,y)
	return (x*x+y*y < n.sr)
end

--为一个Sprite对象增加圆形判定区域
function addSpriteCircle(input, sprite, r)
	local ret = {
		r = r,
		sr = r * r,
		sprite = sprite,
		testHit = sc_testhit,
		remove = s_remove
	}
	initNode(ret)
	local oldremove = sprite.remove
	sprite.remove = function()
		if (ret.host) then
			ret.host:removeNode(ret)
		end
		oldremove(sprite)
	end
	ret.remove = sprite.remove
	addNode(input,ret)
	return ret
end

local function sr_testhit(n,x,y)
	if (not n.sprite:isVisible()) then
		return false
	end
	x,y = n.sprite:screenToLocal(x,y)
	return ((x > n.l) and (x < n.r) and (y > n.t) and (y < n.b))
end

--为一个Sprite增加矩形判定区域
function addSpriteRect(input, sprite, w, h, anchorx, anchory)	
	local _ax, _ay = anchorx or 0, anchory or 0
	local _l = -w/2 - _ax * w
	local _t = -h/2 - _ay * h
	local _r = w/2 - _ax * w
	local _b = h/2 - _ay * h
	_t, _b = math.min(_t, _b), math.max(_t, _b)
	local ret = {
		l = _l,
		t = _t,
		r = _r,
		b = _b,
		sprite = sprite,
		testHit = sr_testhit,
		remove = s_remove
	}
	sprite:newNode().presentation = function()
		render2d.drawRect(l, t, r, b)
	end
	initNode(ret)
	local oldremove = sprite.remove
	sprite.remove = function()
		if (ret.host) then
			ret.host:removeNode(ret)
		end
		oldremove(sprite)
	end
	ret.remove = sprite.remove
	addNode(input,ret)
	return ret
end

local function translateEvent(ev, index)
	local time = ev.time
	local oev = {index = index, 
		x = ev.x, y = ev.y, vx = 0, vy = 0, time = time,
		startx = ev.x, starty = ev.y, starttime = time }
	handlers[index] = oev
	
	handlers[0] = math.max(handlers[0], index)
	return oev
end

local last_ev = {}

local function initArgs(ev, vx, vy)
	last_ev.time = ev.time
	last_ev.x = ev.x
	last_ev.y = ev.y
	last_ev.vx = vx or 0
	last_ev.vy = vy or 0
end

local function calcVelocity(ev)
	local dt = ev.time - last_ev.time
	if dt > 0.02 then
		ev.vx = (ev.x - last_ev.x) / dt
		ev.vy = (ev.y - last_ev.y) / dt
		initArgs(ev, ev.vx, ev.vy)
	else
		ev.vx = last_ev.vx
		ev.vy = last_ev.vy
	end
	return ev
end

local function calcArgs(ev, index)
	local oev = handlers[index]
	if oev.done then
		oev.vx, oev.vy = 0, 0
		return oev 
	end
	oev.x, oev.y = ev.x, ev.y
	
	return calcVelocity(oev)
end

--计算事件参数
local function __combineEvent(ev, index)
	local oev = handlers[index]
	
	if (oev.done) then
		return oev
	end
	
	local x = ev.x
	local y = ev.y
	local time = ev.time
	local dt = time - oev.time
	--瞬时速度
	if dt ~= 0 then
		oev.vx = (x - oev.x) / dt
		oev.vy = (y - oev.y) / dt
	end

	--平均速度
--	oev.vx = (x - oev.startx) / (time - oev.starttime)
--	oev.vy = (y - oev.starty) / (time - oev.starttime)
	
	oev.x = x
	oev.y = y
	oev.time = time
	
	--updateEvent(oev)
	return oev
end

--更新事件的状态，此函数会在每帧执行
function updateEvent(ev)
	if (ev.done) then
		return ev
	end
	local t = ev.target
	if (ev.isDragging) then
		t:onDragging(calcVelocity(ev))
	else
		local dx = ev.x - ev.startx
		local dy = ev.y - ev.starty
		local dt = ev.time - ev.starttime
		if (t.dragable) then
			if ( (math.abs(dx) + math.abs(dy) > 5) or (dt > 1 and not t.holdable) ) then
				t:onDragBegin(ev)
				ev.isDragging = true
				return
			end
		end
		
		if (t.holdable) then
			if (dt > 1) then
				t:onHold(ev)
				ev.done = true
			end
		end
	end
end

--派发事件，此函数会在出现input.touch事件后执行
function dispatchEvent(input, ev)
	local index = ev.index
	local type = ev.type
	--这两个变量的作用，在onTouchUp的时候能够使第二个参数的field：x, y为当前光标所在位置
	local x, y = ev.x, ev.y

	if (ev.type == "down") then
		ev = translateEvent(ev, index)
		initArgs(ev)
	
		local p = input.last
		while (p) do
			if (p:testHit(ev.x, ev.y)) then
				p:onTouchDown(ev)
				ev.target = p
				if (not (p.dragable or p.holdable)) then
					p:onTap(ev)
					ev.done = true
				end
				break
			end
			p = p.prev
		end
		if (not ev.target) then
			ev.done = true
		end
	else
		if (not handlers[index]) then
			return
		end
		ev = calcArgs(ev, index)
		local p = ev.target
		if (type == "up" and p) then
			if (not ev.done and not ev.isDragging) then
				p:onTap(ev)
			end
			if (ev.isDragging) then
				p:onDragEnd(ev)
			end
			ev.x, ev.y = x, y
			p:onTouchUp(ev)
			handlers[index] = nil
		end
	end
end

--[[

=======================input_ex使用说明=========================

	1、创建：
		input_ex = require("input_ex").new()
	
	2、创建event对象：
		event = input_ex:addScreenMask()
		event = input_ex:addCircle()
		event = input_ex:addRect()
		event = input_ex:addSpriteCircle()
		event = input_ex:addSpriteRect()

	3、给event对象的事件添加监听器：
		event.onTap:addListener(function(event, args)
			--TODO Add function body here 
		end)

		event包含如下事件：
			"onTap"		- 点击，按下后并松开时触发一次
			"onHold"	- 按住超过一秒，触发一次，需要将holdable设为true
			"onDragBegin"	- 开始拖拽动作，触发一次，需要将dragable设为true
			"onDragging"	- 拖拽中，每帧触发一次，需要将dragable设为true
			"onDragEnd"		- 拖拽结束，触发一次，需要将dragable设为true
			"onTouchDown"	- 任何情况下，按下触发一次
			"onTouchUp"		- 任何情况下，松开触发一次

		参数event是event对象本身

		参数args是一个table，包含如下value：
			isDragging - 是否处于拖拽的状态
			starttime - 开始触摸屏幕的时间点，等同onTouchDown事件发生时的时间
			time - 当前事件触发时的时间点
			startx - 
			starty - 开始触摸时，光标或手指的位置
			x 
			y - 当前事件触发时，光标或手指的位置
			vx
			vy - 当前的x，y方向的速度（平均速度，非瞬时速度）

	附注：
		不同情况下事件的执行过程：
		按住超过一秒，抬手：onTouchDown -> onHold -> onTouchUp
		按住并拖动拖动、抬手：onTouchDown -> onDragBegin -> onDragging(重复n次，n为拖拽的帧数) -> onDragEnd -> onTouchUp
		按下之后，在小于一秒的时间内抬手：onTouchDown -> onTap -> onTouchUp

]]--