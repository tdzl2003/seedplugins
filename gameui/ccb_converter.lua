--[[
CCB2.0

]]

--将data的ccb格式，处理成seed的格式
local urilib = require("uri")
local filePath_
local plistParser = require("plist")
require("lua_ex")

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

local stageW, stageH

local function addCCSpriteProperties(ret, data)
	local _ret = ret.data
	local _data = data.properties

	--color RGBA
	_ret.color = {}
	_ret.color[1] = _data.color[1]
	_ret.color[2] = _data.color[2]
	_ret.color[3] = _data.color[3]
	_ret.color[4] = _data.opacity

	--blend Effect
	_ret.blendEff = {}
	_ret.blendEff.src = numToBlendState(_data.blendFunc[1])
	_ret.blendEff.dst = numToBlendState(_data.blendFunc[2])
	
	--flips
	_ret.flipx = _data.flipX
	_ret.flipy = _data.flipY

	--image n plist
	if _data.spriteFramesFile then
		--Sprite
		ret.type = "gameui.Sprite"
		_ret.sets = _data.spriteFramesFile
		_ret.action = _data.spriteFile
	else
		--Image
		ret.type = "gameui.Image"
		_ret.image = _data.spriteFile
	end

	--纹理坐标的偏转
	--_ret.y = _ret.y - _ret.height

end

local function addCCMenuItemImageProperties(ret, data)
	local _ret = ret.data
	local _data = data.properties

	if _data.spriteFramesFile then
		_ret.sets = _data.spriteFramesFile
	end

	--三种状态
	_ret.normal = _data.spriteFileNormal
	_ret.selected = _data.spriteFileSelected
	_ret.disabled = _data.spriteFileDisabled
	
	--启用状态
	_ret.enabled = _data.isEnabled
	
	--回调方法
	_ret.selector = _data.selector

	ret.type = "gameui.Button3State"
	
end

local function addCCLabelBMFontProperties(ret, data)
	local _ret = ret.data
	local _data = data.properties

	--color RGBA
	_ret.color = table.clone(_data.color)
	_ret.color[4] = _data.opacity

	--字体名称，这里是带有文件扩展名的
	_ret.font = _data.fontFile
	_ret.string = _data.string
	
	ret.type = "gameui.Lable"
end

local HandlersOfaddOtherProperties = {
	CCNode = function(ret) ret.type = "gameui.Node" end,
	CCSprite = addCCSpriteProperties,
	CCLayer = function(ret) ret.type = "gameui.Layer" end,
	CCMenu = function(ret) ret.type = "gameui.MenuNode" end,
	CCLayerColor = function(ret) ret.type = "gameui.Layer" end,
	CCMenuItemImage = addCCMenuItemImageProperties,
	CCLabelBMFont = addCCLabelBMFontProperties
}

local function _procNodeData(ret, data)

	--格式数据
	ret.type = data.class
	ret.data = {}

	local _ret = ret.data
	local _data = data.properties

	--基本数据
	_ret.visible = _data.visible

	--锚点
	_ret.anchorEnabled = _data.isRelativeAnchorPoint
	_ret.anchorx = _data.anchorPoint[1] - 0.5
	_ret.anchory =  - _data.anchorPoint[2] + 0.5

	--尺寸
	_ret.width = _data.contentSize[1]
	_ret.height = _data.contentSize[2]

	--字节点相对锚点位置的偏移量处理（只对子节点起作用）
	local offsetx, offsety = 0, 0
	if _ret.anchorEnabled then
		offsetx = (-0.5 - _ret.anchorx) * _ret.width
		offsety = (0.5 - _ret.anchory) * _ret.height
	end

	--matrix
	_ret.x = _data.position[1] + (_data.offsetx or 0)
	_ret.y = -_data.position[2] + (_data.offsety or 0)
	_ret.z = _data.zOrder

	_ret.scalex = _data.scaleX
	_ret.scaley = _data.scaleY

	_ret.rotation = _data.rotation


	--附加属性
	_ret.tag = _data.tag
	ret.name = _data.memberVarAssignmentName

	--非通用部分
	local _addOtherPropertie = HandlersOfaddOtherProperties[ret.type]
	if _addOtherPropertie then
		_addOtherPropertie(ret, data)
	else
		warning("this type: " .. ret.type .. " has not been supported yet.")
	end

	--子节点
	for i, v in ipairs(data.children) do
		if not ret.childs then
			ret.childs = {}
		end
		local t = {}
		v.properties.offsetx = offsetx
		v.properties.offsety = offsety
		_procNodeData(t, v)
		table.insert(ret.childs, t)
	end
	
end

local function _procData(data)
	stageW, stageH = data.stageWidth, data.stageHeight
	local ret = {}
	ret.ccbroot = {}
	_procNodeData(ret.ccbroot, data.nodeGraph)
	ret.ccbroot.stageWidth = stageW
	ret.ccbroot.stageHeight = stageH
	ret.ccbroot.type = "CCB"
	--outTable(ret.ccbroot, 10)
	return ret.ccbroot
end

local function convertCCBToSeedUI(ccb)
	local data 
	if type(ccb) == "table" then
		data = ccb
		if not ccb.filepath then
			error("ccb table must take a property: \"filepath\"")
		end
		filePath_ = ccb.filepath
	else
		ccb = urilib.absolute(ccb, 2)
		filePath_ = urilib.dirname(ccb)
		data = plistParser.parseUri(ccb)
	end
	return _procData(data)
end

return {
	convertCCBToSeedUI = convertCCBToSeedUI
}
