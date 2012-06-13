

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
			elseif (t == "kernings") then
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
	if second == -1 then
		return 0
	end
	for i,kerning in pairs(kernings) do 
		if first == kerning.first and second == kerning.second then
			return kerning.amount
		end
	end
	return 0
end

function _labelWithString(self, str, fntUri, Group)

	local node = self:newNode()

	local group = Group or node:newNode()
	local BMStr = str or ""
	
	group.width, group.height = 0, 0

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
			if charRes == char.letter then
				charIndex = i
			end
		end
		
		charInfo = fnt.chars[charIndex]
		kerning = fnt.kernings[charIndex]
		
		for i,page in pairs(fnt.pages) do 
			if charInfo.page == page.id then
				texture = page.file
			end
		end
		
		kerningAmount = getAmount(fnt.kernings, charInfo.id, prev)
		local ss = group:newImageRect("/"..texture, {charInfo.x, charInfo.y, charInfo.width, charInfo.height},
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

