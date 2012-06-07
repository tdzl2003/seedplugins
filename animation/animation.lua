--[[
Seed 插件
	animation

	包含文件
		animation.lua - 提供从plist创建sprite的方法

	依赖组件
		sprite_ex
		seed_ex
		lua_ex
		uri
		plist

	最后修改日期
		2012-6-6
	
	更新内容：
		2012-6-6：
			getSize对于Sprite动画也可以使用，但只返回第一个sheet的大小
]]--
require("sprite_ex")
require("seed_ex")
require("lua_ex")
local urilib = require("uri")
local plist = require("plist")

local Animation = {}

local _loaded = newWeakValueTable()

function Animation:__init__()
	error("Use newWith/newWithPlist/newWithData instead!")
end

function Animation:__init__With(sheet, set, shedata, setdata, framemap, imguri)
	self._sheet = sheet
	self._set = set
	
	self._shedata = shedata
	self._framemap = framemap
	self._imguri = imguri
end

function Animation:__init__WithArray(uri,array)
	uri = urilib.absolute(uri, 2)
	local org = _loaded[uri]
	if (org) then
		self:__init_With(org._sheet, org._set)
	else
		self:__init__With(plist.loadPlistSheet(uri,array))
	end
end

--flags参数的意义：
--	0 - 解释为单张的图片，1 - 按照名称解释为动画序列
function Animation:__init__WithPlist(uri, fps, flags, array)
	local flags = flags or 1
	uri = urilib.absolute(uri, 2)
	local org = _loaded[uri]
	if (org) then
		self:__init_With(org._sheet, org._set)
	else
		self:__init__With(plist.loadPlistSheet(uri, fps, flags, array))
	end
end

function Animation:WithDirections(dt)
	self._dt = dt
	return self
end

define_type("Animation", Animation)

local pss = display.presentations
pss.newSpriteWith = function(rt, ani, action)
	local ret = nil
	if (ani.type == Animation.type) then
		if (ani._dt) then
			ret = pss.newDSprite(rt, ani._sheet, ani._set, ani._dt, action)
		else
			ret = pss.newSprite(rt, ani._sheet, ani._set, action)
		end

		function ret:getSize()
			local id = ani._framemap[ret:getAction()]
			if id == nil then
				id = 1
			end
			local w, h = ani._sheet.data[id][10], ani._sheet.data[id][9] 
			return w, h
		end

	end
	return ret
end

--[[
	使用newSpriteWith创建的对象，可以使用node:getSize()方法获得当前动作的宽和高
	注意：node:getSize()仅在plist被解释为单张图片时适用。
		由于通常在动画形式的plist中，所有sheet的大小都是统一的，因此plist被解释为动画时，只能获得sheet中第一个图块的大小。。
]]--

--[[
使用说明：

函数Animation:newWithPlist(uri, fps, flag)
	参数：
		uri - plist文件的uri地址，可以理解为路径
		fps - 动画帧率，每秒播放多少帧
		flag - 解析标志：0 - 解释为单张的图片，1 - 按照名称解释为动画序列
	返回值：
		sheet_set - 
			sheet_set是一个table，包含如下内容：
				_sheet	图片资源分割数据表
				_set	动作及其对应的帧序列
				_shedata	【暂时未知】
				_framemap	动作名称对应
				_imguri	plist对应图片的uri

函数stage/node:newSpriteWith(runtimeAgent, sheet_set, action)
	参数：
		runtimeAgent - runtime.Agent对象
		sheet_set - Animation:newWithPlist()的返回值
		action - 默认播放的动作
	返回值:
		Sprite对象

标准用法：
	local sheet_set = Animation.newWithPlist("res://xxx/xxxx.plist", 24, 1)
	local node = stage:newSpriteWith(ra, sheet_set, "default_action")
]]--

local unpack = table.unpack
pss.newImageRectWithAni = function(self, name)
	local id = self._framemap[name]
	assert(id)
	local r = self._shedata[id]
	assert(r)
	local sx, sy, sr, sb = unpack(r, 1, 4)
	local dx, dy, dr, db = unpack(r, 5, 8)
	local ret = pss.newImageRect(self._imguri, 
			{sx, sy, sr-sx, sb-sy},
			{dx, dy, dr-dx, db-dy}
		)
	local w,h =  dr-dx, db-dy
	
	function ret:getSize()
		return w,h
	end
	return ret
end
