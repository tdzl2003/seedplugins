--[[
Seed 插件
	ui
包含文件
	ui.lua - 提供通过ccb文件创建UIstage的方法
	ui_menu.lua - 提供创建Menu（菜单框架）和MenuItem（可点击的菜单项）的方法
依赖组件
	plist
	particle
	transition
	animation
	uri
	input_ex
最后修改日期
	2012-6-8

更新内容
	2012-6-8：修正了menuItem的SetFlip函数为nil的问题
	2012-6-4：增加了resourceTable

]]--


local plistParser = require("plist")
require("ui_menu")
require("particle")
require("transition")
require("animation")
local urilib = require("uri")
local filePath_

local screenW, screenH = display.getContentSize()
local width, height = 480, 320
local debugMode_ = false

-- 从RGB表和alpha中获取颜色
local function colorFromRGBA(color, alpha)
	if color == nil then
		return 1, 0, 0, 0.5
	else
		return color[1] / 255, color[2] / 255, color[3] / 255, alpha / 255
	end
end

--计算CCB锚点，返回结果为矩形的位置与宽高
local function calcAnchorRect(x, y, w, h, data)
	if data.isRelativeAnchorPoint then
		x = -data.anchorPoint[1] * w
		y = -data.anchorPoint[2] * h
	else
		--需要重新观察
		x, y = 0, 0
	end
	return x, y, w, h
end

--根据数字查找BlendState的值
local function numToBlendState(num)
	if num == 0 then return "zero"
	elseif num == 1 then return "one"
	elseif num == 770 then return "srcAlpha"
	elseif num == 772 then return "dstAlpha"
	elseif num == 771 then return "invSrcAlpha"
	elseif num == 773 then return "invDstAlpha"
	elseif num == 768 then return "srcColor"
	elseif num == 774 then return "dstColor"
	elseif num == 769 then return "invSrcColor"
	elseif num == 775 then return "invDestColor"
	end
end

--根据flip改变imageRect的w, h属性
local function getSizeFlipped(w, h, flipx, flipy)
	local retw, reth = w, h
	if flipx then retw = -retw end
	if flipy then reth = -reth end
	return retw, reth
end

--设置node的各种属性
local function setNodeProperties(node, data)
	--位置、旋转、缩放和Z
	node.x, node.y = data.position[1], - data.position[2]
	node.rotation = math.rad(data.rotation)
	node.scalex, node.scaley = data.scaleX, data.scaleY
	node.z = data.zOrder

	--显示或隐藏
	if data.visible then
		node:show()
	else
		node:hide()
	end

	--添加进node引用表，方便外界引用
	if data.memberVarAssignmentName ~= nil then
		node.stage:setsymbolTable(data.memberVarAssignmentName, node)
	end

	--获取contentSize
--	node.contentSize = data.contentSize
	node.getContentSize = function(node)
		return data.contentSize[1], data.contentSize[2]
	end

	--获取tag
	node.getTag = function(node)
		return data.tag
	end

	--设置blendState
	if data.blendFunc ~= nil then
		local eff = display.BlendStateEffect.new()
		eff.srcFactor = numToBlendState(data.blendFunc[1])
		eff.destFactor = numToBlendState(data.blendFunc[2])
		node:addEffect(eff)
	end

	--创建容器node，根据容器node的位置创建子节点
	node.container = node:newNode()
	local anchorX, anchorY = data.anchorPoint[1], data.anchorPoint[2]
	if not data.isRelativeAnchorPoint  then
		if data.scaleX ~= 0 then
			anchorX = 0.5 - 0.5 / data.scaleX
		else
			anchorX = 0
		end
		if data.scaleY ~= 0 then
			anchorY = 0.5 - 0.5 / data.scaleY
		else
			anchorY = 0
		end
	end
	node.container.x, node.container.y = -data.contentSize[1] * anchorX, data.contentSize[2] * anchorY
	--debug模式的绘制
	if debugMode_ then
		node.container.presentation = function()
			render2d.fillCircle(0,0,4)
		end
	end
end

local function createNode(self, data)
	local node = self:newNode()
	setNodeProperties(node, data)
	return node
end

local function createSprite(self, data)
	local node

