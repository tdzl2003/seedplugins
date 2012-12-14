local Rect = {}

--方便直接通过配置文件创建
function Rect:__init__(x, y, w, h)
	self.l = x
	self.t = y
	self.r = x + w
	self.b = y + h
end

function Rect:__init__WithRect(x, y, w, h)
	self.l = x
	self.t = y
	self.r = x + w
	self.b = y + h
end

function Rect:__init__WithSize(w, h)
	w = w/2
	h = h/2
	self.l = -w
	self.t = -h
	self.r = w
	self.b = h
end

if (_FUNGUS) then
	local FObject = requireClass("FObject").methods
	function Rect:__init__WithData(data, baseuri, ns)
		FObject.__init__WithData(self, data, baseuri, ns)
		self.id = data.id
		self.group = data.group
		self.groupid = data.groupid
		self.baseuri = baseuri
		
		local x, y, w, h = table.unpack(data.area)
		self:__init__WithRect(x, y, w, h)
	end
end

local render2d = require("render2d")
function Rect:render(fill)
	if fill then 
		render2d.fillRect(self.l, self.t, self.r, self.b)
	else 
		render2d.drawRect(self.l, self.t, self.r, self.b)
	end
end

function Rect:test(x, y)
	return (x >= self.l and x <= self.r and y >= self.t and y <= self.b)
end

if (_FUNGUS) then
	return extend_type("ui.Rect", Rect, requireClass("FObject"))
else
	return define_type("ui.Rect", Rect)
end
