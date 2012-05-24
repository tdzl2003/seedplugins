require("animation")

local selectors = {}

local function _newMenu(self, x, y)
	local posx, posy = x or 0, y or 0
	local node
	node = self:newNode()
	node.x, node.y = posx, posy
	return node
end

display.Stage2D.methods.newMenu = _newMenu
display.Stage2D.Node.methods.newMenu = _newMenu

local function _newMenuItemImage(self, plist, args, input_ex, anchorx, anchory, selectorName, enabled)
	local node
	local normal = {}
	local selected = {}
	local disabled = {}
	
	if type(args) == "table" then
		normal = args[1]
		selected = args[2] or args[1]
		disabled = args[3] or args[1]
	end
	
	if plist == nil then
		node = self:newNode()
		local pssNormal_ = display.presentations.newImageRect(normal[1], normal[2], normal[3])
		local pssSelected_ = display.presentations.newImageRect(disabled[1], disabled[2], disabled[3])
		local pssDisabled_ = display.presentations.newImageRect(selected[1], selected[2], selected[3])
		node.presentation = pssNormal_
		node.setNormal = function(self) self.presentation = pssNormal_ end
		node.setDisabled = function(self) self.presentation = pssSelected_ end
		node.setSelected = function(self) self.presentation = pssDisabled_ end
	else
		local data = Animation.newWithPlist(plist, 1, 0)
		node = self:newSpriteWith(self.stage.runtime, data, normal[1])
		node.setNormal = function(self) self:changeAction(normal[1]) end
		node.setDisabled = function(self) self:changeAction(disabled[1]) end
		node.setSelected = function(self) self:changeAction(selected[1]) end
	end
	node:setAnchor(anchorx, anchory)
	node.enabled = enabled or true
	local input_node
	if type(normal[2]) == "table" then
		input_node = input_ex:addSpriteRect(node, normal[2][#normal[2] - 1], normal[2][#normal[2]], anchorx, anchory)
	else
		input_node = input_ex:addSpriteRect(node, normal[2] or 64, normal[3] or 64, anchorx, anchory)
	end
	ev = event.Dispatcher.new()
	input_node.onTap:addListener(ev)
	local selector = node.stage.selectorTable
	input_node.onTouchDown:addListener(function()
		node:setSelected()
	end)
	input_node.onTouchUp:addListener(function()
		node:setNormal()
	end)

	node.setEnabled = function(self, value)
		if value then
			self:setNormal()
		else
			self:setDisabled()
		end
	end

	selector[selectorName] = ev
	return node
end

display.Stage2D.Node.methods.newMenuItemImage = _newMenuItemImage

