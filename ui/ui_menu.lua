--[[
Seed 插件
	ui_menu

	包含文件
		ui_menu.lua - 提供创建按钮的方法

	依赖组件
		animation

	最后修改日期
		2012-6-8

	更新内容
		2012-6-8：增加了使用imageRect创建的menuItem的setDestRect方法
				开放了使用imageRect创建的menuItem的三个状态的presentation，使用node.pssNormal_, pssSelected_, pssDisabled_ 来获取

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
		plist - 资源图所属plist文件，如果没有，填nil，则视作使用三张单独的png图片创建三态按钮
		args - args是一个table，如果plist为nil，{ {普通状态按钮的图片, 宽, 高}, {选中状态按钮的图片, 宽, 高}, {无效状态按钮的图片, 宽, 高} }
				否则，args的内容为 { {普通状态按钮的图片在plist中的命名}, {选中状态按钮的图片在plist中的命名}, {无效状态按钮的图片在plist中的命名} }
		input_ex - input_ex对象
		anchorx - 锚点x
		anchory - 锚点y
		enabled - 是否启用

]]--

--增加一个用户需求：用户按下按键之后
local function _newMenuItemImage(self, plist, args, input_ex, anchorx, anchory, enabled)
	local node
	local normal = {}
	local selected = {}
	local disabled = {}

	local imguri = {}
	local auto = true

	if type(args) == "table" then
		normal = args[1]
		selected = args[2] or args[1]
		disabled = args[3] or args[1]
	end

	if plist == nil then
		node = self:newNode()
		node.pssNormal_ = display.presentations.newImageRect(normal[1], normal[2], normal[3])
		node.pssSelected_ = display.presentations.newImageRect(disabled[1], disabled[2], disabled[3])
		node.pssDisabled_ = display.presentations.newImageRect(selected[1], selected[2], selected[3])
		node.presentation = node.pssNormal_
		node.setNormal = function(self) self.presentation = node.pssNormal_ end
		node.setDisabled = function(self) self.presentation = node.pssSelected_ end
		node.setSelected = function(self) self.presentation = node.pssDisabled_ end
		imguri[1] = normal[1]
		imguri[2] = disabled[1]
		imguri[3] = selected[1]
		--使用设置目的矩形的方式实现翻转
		node.setDestRect = function(self, l, t, w, h)
			self.pssNormal_:setDestRect(l, t, w, h)
			self.pssSelected_:setDestRect(l, t, w, h)
			self.pssDisabled_:setDestRect(l, t, w, h)
		end
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
		if auto then node:setSelected() end
	end)
	input_node.onTouchUp:addListener(function()
		if auto then node:setNormal() end
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
display.Stage2D.methods.newMenuItemImage = _newMenuItemImage

