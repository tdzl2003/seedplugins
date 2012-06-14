--[[
Seed 插件
	bmFnt

	包含文件
		bmFnt.lua - 提供图片字的处理方法

	依赖组件
		uri
		xmlParser

	最后修改日期
		2012-6-14

	更新内容
		2012-6-14：
			1、提供通过相对路径创建lable对象的支持
			2、提供Ascii码的兼容
]]--
local xmlParser = require("xmlParser")
local uri = require("uri")

local absolute = uri.absolute
local basename = uri.basename
local splitext = uri.splitext
local splituri = uri.split
local normjoin = uri.normjoin
local joinuri = uri.join

local xmlhandler_mt = {
	__index = {
		starttag = function(self,t,a,s,e)
			if (t == "font") then
				self.pages = {}
				self.chars = {}
				self.kernings = {}
			elseif (t == "info") then
				self.info = a
			elseif (t == "common") then
				self.common = a
			elseif (t == "page") then
				table.insert(self.pages, a)
			elseif (t == "char") then
				table.insert(self.chars, a)
			elseif (t == "kerning") then
				table.insert(self.kernings, a)
			end
		end,

		endtag = function(self,t,s,e)
			
		end
	}
}

local function parseXml(s)
	local h = {}
	setmetatable(h, xmlhandler_mt)
	xmlParser.parse(h, s)
	return h
end

local function parseUri(uri)
	local f = io.open(uri, "r")
	if (not f) then
		error("Cannot open uri "..uri)
	end
	local s = f:read()
	f:close()
	return parseXml(s)
end

local function getAmount(kernings, first, second)
	if second == -1 or kernings == nil then
		return 0
	end
	for i,kerning in pairs(kernings) do 
		if first == kerning.first and second == kerning.second then
			return kerning.amount
		end
	end
	return 0
end


--[[
函数：Stage2D/Node:lableWithString(string, fntUri, group)
	
	说明：
		通过字符串和fnt文件，创建一个lable对象

	参数：
		string - 要创建的字符串内容
		fntUri - fnt文件的URI
		Group - 

	返回值：
		lableNode对象

	附注：
		lableNode对象包含如下属性和方法：
			
			属性：
				self.group - 文字图片组合
		
			方法：
				self:setPostion(x, y) - 设置坐标位置
				self:getSize() - 获取大小
				self:setAnchor(ax, ay) - 设置锚点
				self:setString(str) - 重新设置文字内容
]]--

function _labelWithString(self, str, fntUri, Group)

	local node = self:newNode()

	local group = Group or node:newNode()
	local BMStr = str or ""
	
	group.width, group.height = 0, 0

	--uri的绝对化
	fntUri = absolute(fntUri, 2)
	--分离目录和文件名
	local dir, name = splituri(fntUri)

	local fnt = parseUri(fntUri)
	
	local count = string.len(BMStr)
	local index = 1
	local nextFontPositionX = 0
	local nextFontPositionY = 0
	local kerningAmount
	local prev = -1
	
	while index <= count do
		local charRes = string.sub(BMStr,index,index)
		
		local charIndex
		local charInfo
		local texture
		local kerning
		
		for i,char in pairs(fnt.chars) do
			if charRes == char.letter or string.byte(charRes) == char.id then
				charIndex = i
			end
		end
		
		charInfo = fnt.chars[charIndex]
		if fnt.kernings then
			kerning = fnt.kernings[charIndex]
		end

		for i,page in pairs(fnt.pages) do 
			if charInfo.page == page.id then
				--加载图片，如果没有图片相关信息，加载与uri同名的图片
				texture = (page.file and joinuri(dir, page.file)) or joinuri(dir, name..'.png')
			end
		end
		
		kerningAmount = getAmount(fnt.kernings, charInfo.id, prev) or 0
		local ss = group:newImageRect(texture, {charInfo.x, charInfo.y, charInfo.width, charInfo.height},
													{charInfo.xoffset + nextFontPositionX + kerningAmount,
													charInfo.yoffset + nextFontPositionY,
													charInfo.width, charInfo.height})
								
		group.width = group.width + charInfo.xoffset + nextFontPositionX + kerningAmount
		group.height = group.height + charInfo.yoffset + nextFontPositionY
		nextFontPositionX = nextFontPositionX + charInfo.xadvance + kerningAmount
		prev = charInfo.id
		index = index + 1
	end
	group.ax, group.ay = 0, 0
	group.x, group.y = -(group.ax + 0.5) * group.width, -(group.ay + 0.5) * group.height

	node.group = group

	function node:setPostion(dx,dy)
		self.x = dx
		self.y = dy
	end

	function node:getSize()
		return node.group.width, node.group.height
	end

	function node:setAnchor(ax, ay)
		self.group.ax, self.group.ay = ax, ay
		self.group.x = -(self.group.ax + 0.5) * self.group.width 
		self.group.y = -(self.group.ay + 0.5) * self.group.height
	end
	
	function group:setString(changeStr)
		local node = self.firstChild
		while node do
			local temp = node; node = node.next
			temp:remove()
		end
		_labelWithString(self, changeStr, fntUri, self)
	end

	function node:setString(str)
		self.group:setString(str)
	end
	
	return node
end


display.Stage2D.Node.methods.newLabelWithString = _labelWithString
display.Stage2D.methods.newLabelWithString = _labelWithString

