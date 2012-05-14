--Seed 插件
--	ui
--包含文件
--	ui.lua - 提供通过ccb文件创建UIstage的方法
--	ui_menu.lua - 提供创建Menu（菜单框架）和MenuItem（可点击的菜单项）的方法
--依赖组件
--	plist
--	particle
--	transition
--	animation
--	uri
--	input_ex
--最后修改日期
--	2012-5-14

local plistParser = require("plist")
require("ui_menu")
require("particle")
require("transition")
require("animation")
local urilib = require("uri")
local filePath_
local runtime_

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

--计算CCB锚点
local function calcAnchorRect(x, y, w, h, data)
	if data.isRelativeAnchorPoint then
		x = -data.anchorPoint[1] * w
		y = -data.anchorPoint[2] * h
	else
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

--设置各种属性
local function setNodeProperties(node, data)
	node.x, node.y = data.position[1], -data.position[2]
	node.rotation = -math.rad(data.rotation)
	node.scalex, node.scaley = data.scaleX, data.scaleY
	node.z = data.zOrder
	if data.visible then
		node:show()
	else
		node:hide()
	end
	if data.memberVarAssignmentName ~= nil then
		node.stage:setSymbolTable(data.memberVarAssignmentName, node)
	end
	node.container = node:newNode()
	node.container.x, node.container.y = -data.contentSize[1]*data.anchorPoint[1], data.contentSize[2]*data.anchorPoint[2]
	if data.blendFunc ~= nil then
		local eff = display.BlendStateEffect.new()
		eff.srcFactor = numToBlendState(data.blendFunc[1])
		eff.destFactor = numToBlendState(data.blendFunc[2])
		node:addEffect(eff)
	end
end

local function createNode(self, data)
	local node = self:newNode()
	local x, y, w, h
	w, h = data.contentSize[1], data.contentSize[2]
	x, y, w, h = calcAnchorRect(x, y, w, h, data)
	setNodeProperties(node, data)
	return node
end

local function createSprite(self, data)
	local node
	local sheet_set = Animation.newWithPlist(filePath_ .. "/" .. data.spriteFramesFile, 1, 0)
	node = self:newSpriteWith(self.stage.runtime, sheet_set, data.spriteFile)
	node:setAnchor(data.anchorPoint[1] - 0.5, 0.5 - data.anchorPoint[2])
	setNodeProperties(node, data)
	return node
end

local function createImageRect(self, data)

	local node
	local w, h
	w, h = data.contentSize[1], data.contentSize[2]
	node = self:newImageRect(filePath_ .. "/" .. data.spriteFile, w, h)
	node:setAnchor(data.anchorPoint[1] - 0.5, 0.5 - data.anchorPoint[2]);
	setNodeProperties(node, data)
	return node
end

local function createLayerColor(self, data)
	local node = self:newNode()
	local x, y, w, h
	w, h = data.contentSize[1], data.contentSize[2]
	x, y, w, h = calcAnchorRect(x, y, w, h, data)
	local l, t, r, b = x, y, x + w, y + h
	node.presentation = function()
		render2d.fillRect(l, t, r, b)
	end
	local r, g, b, a = colorFromRGBA(data.color, data.opacity)
	print(r, g, b, a)
	node:setMaskColor(r, g, b, a)
	setNodeProperties(node, data)
	return node
end

local function createMenu(self, data)
	local node = self:newMenu()
	setNodeProperties(node, data)
	return node
end

local function createMenuItemImage(self, data)
	local node
	local w, h = data.contentSize[1], data.contentSize[2]
	if data.spriteFramesFile == nil then
		node = self:newMenuItemImage(nil,{ 
			{filePath_ .. "/" .. data.spriteFileNormal, w, h},
			{filePath_ .. "/" .. data.spriteFileSelected, w, h},
			{filePath_ .. "/" .. data.spriteFileDisabled, w, h}},
			data.anchorPoint[1] - 0.5, 0.5 - data.anchorPoint[2],
			data.selector, data.enabled)
	else
		node = self:newMenuItemImage(filePath_ .. "/" .. data.spriteFramesFile,{
			{data.spriteFileNormal, w, h},
			{data.spriteFileSelected, w, h},
			{data.spriteFileDisabled, w, h}},
			data.anchorPoint[1] - 0.5, 0.5 - data.anchorPoint[2],
			data.selector, data.enabled)
	end
	setNodeProperties(node, data)
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
	psd.rotatePerSecond				= rotatePerSecond
	psd.rotatePerSecondVariance		= rotatePerSecondVar
	psd.omegaAcceleration			= nil
	psd.omegaAccelVariance			= nil

	psd.textureFileName	= filePath_ .. "/" .. data.spriteFile
	print(psd.textureFileName)

	local node_base = self:newNode()
	data.blendFunc = nil
	setNodeProperties(node_base, data)
	
	psd.sourcePositionx, psd.sourcePositiony = 0, 0
	local node = node_base:newParticleEmit(psd.textureFileName, psd, self.stage.runtime)
	node.x, node.y = 0, 0

	return node_base
end

local function createLayer(self, data)
	local node = self:newNode()
	local x, y, w, h
	w, h = data.contentSize[1], data.contentSize[2]
	x, y, w, h = calcAnchorRect(x, y, w, h, data)
	setNodeProperties(node, data)
	return node
end

local function createLayerGradient(self, data)
	local node = self:newNode()
	local x, y, w, h
	w, h = data.contentSize[1], data.contentSize[2]
	x, y, w, h = calcAnchorRect(x, y, w, h, data)
	local l, t, r, b = x, y, x + w, y + h
	node.presentation = function()
		render2d.fillRect(l, t, r, b)
	end
	local r, g, b, a = colorFromRGBA(data.color, data.opacity)
	print(r, g, b, a)
	node:setMaskColor(r, g, b, a)
	setNodeProperties(node, data)
	return node
end

local function createCCSprite(self, data)
	if data.spriteFramesFile == nil then
		node = createImageRect(self, data)
	else
		node = createSprite(self, data)
	end
end

local function createDebugNode(self, data)
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
	print("====",data.class)
	printTable(data.properties)
	
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



local function _newUIFromCCB(display, ccb, runtime, isdebugMode_)
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
	stage.runtime = runtime
	stage.selectorTable = {}
	stage.SymbolTable = {}
	stage.setSymbolTable = function(self, _name, _node)
		if _node == nil then
			error("node cannot be nil")
			return 
		end
		self.SymbolTable[_name] = _node
	end
	local camera = display.Camera2D.new()
	camera.width, camera.height = width, height
	stage.camera = camera
	camera.x, camera.y = width / 2, -height / 2
	local node = create(stage, data.nodeGraph)
	return stage
end

display.newUIFromCCBFile = _newUIFromCCB


--[[

UI的使用方法：
使用display:newUIFromCCBFile(ccb, runtime, isdebugMode)来创建
	参数：
		ccb - ccb文件的URI
		runtime
		isdebugMode - 默认为false，给true值后，使用线框绘制场景
	返回值：
		stage - 一个Stage2D对象，同时附加了selectorTable和sambolTable
		stage.selectorTable - 记录了UI里所有的selector，可以使用stage.selectorTable["selector名称"]来引用
		stage.SymbolTable - 记录了UI里所有取了名字的Node，可以使用stage.SymbolTable["node名称"]来引用相应的Node
	

]]--