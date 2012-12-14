local Circle = {}

function Circle:__init__WithRadius(r)
	self.x = 0
	self.y = 0
	self.r = r
	self.rr = r*r
end

function Circle:__init__WithPos(x, y, r)
	self.x = x
	self.y = y
	self.r = r
	self.rr = r*r
end

function Circle:test(x, y)
	local dx = self.x - x
	local dy = self.y - y
	return dx*dx+dy*dy < self.rr
end

local render2d = require("render2d")
function Circle:render(fill)
	if fill then 
		render2d.fillCircle(self.x, self.y, self.r)
	else 
		render2d.drawCircle(self.x, self.y, self.r)
	end
end

return define_type("ui.Circle", Circle)