
local UIBase = requireClass("gameui.UIBase")
local Button3State = {}

function Button3State:__init__WithData(father, data, symbolTable)
	UIBase.methods.__init__WithData(self, father, data, symbolTable)
end

function Button3State:setNormal()
	if self.enabled then
		if self.sets then
			self.node:changeAction(self.normal)
		else
			self.node.presentation = self.pssNormal
		end
	end
end

function Button3State:setSelected()
	if self.enabled then
		if self.sets then
			self.node:changeAction(self.selected)
		else
			self.node.presentation = self.pssSelected
		end
	end
end

function Button3State:setEnabled(flag)
	self.enabled = flag
	if flag then
		if self.sets then
			self.node:changeAction(self.normal)
		else
			self.node.presentation = self.pssNormal
		end
	else
		if self.sets then
			self.node:changeAction(self.disabled)
		else
			self.node.presentation = self.pssDisabled
		end
	end
end

function Button3State:toNode(selectorTable, rta)
	UIBase.methods.toNode(self, selectorTable, rta)
	local node = self.node

	if self.sets then
		local sheet_set = Animation.newWithPlist(gameui.toAbsolute(self.sets), 0, 0)
		self.pssNormal = display.presentations.newSpriteWith(rta, sheet_set, self.normal)
		-- self.pssSelected = display.presentations.newSpriteWith(rta, sheet_set, self.selected)
		-- self.pssDisabled = display.presentations.newSpriteWith(rta, sheet_set, self.disabled)
		self.pssNormal:setAnchor(self.anchorx, self.anchory)
	else
		self.pssNormal = display.presentations.newImage(gameui.toAbsolute(self.normal))
		self.pssSelected = display.presentations.newImage(gameui.toAbsolute(self.selected))
		self.pssDisabled = display.presentations.newImage(gameui.toAbsolute(self.disabled))
		self.pssNormal:setAnchor(self.anchorx, self.anchory)
		self.pssSelected:setAnchor(self.anchorx, self.anchory)
		self.pssDisabled:setAnchor(self.anchorx, self.anchory)
	end

	node.presentation = self.pssNormal

--	if self.anchorEnabled then
	
--	end

	-- print(self.anchorx, self.anchory, self.width, self.height)

	self.shape = {
		type = "ui.Rect",
		x = (-self.anchorx - 0.5) * self.width,
		y = (-self.anchory - 0.5) * self.height,
		w = self.width,
		h = self.height
	}

	local shape = requireClass("ui.Rect").newWithRect(self.shape.x, self.shape.y, self.shape.w, self.shape.h)
	local uiNode = ui.registerNode(rta, node):withShape(shape):catchTap():catchTouch()
	self.evTapped = event.Dispatcher.new()
	if self.selector then
		selectorTable[self.selector] = self.evTapped
	end
	uiNode.evTouchUp:addListener(function(node, ev)
		self:setNormal()
	end)

	uiNode.evTapped:addListener(function(node, ev)
		self.evTapped:dispatch(node, ev, self)
	end)

	uiNode.evTouchDown:addListener(function(node, ev)
		self:setSelected()
	end)
end

return extend_type("gameui.Button3State", Button3State, UIBase)
