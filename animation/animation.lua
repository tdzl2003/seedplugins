--[[
Seed 插件
	Animation

	版本：
		1.4

	包含文件：
		Animation.lua - 提供从plist创建sprite的方法

	依赖组件：
		sprite_ex
		seed_ex
		lua_ex
		uri
		plist

	最后修改日期：
		2012-12-13：
	
	更新内容：
		1.4 2012-12-13：
			修改了newImageRectWithAni方法，适配了build127以后的引擎
			
		1.3 2012-11-13：
			修改了newImageRect部分，适配了build125以后的版本
		
		1.2 2012-6-15：
			使display.presentations.newImageRectWithAni()方法支持imageRect的90度旋转
			修正了sprite对象的getSize()方法在图像有旋转时的错误

		1.1 2012-6-6：
			getSize对于Sprite动画也可以使用，但只返回第一个sheet的大小

	注意事项：
		require("Animation")注意Animation的大小写问题

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
	if not org then
		org = {}
		org._sheet, org._set, org._shedata, org._setdata, org._framemap, org._imguri = plist.loadPlistSheet(uri,array)
		_loaded[uri] = org
	end
	self:__init__With(org._sheet, org._set, org._shedata, org._setdata, org._framemap, org._imguri)
end

--flags参数的意义：
--	0 - 解释为单张的图片，1 - 按照名称解释为动画序列
function Animation:__init__WithPlist(uri, fps, flags, array)
	local flags = flags or 1
	uri = urilib.absolute(uri, 2)
	local org = _loaded[uri]
	if not org then
		org = {}
		org._sheet, org._set, org._shedata, org._setdata, org._framemap, org._imguri = plist.loadPlistSheet(uri, fps, flags, array)
		_loaded[uri] = org
	end
	self:__init__With(org._sheet, org._set, org._shedata, org._setdata, org._framemap, org._imguri)
end

function Animation:WithDirections(dt)
	self._dt = dt
	return self
end

_G.Animation = define_type("Animation", Animation)

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
			local w, h = ani._sheet.data[id][9], ani._sheet.data[id][10] 
			if ani._sheet.data[id][11] == 5 then
				w, h = h, w
			end
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

函数Animation.newWithPlist(uri, fps, flag)
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
		presentations.Sprite对象

	标准用法：
		local sheet_set = Animation.newWithPlist("res://xxx/xxxx.plist", 24, 1)
		local node = stage:newSpriteWith(ra, sheet_set, "default_action")

函数stage/node:newImageRectWithAni(name)
	
	参数：
		name - 动作名
	
	返回值：
		presentations.ImageRect对象

	标准用法：
		local sheet_set = Animation.newWithPlist("res://xxx/xxxx.plist", 24, 1)
		local node = stage:newImageRectWithAni("default_image.png")

]]--

local unpack = table.unpack
pss.newImageRectWithAni = function(self, name)
	local id = self._framemap[name]
	assert(id)
	local r = self._shedata[id]
	assert(r)
	local sx, sy, sr, sb = unpack(r, 1, 4)
	local dx, dy, dr, db = unpack(r, 5, 8)
	local sw, sh, rotFlag = unpack(r, 9, 11)
	local ret = pss.newImageRect(self._imguri, 
			{sx, sy, sr-sx, sb-sy}
		)
	--对于plist_sheet而言，flipx和flipy要考虑图片旋转了的情况
	if rotFlag == 5 then
		local ori_setFlip = ret.setFlip
		function ret:setFlip(flipx, flipy)
			ori_setFlip(self, not flipy, flipx)
		end
	end
	local w,h = dr-dx, db-dy
	ret:setFlag(rotFlag)

	function ret:getSize()
		return w,h
	end

	return ret
end
return _G.Animation
