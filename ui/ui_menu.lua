--[[
Seed 插件
	ui_menu

	包含文件
		ui_menu.lua - 提供创建按钮的方法

	依赖组件
		animation

	最后修改日期
		2012-6-4
	
	更新内容
		2012-6-4：增加第三个返回值：所用到的图片资源列表
]]--
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

--[[
函数：stage:newMenuItemImage(plist, args, input_ex, anchorx, anchory, enabled)

	说明：
		创建一个三态按钮，当按钮无效、有效和被按下时，有三种不同的状态
	
	参数：
		plist - 
		args - 
		input_ex - 
		anchorx - 
		anchory - 
		enabled - 

]]--

local function _newMenuItemImage(self, plist, args, input_ex, anchorx, anchory, enabled)
	local node
	local normal = {}
	local selected = {}
	local disabled = {}

	local imguri = {}
	
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
		imguri[1] = normal[1]
		imguri[2] = disabled[1]
		imguri[3] = selected[1]
	else
		local data = Animation.newWithPlist(plist, 1, 0)
		node = self:newSpriteWith(self.stage.runtime, data, normal[1])
		node.setNormal = function(self) self:changeAction(normal[1]) end
		node.setDisabled = function(self) self:changeAction(disabled[1]) end
		node.setSelected = function(self) self:changeAction(selected[1]) end
		imguri[1] = data._imguri
		imguri[2] = data._imguri
		imguri[3] = data._imguri
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
	--input_node.dragable = true
	input_node.onTap:addListener(ev)
	
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
	return node, ev, imguri
end

--[[
函数：stage2D:newMenuItemImage(plist, args, input_ex, anchorx, anchory, enabled)

node包含如下方法：
	node:setNormal()
	node:setDisabled()
	node:setSelected()
	node:setEnabled(enabled) 参数：true - enable, false - disable

]]--

display.Stage2D.Node.methods.newMenuItemImage = _newMenuItemImage