----这段代码可以根据使用的action的名称自动识别为动画并播放，如果当前action的名称是以_00.png为结尾的，那么就将其视作动画处理
	local s, e = string.find(data.spriteFramesFile, ".plist")
	local str = string.sub(data.spriteFramesFile, 1, s-1)
	s, e = string.find(data.spriteFile, str)
	local ss, ee = string.find(data.spriteFile, "_00.png")
	local type = 0
	local actionName
	if s ~= nil and e ~= nil and s ~= e and ss ~= nil and ee ~= nil and ss ~= ee then
		type = 1
	end 
	
	local sheet_set = Animation.newWithPlist(filePath_ .. "/" .. data.spriteFramesFile, 24, type)
	
	if type == 1 then
		actionName = string.sub(data.spriteFile, e+2, ss-1)
	end
	
	node = self:newSpriteWith(self.stage.runtime, sheet_set, actionName == nil and data.spriteFile or actionName)
---------------------------------------------------------------

	local ax, ay = data.anchorPoint[1] - 0.5, 0.5 - data.anchorPoint[2]
	node:setFlip(data.flipX, data.flipY)
	if data.flipX then ax = -ax end
	if data.flipY then ay = -ay end
	node:setAnchor(ax, ay)

	setNodeProperties(node, data)
	local r, g, b, a = colorFromRGBA(data.color, data.opacity)
	node:setMaskColor(r, g, b)
	node:setAlpha(a)
--	table.insert(node.stage.resourceTable, sheet_set._imguri)
	return node
end

local function createImageRect(self, data)

	local node
	local w, h
	w, h = data.contentSize[1], data.contentSize[2]
	
	node = self:newImageRect(filePath_ .. "/" .. data.spriteFile, w, h)
	node:setAnchor(data.anchorPoint[1] - 0.5, 0.5 - data.anchorPoint[2]);
	local r, g, b, a = colorFromRGBA(data.color, data.opacity)
	node:setMaskColor(r, g, b)
	node:setAlpha(a)
	
	w, h = getSizeFlipped(w, h, data.flipX, data.flipY)
	node:setDestRect(-w / 2, -h / 2, w, h)
	setNodeProperties(node, data)
--	table.insert(node.stage.resourceTable, filePath_ .. "/" .. data.spriteFile)
	return node
end

local function createMenu(self, data)
	local node = self:newMenu()
	setNodeProperties(node, data)
	return node
end

local function createMenuItemImage(self, data)
	local node
	local ev
	local imgUri
	local w, h = data.contentSize[1], data.contentSize[2]
	if data.spriteFramesFile == nil then
		local ax, ay = data.anchorPoint[1] - 0.5, 0.5 - data.anchorPoint[2]
		if data.flipX then ax = -ax end
		if data.flipY then ay = -ay end

		node, ev, imgUri = self:newMenuItemImage(nil,{ 
			{filePath_ .. "/" .. data.spriteFileNormal, w, h},
			{filePath_ .. "/" .. data.spriteFileSelected, w, h},
			{filePath_ .. "/" .. data.spriteFileDisabled, w, h}},
			self.stage.input_ex,
			ax, ay,
			data.enabled)
		w, h = getSizeFlipped(w, h, data.flipX, data.flipY)
		node:setDestRect(-w / 2, -h / 2, w, h)
	else
		local tw, th = getSizeFlipped(w, h, data.flipX, data.flipY)
		
		node, ev, imgUri = self:newMenuItemImage(filePath_ .. "/" .. data.spriteFramesFile,{
			{data.spriteFileNormal, {w, h}, {-tw / 2, -th / 2, tw, th}},
			{data.spriteFileSelected, {w, h},{-tw / 2, -th / 2, tw, th}},
			{data.spriteFileDisabled, {w, h},{-tw / 2, -th / 2, tw, th}}},
			self.stage.input_ex,
			data.anchorPoint[1] - 0.5, 0.5 - data.anchorPoint[2],
			data.enabled)
	end
	local selector = node.stage.selectorTable
	selector[data.selector] = ev
	setNodeProperties(node, data)
	for k, v in pairs(imgUri) do
--		table.insert(node.stage.resourceTable, v)
	end
	return node
end

local function createBMFont(self, data)
	local node = self:newNode()
	setNodeProperties(node, data)
	return node
end

