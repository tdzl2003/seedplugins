--[[
Seed插件：GameUI

	版本：
		0.13

	作者：
		YoungGK
		[yy.cicada@gmail.com]

	包含文件：
		init.lua            - 提供创建UI界面的方法以及一些支持函数
		ccb_converter.lua   - 提供读取并转换CCB文件的函数

	包含类：
		gameui.UIBase       - 所有GameUI组件的基类
		gameui.Image        - 单张图片
		gameui.Sprite       - 从plist中创建的ImageRect，暂时还不支持动画
		gameui.Node         - 最基本的节点
		gameui.Layer        - 有宽和高的层
		gameui.Button3State - 按钮控件，包含普通，按下，无效三个状态
		gameui.ButtonSwitch - 开关按钮控件
		gameui.ScreenMask   - 可以屏蔽点击的全屏遮罩（实现焦点之前的临时方案）

	依赖组件：
		Animation
		seed_ex
		uri
		xmlParser
		ui

	可选依赖组件：
		algorithm
		presentations       - 如果不使用gameui.BarView类，可以不包含这两个文件

	最后修改日期：
		2012-12-17
	
	更新记录：
		2012-12-17：0.13版本，通过selectorTable["name"].uiNode可以获取到gameui.Button3State对象
		2012-12-14：0.12版本，修正了按钮的锚点和触控区域问题
		2012-12-12：将Sprite的内部node由ImageRect改为了Sprite，已解决因原始图片尺寸与实际纹理区域尺寸不同导致的偏移问题
		2012-12-12：0.1版本

	使用方法：
		1、根据CCB文件创建场景：
			local gameui = require("gameui")
			local stage, symbols, selectors = gameui.createWithCCB(father, "res://data/main_menu.ccb", rta)
			--其中，father可以是Stage2D或Stage2D.Node对象，在创建完CCB之后，会将father对象返回
			--一般情况下，可以将第一个参数father填nil，这样，就会创建新的stage返回
			--symbols记录了所有命名过的节点
			--selector则记录了所有命名过的点击事件

		2、debug模式：
			如果存在名为DEBUG的全局table且其中的showUIData为True，那么，可以看到一些打印信息以帮助调试
			_G.DEBUG = {
				showUIData = true
			}

		3、获得UINode和Stage2D.Node对象：
			如果在cocosbuilder编辑器中已经为节点命了名，那么可以使用symbols["name"]来获得GameUINode
			需要注意的是，与之前的ccb插件不同，这次获得的是一个gameui.UIBase对象。
			根据具体的组件不同，获得的GameUINode有不同的方法，详情可以打开对应的lua文件查看。
			其中，通用的属性和方法有：
				gameUINode:getNode()          - 获取Stage2D.Node对象
				gameUINode:withDebug()        - 可以显示出坐标位置
				gameUINode:move(dx, dy)       - 平移一定距离
				gameUINode:setPosition(x, y)  - 设置坐标位置
				gameUINode:hide()             - 隐藏
				gameUINode:show()             - 显示

	注意事项：
		1、需要至少0.2.4 build 127以上版本的Seed引擎

]]

require("ui")
local liburi = require("uri")
require("animation")

if _G.gameui then
	return _G.gameui
end

local classTable = {}
classTable["gameui.Node"]         = requireClass("gameui.Node")
classTable["CCBRoot"]             = requireClass("gameui.Node")
classTable["gameui.UIBase"]       = requireClass("gameui.UIBase")
classTable["gameui.Image"]        = requireClass("gameui.Image")
classTable["gameui.Sprite"]       = requireClass("gameui.Sprite")
classTable["gameui.Layer"]        = requireClass("gameui.Layer")
classTable["gameui.MenuNode"]     = requireClass("gameui.Node")
classTable["gameui.Button3State"] = requireClass("gameui.Button3State")
classTable["gameui.Lable"]        = requireClass("gameui.Lable")

--并非ccb原生支持的类型
classTable["gameui.ButtonSwitch"] = requireClass("gameui.ButtonSwitch")
classTable["gameui.ScreenMask"]   = requireClass("gameui.ScreenMask")

local baseuri = "res://data/ui"

--相关的工具函数

--/
-- @function _toAbsolute [转为绝对路径]
-- @param  {URI} _uri [要转换的URI]
-- @return {URI}      [已转换为绝对路径的URI]
--/
local function _toAbsolute(_uri)
	if liburi.isabs(_uri) then
		baseuri = liburi.dirname(_uri)
	end
	return (liburi.isabs(_uri) and _uri) or baseuri .. '/' .. _uri
end

--CCB根节点
--[[
	data = {
		type = "CCBRoot", uri = "xxx.ccb", visible = true, name = "system_menu"
	}
]]
local function _createHandler_CCBRoot(father, data, symbolTable)
	local ccb = require("gameui.ccb_converter")
	local ccb_visible = data.visible		
	local ccb_data = ccb.convertCCBToSeedUI(_toAbsolute(data.uri))
	ccb_data.data.y = ccb_data.data.y + ccb_data.stageHeight
	if data.visible ~= nil then		--可以在外部控制整体ccb是否显示
		ccb_data.data.visible = data.visible
	end
	ccb_data.name = data.name
	local uinode = classTable["CCBRoot"].newWithData(father, ccb_data, symbolTable)
	return uinode
end

--CCB节点
local function _createHandler_CCBNode(father, data, symbolTable)
	local className = classTable[data.type]
	--print(data.type, className)
	if className then
		local node = className.newWithData(father, data, symbolTable)
		return node
	end
end
--	各种构造Node的函数

local createHandlers = {
	image = _createHandler_image,
	button = _createHandler_button,
	CCBRoot = _createHandler_CCBRoot,
	["gameui.ButtonSwitch"] = _createHandler_CCBNode,
}

--根据ui配置文件或UI数据table创建完整的UI
local function _create(data, rta)
	if type(data) == "string" then
		baseuri = _G.BASE_DATA_UI_URI or require("uri").dirname(data)
		data = dofile(data)
	end
	
	local stageUI = display:newStage2D()
	local symbolTable = {}
	local selectorTable = {}

	--所有UINode的根节点
	local root = {}
	root.node = stageUI
	symbolTable["root"] = root

	--获取数据
	local _createHandler
	for k, v in pairs(data) do
		_createHandler = createHandlers[v.type] or _createHandler_CCBNode
		if _createHandler then
			local uiNode = _createHandler(root, v, symbolTable, selectorTable)
			if uiNode then
				uiNode:toNode(selectorTable, rta)
			end
		end
	end

	return 
		stageUI, 
		symbolTable, 
		selectorTable
end

--直接创建一个ccb文件
local function _createWithCCBFile(father, file, rta, symbolTable, selectorTable)

	local symbolTable = symbolTable or {}
	local selectorTable = selectorTable or {}

	local root = {}
	root.node = father or display:newStage2D()
	local stageUI = root.node
	stageUI.symbolTable = symbolTable
	stageUI.selectorTable = selectorTable

	symbolTable["root"] = root

	local data = {
		name = "ccbroot",
		type = "CCBRoot",
		uri = file
	}

	local uiNode = _createHandler_CCBRoot(root, data, symbolTable)
	if uiNode then
		uiNode:toNode(selectorTable, rta)
	end

	return 
		stageUI, 
		symbolTable, 
		selectorTable
end

_G.gameui = {
	create = _create,
	handlers = createHandlers,
	createCCBNode = _createHandler_CCBNode,
	baseuri = baseuri,
	toAbsolute = _toAbsolute,
	createWithCCB = _createWithCCBFile
}

return _G.gameui