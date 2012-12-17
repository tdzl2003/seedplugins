--[[
Seed 插件
	ccb_menu

	包含文件
		ccb_menu.lua - 提供创建按钮的方法

	依赖组件
		animation

	最后修改日期
		2012-8-8

	更新内容
		2012-8-8：修正了创建多个按键却只能相应一个按键功能的bug
		2012-8-6：在光标拖拽出按钮的范围之外后，松开鼠标按键或手指从屏幕上移开时，不会触发按钮事件；当按钮属性enabled为false时，无论如何也不触发按钮事件。
					【注意：本次更新请与input_ex同步更新】
		2012-7-13：修正了按钮的stateAuto和setEnabled方法
		2012-6-15：增加了state属性，用来获取当前按钮的状态

		2012-6-14：增加了一系列的属性和方法，方便menuItem对象更加灵活的使用

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
		args - args是一个table，如果plist为nil，{ {普通状态按钮的图片uri, 宽, 高}, {选中状态按钮的图片uri, 宽, 高}, {无效状态按钮的图片uri, 宽, 高} }
				否则，args的内容为 { {普通状态按钮的图片在plist中的命名}, {选中状态按钮的图片在plist中的命名}, {无效状态按钮的图片在plist中的命名} }
		input_ex - input_ex对象
		anchorx - 锚点x
		anchory - 锚点y
		enabled - 是否启用

	返回值：Stage2D.Node对象

	除Stage2D.Node默认提供的方法外，此node还包含如下方法：
		self:setNormal()
		self:setDisabled()
		self:setSelected()
		self:setEnabled(enabled) 参数：true - enable, false - disable
		self:autoState(isAuto) 参数：true - 自动处理按下之后图片的变化，false - 按下按钮和抬起之后，默认图片没有变化

	属性；
		self.event 使用input_ex创建的event，可以给其设置onTouchUp,onTouchDown等事件
		self.enabled  按键是否有效
		self.state	按键当前的状态
		self.pssNormal_		普通状态下的presentation
		self.pssSelected_	选中状态下的presentation
		self.pssDisabled_	无效状态下的presentation
]]--

--增加一个用户需求：用户按下按键之后
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
		node.pssNormal_ = display.presentations.newImageRect(normal[1], normal[2], normal[3])
		node.pssSelected_ = display.presentations.newImageRect(disabled[1], disabled[2], disabled[3])
		node.pssDisabled_ = display.presentations.newImageRect(selected[1], selected[2], selected[3])
		node.presentation = node.pssNormal_
		node.state = "normal"
		node.setNormal = function(self) self.presentation = self.pssNormal_; node.state = "normal" end
		node.setDisabled = function(self) self.presentation = self.pssSelected_; node.state = "disabled" end
		node.setSelected = function(self) self.presentation = self.pssDisabled_; node.state = "selected" end
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
		node.state = "normal"
		node.setNormal = function(self) self:changeAction(normal[1]); node.state = "normal" end
		node.setDisabled = function(self) self:changeAction(disabled[1]); node.state = "disabled" end
		node.setSelected = function(self) self:changeAction(selected[1]); node.state = "selected" end
		imguri[1] = data._imguri
		imguri[2] = data._imguri
		imguri[3] = data._imguri
	end
	node.auto = true
	node.ax, node.ay = anchorx, anchory
	node:setAnchor(node.ax, node.ay)
	node.enabled = enabled or true
	local input_node
	if type(normal[2]) == "table" then
		input_node = input_ex:addSpriteRect(node, normal[2][#normal[2] - 1], normal[2][#normal[2]], anchorx, anchory)
	else
		input_node = input_ex:addSpriteRect(node, normal[2] or 64, normal[3] or 64, anchorx, anchory)
	end
	local ev = event.Dispatcher.new()
	--input_node.dragable = true
	
	input_node.onTouchDown:addListener(function()
		if node.auto and node.enabled then node:setSelected() end
		node:setAnchor(node.ax, node.ay)
	end)

	input_node.onTouchUp:addListener(function(e, args)
		if node.auto and node.enabled then node:setNormal() end
		node:setAnchor(node.ax, node.ay)
		if node.enabled and ev and input_node:testHit(args.x, args.y) then
			ev(e, args)
		end
	end)

--	input_node.onTouchUp:addListener(ev)

	node.autoState = function(self, value)
		self.auto = value

	end

	node.setEnabled = function(self, value)
		if value then
			self:setNormal()
		else
			self:setDisabled()
		end
		self.enabled = value
		self:setAnchor(self.ax, self.ay)
	end

	node.event = input_node

	return node, ev, imguri
end

display.Stage2D.Node.methods.newMenuItemImage = _newMenuItemImage
display.Stage2D.methods.newMenuItemImage = _newMenuItemImage