local function createParticleSystem(self, data)
	local texture = nil

	local psd = {}
	psd.emitterType					= data.emitterMode
	psd.maxParticles				= data.totalParticles
	psd.emissionRate				= data.emissionRate
	psd.duration					= data.duration
								   
	psd.particleLifespan			= data.life
	psd.particleLifespanVariance	= data.lifeVar
								   
	psd.sourcePositionx				= data.position[1]
	psd.sourcePositiony				= -data.position[2]
	psd.sourcePositionVariancex		= data.posVar[1]
	psd.sourcePositionVariancey		= data.posVar[2]
								   
	psd.startColorRed				= data.startColor[1]
	psd.startColorGreen				= data.startColor[2]
	psd.startColorBlue				= data.startColor[3]
	psd.startColorAlpha				= data.startColor[4]
	psd.startColorVarianceRed		= data.startColorVar[1]
	psd.startColorVarianceGreen		= data.startColorVar[2]
	psd.startColorVarianceBlue		= data.startColorVar[3]
	psd.startColorVarianceAlpha		= data.startColorVar[4]
								   
	psd.startParticleSize			= data.startSize
	psd.startParticleSizeVariance	= data.startSizeVar
	psd.finishParticleSize			= data.endSize
	psd.finishParticleSizeVariance	= data.endSizeVar
								   
	psd.finishColorVarianceRed		= data.endColor[1]
	psd.finishColorVarianceGreen	= data.endColor[2]
	psd.finishColorVarianceBlue		= data.endColor[3]
	psd.finishColorVarianceAlpha	= data.endColor[4]
								   
	psd.finishColorRed				= data.endColorVar[1]
	psd.finishColorGreen			= data.endColorVar[2]
	psd.finishColorBlue				= data.endColorVar[3]
	psd.finishColorAlpha			= data.endColorVar[4]
								   
	psd.angle						= data.angle or 0
	psd.angleVariance				= data.angleVar
	psd.speed						= data.speed
	psd.speedVariance				= data.speedVar
								   
	psd.gravityx					= data.gravity and data.gravity[1]
	psd.gravityy					= data.gravity and data.gravity[2]
								   
	psd.tangentialAcceleration		= data.tangentialAccel
	psd.tangentialAccelVariance		= data.tangentialAccelVar
	psd.radialAcceleration			= data.radialAccel
	psd.radialAccelVariance			= data.radialAccelVar
								   
	psd.rotationStart				= data.startSpin
	psd.rotationEnd					= data.endSpin
	psd.rotationStartVariance		= data.startSpinVar
	psd.rotationEndVariance			= data.endSpinVar
	
	psd.blendFuncSource				= data.blendFunc[1]
	psd.blendFuncDestination		= data.blendFunc[2]
						   
	psd.minRadius					= data.startRadius
	psd.minRadiusVariance			= data.startRadiusVar
	psd.maxRadius					= data.endRadius
	psd.maxRadiusVariance			= data.endRadiusVar
	psd.rotatePerSecond				= data.rotatePerSecond
	psd.rotatePerSecondVariance		= data.rotatePerSecondVar
	psd.omegaAcceleration			= nil
	psd.omegaAccelVariance			= nil

	psd.textureFileName	= filePath_ .. "/" .. data.spriteFile

	local node_base = self:newNode()
	data.blendFunc = nil
	setNodeProperties(node_base, data)
	
	psd.sourcePositionx, psd.sourcePositiony = 0, 0
	local node = node_base:newParticleEmit(psd.textureFileName, psd, self.stage.runtime)
	node.x, node.y = 0, 0

	return node_base
end

function setLayerProperties(node, data, drawable)
	--位置、缩放和Z
	node.x, node.y = data.position[1], - data.position[2]
	node.scalex, node.scaley = data.scaleX, data.scaleY
	node.z = data.zOrder
	node.layer = node:newNode()

	if data.isRelativeAnchorPoint then
		node.layer.x, node.layer.y = 0, 0
	else
		node.layer.x, node.layer.y = data.contentSize[1] * data.anchorPoint[1], -data.contentSize[2] * data.anchorPoint[2]
	end

	local x, y, w, h = 0, 0, data.contentSize[1], -data.contentSize[2]
	x = -data.anchorPoint[1] * w
	y = -data.anchorPoint[2] * h

	node.layer.rotation = math.rad(data.rotation)

	--显示或隐藏
	if data.visible then
		node:show()
	else
		node:hide()
	end
	
	if drawable then
		node.layer:setMaskColor(colorFromRGBA(data.color, data.opacity))
		node.layer.presentation = function()
			render2d.fillRect(x, y, x + w, y + h)
		end
	end

	--添加进node引用表，方便外界引用
	if data.memberVarAssignmentName ~= nil then
		node.stage:setsymbolTable(data.memberVarAssignmentName, node)
	end

	--获取大小
	node.getContentSize = function(node)
		return data.contentSize[1], data.contentSize[2]
	end

	--获取tag
	node.getTag = function(node)
		return data.tag
	end

	--设置blendState
	if data.blendFunc ~= nil then
		local eff = display.BlendStateEffect.new()
		eff.srcFactor = numToBlendState(data.blendFunc[1])
		eff.destFactor = numToBlendState(data.blendFunc[2])
		node:addEffect(eff)
	end

	--创建容器node，根据容器node的位置创建子节点
	node.container = node.layer:newNode()
	if drawable then node.container:setMaskColor(1,1,1,1) end
	node.container.x, node.container.y = x, y
