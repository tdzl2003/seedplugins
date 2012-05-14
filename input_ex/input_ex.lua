module(..., package.seeall)
require("lua_ex")
local event = require("event")
--TODO: 提供C++版本以优化各种操作

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

function addCircle(input, x, y, r)
	local ret = {x = x, y = y, r = r, sr = r*r}
	initNode(ret)
	ret.testHit = circle_testhit
	addNode(input, ret)
	return ret
end

function addRect(input, x, y, w, h)
	local ret = {x = x, y = y, w = w, h = h, r= x + w, b = y + h ,sr = w*h}
	initNode(ret)
	ret.testHit = rect_testhit
	addNode(input,ret)
	return ret
end

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
	local time = ev.time / 1000
	local oev = {index = index, 
		x = ev.x, y = ev.y, vx = 0, vy = 0, time = time,
		startx = ev.x, starty = ev.y, starttime = time, }
	handlers[index] = oev
	
	handlers[0] = math.max(handlers[0], index)
	return oev
end

function updateEvent(ev)
	if (ev.done) then
		return ev
	end
	
	local t = ev.target
	if (ev.isDragging) then
		t:onDragging(ev)
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

local function combineEvent(ev, index)
	local oev = handlers[index]
	
	if (oev.done) then
		return oev
	end
	
	local x = ev.x
	local y = ev.y
	local time = ev.time / 1000
	local dt = time - oev.time
	
	if (dt > 0) then
		oev.vx = (x - oev.x) / dt
		oev.vy = (y - oev.y) / dt
	end
	oev.x = x
	oev.y = y
	oev.time = time
	
	updateEvent(oev)
	return oev
end

function dispatchEvent(input, ev)
	local index = ev.index + 1
	local type = ev.type

--	print(ev.type)
	if (ev.type == "down") then
		ev = translateEvent(ev, index)
	
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
		ev = combineEvent(ev, index)
		local p = ev.target
		if (type == "up" and p) then
			if (not ev.done and not ev.isDragging) then
				p:onTap(ev)
			end
			if (ev.isDragging) then
				p:onDragEnd(ev)
			end
			p:onTouchUp(ev)
			handlers[index] = nil
		end
	end
end
