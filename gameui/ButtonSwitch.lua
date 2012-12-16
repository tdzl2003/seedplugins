local UIBase = requireClass("gameui.UIBase")
local ButtonSwitch = {}

--[[
开关按钮：拥有三种状态，开状态、关状态、无效状态


]]

--[[
data = {
	name = "switch",
	data = {
		x, y, width, height, anchorx, anchory, visible, enabled, state
		sets, normal_on, selected_on, normal_off, selected_off, disabled
	}
}

local t = {}
local buttonS = ButtonSwitch.newWithData(node, data, t)

buttonS:toNode()

t["switch_evOn"]:addList
t["switch_evOff"]
]]

function ButtonSwitch:__init__WithData(father, data, symbolTable)
	
	UIBase.methods.__init__WithData(self, father, data, symbolTable)
	--[[
	printTable(data, 3)
	print("------------------")
	printTable(self, 1)
	print("==================")
	]]
	local _data = data.data
	self.state = self.state or true
	self.enabled = self.enabled or true
	self.visible = self.visible or true
end

function ButtonSwitch:setNormal()
	if self.enabled then
		if self.state then
			self.node.presentation = self.pssNormalOn
		else
			self.node.presentation = self.pssNormalOff
		end
	end
end

function ButtonSwitch:setSelected()
	if self.enabled then
		if self.state then
			self.node.presentation = self.pssSelectedOn
		else
			self.node.presentation = self.pssSelectedOff
		end
	end
end

function ButtonSwitch:setState(flag)
	if self.enabled then
		self.state = flag
	end
end

function ButtonSwitch:getState()
	return self.state
end

function ButtonSwitch:setEnabled(flag)
	self.enabled = flag
	if flag then
		self:setNormal()
	else
		self.node.presentation = self.pssDisabled
	end
end

function ButtonSwitch:toNode(selectorTable, rta)
	UIBase.methods.toNode(self, selectorTable, rta)
	local node = self.node
	--[[
	self.node:newNode().presentation = function()
		render2d.fillCircle(0, 0, 4)
	end
	]]

	if self.sets then
		local sheet_set = Animation.newWithPlist(gameui.toAbsolute(self.sets), 0, 0)
		--开状态
		self.pssNormalOn = display.presentations.newImageRectWithAni(sheet_set, self.normal_on)
		self.pssSelectedOn = display.presentations.newImageRectWithAni(sheet_set, self.selected_on)
		--关状态
		self.pssNormalOff = display.presentations.newImageRectWithAni(sheet_set, self.normal_off)
		self.pssSelectedOff = display.presentations.newImageRectWithAni(sheet_set, self.selected_off)
		--无效状态
		self.pssDisabled = display.presentations.newImageRectWithAni(sheet_set, self.disabled)
	else
		self.pssNormalOn = display.presentations.newImage(gameui.toAbsolute(self.normal_on))
		self.pssSelectedOn = display.presentations.newImage(gameui.toAbsolute(self.selected_on))
		
		self.pssNormalOff = display.presentations.newImage(gameui.toAbsolute(self.normal_off))
		self.pssSelectedOff = display.presentations.newImage(gameui.toAbsolute(self.selected_off))

		self.pssDisabled = display.presentations.newImage(gameui.toAbsolute(self.disabled))
		
	end

	self.pssNormalOn:setAnchor(self.anchorx, self.anchory)
	self.pssSelectedOn:setAnchor(self.anchorx, self.anchory)
	self.pssNormalOff:setAnchor(self.anchorx, self.anchory)
	self.pssSelectedOff:setAnchor(self.anchorx, self.anchory)
	self.pssDisabled:setAnchor(self.anchorx, self.anchory)

	self:setState(self.state)
	self:setNormal()
	--按钮的触控区域通过shape来指定
	self.shape = {
		type = "ui.Rect",
		x = (-self.anchorx - 0.5) * self.width,
		y = (-self.anchory - 0.5) * self.height,
		w = self.width,
		h = self.height
	}

	local shape = requireClass("ui.Rect").newWithRect(self.shape.x, self.shape.y, self.shape.w, self.shape.h)
	local uiNode = ui.registerNode(rta, node):withShape(shape):catchTap():catchTouch()

	--开关按钮的事件：打开和关闭
	local evOn = event.Dispatcher.new()
	local evOff = event.Dispatcher.new()

	self.evOn = evOn
	self.evOff = evOff

	--如果selector有专门的名字，那么用指定好的名字注册到selectorTable中，否则，生成名称：name_evOn, name_evOff
	if self.selectorOn then
		selectorTable[self.selectorOn] = evOn
	elseif self.name then
		selectorTable[self.name .. "_evOn"] = evOn
	end

	if self.selectorOff then
		selectorTable[self.selectorOff] = evOff
	elseif self.name then
		selectorTable[self.name .. "_evOff"] = evOff
	end

	uiNode.evTouchUp:addListener(function(node, ev)
		self:setNormal()
	end)

	--在evTapped里派发事件
	uiNode.evTapped:addListener(function(node, ev)
		self:setState(not self.state)
		if self:getState() then 
			evOn:dispatch(node, ev, self)
		else
			evOff:dispatch(node, ev, self)
		end
	end)

	uiNode.evTouchDown:addListener(function(node, ev)
		self:setSelected()
	end)

end



return extend_type("gameui.ButtonSwitch", ButtonSwitch, UIBase)