end

--创建容器图层
local function createLayer(self, data)
	local node = self:newNode()
	setLayerProperties(node, data)
	return node
end

--创建颜色容器图层
local function createLayerColor(self, data)
	local node = self:newNode()
	setLayerProperties(node, data, true)
	return node
end

--创建渐变色容器图层（现阶段引擎无法支持渐变色，使用纯色代替）
local function createLayerGradient(self, data)
	local node = self:newNode()
	setLayerProperties(node, data, true)
	return node
end

--创建bmFnt
local function createBmFnt(self, data)
	
end

local function createCCSprite(self, data)
	if data.spriteFramesFile == nil then
		node = createImageRect(self, data)
	else
		node = createSprite(self, data)
	end
	return node
end

local function createDebugNode(self, data)
	print("---------------------------")
	printTable(data)
	local node = self:newNode()
	local x,y,w,h
	w, h = data.contentSize[1], data.contentSize[2]
	x, y, w, h = calcAnchorRect(x, y, w, h, data)
	local l, t, r, b = x, y, x + w, y + h
	node.presentation = function()
		render2d.fillRect(l, t, r, b)
		render2d.drawRect(l, t, r, b)
		render2d.drawLine(l, t, r, b)
		render2d.drawLine(l, b, r, t)
		render2d.drawCircle(0, 0, 3)
	end
	node:setMaskColor(0, 1, 0, 0.7)
	setNodeProperties(node, data)
	return node
end

local createNodeTable = {
	["DebugNode"] = createDebugNode,
	["CCNode"] = createNode,
	["CCSprite"] = createCCSprite,
	["CCLayerGradient"] = createImageRectWithAni,
	["CCLayer"] = createLayer,
	["CCLayerColor"] = createLayerColor,
	["CCLayerGradient"] = createLayerGradient,
	["CCMenu"] = createMenu,
	["CCMenuItemImage"] = createMenuItemImage,
	["CCLabelBMFont"] = createLabelBMFont,
	["CCParticleSystem"] = createParticleSystem
}

local function create(self, data)
	local node

	if debugMode_ then
		node = createDebugNode(self, data.properties)
	else
		local t = data.class
		local createFunc = createNodeTable[t]
		if createFunc ~= nil then
			node = createFunc(self, data.properties)
		else
			node = self:newNode()
			print(t .. "class not supported")
		end
		
	end
	if data.children[1] ~=nil then
		for i, v in ipairs(data.children) do
			create(node.container, v)
		end
	end
	return node
end

local function _newUIFromCCB(display, ccb, runtime, input_ex, isdebugMode_)
	local data 
	if type(ccb) == "table" then
		data = ccb
	else
		ccb = urilib.absolute(ccb, 2)
		filePath_ = urilib.dirname(ccb)
		data = plistParser.parseUri(ccb)
	end
	
	debugMode_ = isdebugMode_ or false
	width, height = data.stageWidth, data.stageHeight
	local stage = display:newStage2D()
--	stage:setSortMode("ascending")
	stage.input_ex = input_ex
	stage.runtime = runtime
	stage.selectorTable = {}
	stage.symbolTable = {}
	stage.setsymbolTable = function(self, _name, _node)
		if _node == nil then
			error("node cannot be nil")
			return 
		end
		self.symbolTable[_name] = _node
	end
	local camera = display.Camera2D.new()
	camera.width, camera.height = width, height
	stage.camera = camera
	camera.x, camera.y = width / 2, -height / 2
	local node = create(stage, data.nodeGraph)
	return stage
end

