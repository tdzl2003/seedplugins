
require("seed_ex")

local ui = {}
ui._VER = 2

_G.ui = ui

-- 记录所有直接注册的结点
local roots = {}

local Node = {}

function Node:__init__(node)
	-- TODO: node.removed事件，也干掉自己。
	self._node = node
	self._childs = {}
	
	-- 触摸事件的监听者。
	-- TODO:乍一想貌似可以用event.Dispatcher了。
	self._listeners = {}
end

-- node也可以是stage
-- 用Node.newRoot方法。
function Node:__init__Root(rta, node)
	self:__init__(node)

	-- 注册root结点
	table.insert(roots, self)
	
	-- 响应runtimeAgent:destroy事件
	local function destroyf()
		self:remove()
	end
	rta.destroy:addListener(destroyf)
	
	function self:remove()
		self.remove = nil
		rta.destroy:removeListener(destroyf)
		
		local i = table.find(roots, self)
		assert(i)
		table.remove(roots, i)
		
		Node.methods.remove(self)
	end
end

function Node:remove()
	if (self._node) then
		self._node._ui = nil
	end
	if (self._parent) then
		local t = self._parent._childs
		local i = table.find(t, self)
		assert(i)
		table.remove(t, i)
		self._parent = nil
	end
	for i,v in ipairs(self._childs) do
		v._parent = nil
		v:remove()
	end
end

function Node:addChild(child)
	local cp = child._node.parent
	assert(cp == self._node or (not cp and child._node.stage == self._node))
	child._parent = self
	table.insert(self._childs, child)
end

function Node:withShape(shape)
	self._shape = shape
	return self
end

function Node:withScissor(shape)
	self._scissor = shape
	return self
end

--TODO: 此为临时方案。
function display.screenToContent(x, y)
	local vw, vh = display.getViewSize()
	local cw, ch = display.getContentSize()
	local cs = display.getContentScale()
	return (x-vw/2)*cs+cw/2, (y-vh/2)*cs+ch/2
end

function Node:dispatchTouch(ev, x, y)
	if (not self._node:isVisible()) then
		return
	end
	
	if (self._parent) then
		x, y = self._node:parentToLocal(x, y)
	else
		x, y = self._node:screenToWorld(ev.x, ev.y)
	end

	-- 判断裁剪区域
	if (self._scissor and not self._scissor:test(x, y)) then
		return
	end
	
	local ret
	-- 检查所有的孩子
	for i = #self._childs, 1, -1 do
		local v = self._childs[i]
		v:dispatchTouch(ev, x, y)
		if (ev:captured()) then
			break
		end
	end
	
	-- 处理自身的判定
	if (not ev:exclusive() and
		self._shape and self._shape:test(x, y)) then
		
		for i,v in ipairs(self._listeners) do
			v(self, ev, x, y)
		end
	end
end

Node = define_type("ui.Node", Node)

--触摸事件的处理
local points = {}

local TouchEvent = requireClass("ui.TouchEvent")

local function _mergeTouchInfo(ev)
	local id = ev.index
	local ret
	
	if (ev.type == "down") then
		assert(not points[id])
		ret = TouchEvent.new(ev)
		--用于计算速度的上一次坐标
		ret.lx,ret.ly = ev.x, ev.y
		ret.vx,ret.vy = 0,0
		points[id] = ret
	else
		--当index1抬起后再抬起index2，会出现index2又执行了一次move，初步判定是framework的一点问题
		--已在build：125中解决
		ret = points[id]
		assert(ret)
		if not ret then return end
		ret.type = ev.type
		ret.x, ret.y = ev.x, ev.y
		
		if (ev.time > ret.time + 0.005) then
			local dt = ev.time - ret.time
			local dx, dy = ev.x - ret.lx, ev.y - ret.ly
			ev.vx, ev.vy = dx/dt, dy/dt
			ret.lx, ret.ly = ev.x, ev.y
			ret.time = ev.time
		end
		if (ev.type == "up") then
			points[id] = false
		end
	end
	return ret
end

local function _dispatchTouch(ev)
	local t = ev.type
	
	ev = _mergeTouchInfo(ev)
	if not ev then return end
	
	if (t == 'down') then
		for i = #roots,1,-1 do
			roots[i]:dispatchTouch(ev)
		end
		if (not ev:captured() and not ev:listened()) then
			ev:over()
		end
	elseif (t == 'up') then
		ev:touchUp()
	elseif (t == 'move') then
		ev:update()
	end
end

local function _updateTouch(t)
	for i,v in ipairs(points) do
		if (v and not v:overed()) then
			v.type = 'time'
			v.time = t
			v:update()
		end
	end
end

input.touch:addListener(_dispatchTouch)
runtime.enterFrame:addListener(_updateTouch)

-- ui.registerNode函数
function ui.registerNode(rta, node, type)
	assert(not node or not node._ui)
	if (node.type == display.Stage2D) then
		local n = (type or Node).newRoot(rta, node)
		node.isVisible = node.isVisible or true_
		node._ui = n
		return n
	elseif (node.type == display.Stage2D.Node) then
		local pn = node.parent or node.stage
		local pui = pn._ui or ui.registerNode(rta, pn)
		
		local n = (type or Node).new(node)
		pui:addChild(n)
		node._ui = n
		return n
	end
end

function ui.getOrRegisterNode(rta, node, type)
	return (node and node._ui) or ui.registerNode(rta, node, type)
end

function ui.register(rta, type)
	local ret = (type or Node).newRoot(rta)
	ret._node = ret
	function ret:screenToWorld(x, y)
		return display.screenToContent(x, y)
	end
	ret.isVisible = true_
	return ret
end

require("ui.tap")
require("ui.hold")
require("ui.drag")
require("ui.touch")
ui.Circle = require("ui.Circle")
ui.Rect = require("ui.Rect")
ui.ScreenMask = require("ui.ScreenMask")

return ui
