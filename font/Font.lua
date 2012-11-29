--[[
Seed插件：字体和文本

	包含文件：
		particle.lua - 提供创建粒子的方法

	依赖组件：
		seed_ex
		uri

	最后修改日期：
		2012-11-29
	
	更新记录：
		2012-11-29：正式第一版

	使用方法：
		require("Font")		--在require之后，就会创建两个全局类 Font和Text
		local fontDefault = Font.newWithUri("res://data/default.fnt")	--创建字体对象。
		--对于一款游戏来说，一种字体创建一次后，应当尽量避免重复的创建。
		
		local text = stage:newText(fontDefault, "Hello Seed")	-- 使用刚刚创建好的字体创建Text对象

		--也可以不使用代理方法，直接指定presentation：
		local text = stage:newNode()
		text.presentation = display.presentations.newText(fontDefault, "Hello Seed")

		-- text拥有node的所有属性，同时具备如下方法
		text:setText("Powered by Seed Engine \n version 0.2.4")	--设置文本显示内容，支持换行符和中文显示（UTF-8编码）
		text:setLineHeight(18)		--设置文字的行高，会影响多行文字的行距
		text:setFont(newFont)		--设置字体，可以用这个来更换字体
		text:getAnchor()			--获得锚点

	注意事项：
		1、需要至少0.2.4版本的Seed引擎（build 124以上）
		2、目前暂不支持使用xml格式的fnt文件，只支持文本格式的fnt
]]

require("seed_ex")

local urilib = require("uri")

local Font = {}

function Font:__init__(fntData)
	self.pages = fntData.pages
	self.chars = fntData.chars
	self.lineHeight = fntData.lineHeight
	self.base = fntData.base
	self.pageCount = fntData.pageCount
end

local loadFntFile

function Font:__init__WithUri(uri)
	--TODO: 防重复加载。
	uri = urilib.absolute(uri, 3)
	
	local ext = urilib.extension(uri)
	if (ext == '.fnt') then
		self:__init__(loadFntFile(uri))
	end

end

function Font:generateRenderer(text, lineHeight)
	local lineHeight = lineHeight or self.lineHeight
	--local lhofs = math.floor( (lineHeight -self.lineHeight) / 2)

	local function newLine(x, y)
		return 0, y+lineHeight
	end

	local funclist = {}

	for i,v in ipairs(utf8_2_unicode(text)) do
		if (v == 10) then
			table.insert(funclist, self.chars[v] or newLine )
		elseif (self.chars[v]) then
			table.insert(funclist, self.chars[v] )
		else
			warning("Font don't have charactor: "..v.."")
		end
	end

	local function func(x, y, pageid)
		x = x or 0
		y = y or 0
		-- y = y + lhofs
		for i,v in ipairs(funclist) do
			x, y = v(x, y, pageid)
		end
		return newLine(x, y)
	end

	local function getSize()
		local x, y = 0, 0
		local w, h = 0, 0
		for i,v in ipairs(funclist) do
			x, y = v(x, y, pageid)
			w = math.max(x, w)
			h = math.max(y, h)
		end
		x, y = newLine(x, y)
		w = math.max(x, w)
		h = math.max(y, h)
		return w, h
	end

	local function render(x, y)
		for pageid = 1, self.pageCount or 1 do
			local page = self.pages[pageid]
			if (page) then
				if (not page:isLoaded()) then
					page:load()
				end
				func(x or 0, y or 0, pageid)
			end
		end
	end

	return render, getSize
end

local function parseFntLine(line)
	local cmd, rest = line:match("(%w+)%s(.*)")
	if (not cmd) then
		return line, {}
	end
	local args = {}
	for k,v in rest:gmatch("(%w+)=(%S+)") do
		local s = v:match("%\"(.+)%\"")
		if (s) then
			args[k] = s
		else
			args[k] = tonumber(v)
		end
	end
	return cmd, args
end

local drawRect = render2d.drawRectWithTexture

if (not drawRect) then
	local drawtri = render2d.drawTriangleWithTexture

	function drawRect(tex, l, t, r, b, tl, tt, tr, tb)
		drawtri(
			tex, 
			l, t, tl, tt, 
			r, t, tr, tt,
			r, b, tr, tb
			)
		drawtri(
			tex, 
			l, t, tl, tt,
			r, b, tr, tb,
			l, b, tl, tb
			)
	end
end

local function generateCharRenderer(args, pages)
	local pageid = args.page + 1
	local page = pages[pageid]

	local xadvance = args.xadvance

	local w, h = args.width, args.height
	local xofs, yofs = args.xoffset, args.yoffset
	local tx, ty = args.x, args.y

	local function render(x, y)
		drawRect(page, 
			x+xofs, y+yofs, x+xofs+w, y+yofs+h,
			tx, ty, tx+w, ty+h
		)
	end

	return function(x, y, _pageid)
		if (_pageid == pageid) then
			render(x, y)
		end

		return x + xadvance, y
	end
end

function loadFntFile(uri)
	local fd = io.open(uri, "r")
	local ret = {}
	ret.pages = {}
	ret.chars = {}

	local charTables = {}

	for line in fd:lines() do
		local cmd, args = parseFntLine(line)

		if (cmd == 'common') then
			ret.lineHeight = args.lineHeight
			ret.base = args.base
			ret.pageCount = args.pages
		elseif (cmd == 'page') then
			local file = urilib.normjoin(urilib.dirname(uri), args.file)
			ret.pages[args.id+1] = resource.loadTexture(file)
		elseif (cmd == 'char') then
			table.insert(charTables, args)
		end
	end

	for i,args in ipairs(charTables) do
		local charR = generateCharRenderer(args, ret.pages)
		ret.chars[args.id] = charR
	end

	fd:close()

	return ret
end

_G.Font = define_type("Font", Font)

local Text = {}

local function rebuildText(self)
	local font = self.font
	local text = self.text
	local lh = self.lineHeight

	self._renderText, self.getSize = font:generateRenderer(text, lh)
end

local function rebuildRender(self)
	local ax, ay = self.ax, self.ay
	local w, h = self:getSize()
	local x, y = w*(-ax-0.5), h*(-ay-0.5)
	local renderText = self._renderText

	local push_matrix = render.matrix.push
	local pop_matrix = render.matrix.pop
	local translate_matrix = render.matrix.pushTranslate

	function self:__call()
		push_matrix()
		translate_matrix(x, y)
		renderText(0, 0)
		pop_matrix()
	end
end

function Text:__init__(font, text)
	self.font = font
	self.text = text or ""
	self.ax = 0
	self.ay = 0
	rebuildText(self)
	rebuildRender(self)
end

function Text:setText(text)
	self.text = (text and tostring(text))  or ""
	rebuildText(self)
	rebuildRender(self)
end

function Text:setLineHeight(lh)
	self.lineHeight = lh
	rebuildText(self)
	rebuildRender(self)
end

function Text:setFont(font)
	self.font = font
	rebuildText(self)
	rebuildRender(self)
end

function Text:setAnchor(ax, ay)
	self.ax, self.ay = ax, ay
	rebuildRender(self)
end

function Text:getAnchor()
	return self.ax, self.ay
end

Text = define_type("display.presentations.Text", Text)
local pss = display.presentations

pss.Text = Text
pss.newText = Text.new

return _G.Font