local function getResTable(t, data)
	if data.class == "CCSprite" then
		if data.properties.spriteFramesFile == nil then
			if data.properties.spriteFile ~= "" then
				table.insert(t, filePath_ .. "/" .. data.properties.spriteFile)
			end
		else
			local sheet_set = Animation.newWithPlist(filePath_ .. "/" .. data.properties.spriteFramesFile, 1, 0)
			table.insert(t, sheet_set._imguri)
		end
	elseif data.class == "CCMenuItemImage" then
		if data.spriteFramesFile == nil then
			if data.properties.spriteFileNormal ~= "" then
				table.insert(t, filePath_ .. "/" .. data.properties.spriteFileNormal)
			end
			if data.properties.spriteFileSelected ~= "" then
				table.insert(t, filePath_ .. "/" .. data.properties.spriteFileSelected)
			end
			if data.properties.spriteFileDisabled ~= "" then
				table.insert(t, filePath_ .. "/" .. data.properties.spriteFileDisabled)
			end
		else
			local sheet_set = Animation.newWithPlist(filePath_ .. "/" .. data.properties.spriteFileNormal, 1, 0)
			table.insert(t, sheet_set._imguri)
			sheet_set = Animation.newWithPlist(filePath_ .. "/" .. data.properties.spriteFileSelected, 1, 0)
			table.insert(t, sheet_set._imguri)
			sheet_set = Animation.newWithPlist(filePath_ .. "/" .. data.properties.spriteFileDisabled, 1, 0)
			table.insert(t, sheet_set._imguri)
		end
	elseif data.class == "CCParticleSystem" then
		table.insert(t, filePath_ .. "/" .. data.properties.spriteFile)
	end
	for i, v in ipairs(data.children) do
		getResTable(t, v)
	end
end

function getResourceTableFromCCB(ccb)
	local data 
	if type(ccb) == "table" then
		data = ccb
	else
		ccb = urilib.absolute(ccb, 2)
		filePath_ = urilib.dirname(ccb)
		data = plistParser.parseUri(ccb)
	end
	local ret = {}
	
	getResTable(ret, data.nodeGraph)
	return ret
end

display.newUIFromCCBFile = _newUIFromCCB

--[[

UI的使用方法：
使用display:newUIFromCCBFile(ccb, runtime, input_ex, isdebugMode)来创建
	参数：
		ccb - ccb文件的URI
		runtime
		isdebugMode - 默认为false，给true值后，使用线框绘制场景
	返回值：
		stage - 一个Stage2D对象，同时附加了selectorTable和sambolTable
		stage.selectorTable - 记录了UI里所有的selector，可以使用stage.selectorTable["selector名称"]来引用
		stage.symbolTable - 记录了UI里所有取了名字的Node，可以使用stage.symbolTable["node名称"]来引用相应的Node

]]--

--[[

===========================symbolTable的详细用法===============================

通过“symbolTable.nodeName”可以引用到在ccb编辑器中以“nodeName”命名的节点
可以对其执行各种诸如旋转、平移、增删子节点等各种操作
如下的例子即让一个名为Star的节点不停旋转：

local node = uiStage.symbolTable.Star
runtime.enterFrame:addListener(function()
	node.rotation = node.rotation + 0.05
end)

node中增加了一些获取数据的属性和方法：
	node:getContentSize()		--获取node的ContentSize数据
	node:getTag()				--获取node的tag数据

]]--

--[[

===========================selectorTable的详细用法=============================

通过“selectorTable.selectorName”或“selectorTable["selectorName"]”可以引用到以“selectorName”命名的selector
selector是一个事件，该事件会在selector所属的MenuItem被按下时触发。
使用方法同其他事件，即selector:addListener(callbackFunction)
如下的例子即让一个名为“pressedToMenu”的selector被触发时，打印"ToMenu"字符串
（有些selector的名称，如“pressedToMenu:”中包含lua的运算符“:”，这时只能使用selectorTable["pressedToMenu:"]来引用）

uiStage.selectorTable.pressedToMenu:addListener(function()
	print("ToMenu")
end)

]]--

--[[

===========================resourceTable的详细用法=============================

使用函数getResourceTableFromCCB(ccb)来预先获得图片资源列表

]]--

--[[

===========================注意事项============================================

大部分的node有一个容器对象，是其在ccb文件中的所有子节点的直接父节点，正确获得ccb中node的子节点的方法是使用node.container.firstChild。
直接使用node.firstChild可能得到的仅仅是一个容器，或者是粒子发射器，也可能是一个带颜色的矩形node。

]]--