local display = display
local print = print

local function parseNumpair(str, dx, dy)
	if (not str) then
		return dx or 0, dy or 0
	end
	local x, y = str:match("([%-%d%.]+),%s*([%-%d%.]+)")
	return tonumber(x), tonumber(y)
end

local _ENV = {}

function default(data, baseuri, ns)
	return function(view)
		local node = view.node
		local cw, ch = parseNumpair(data.size, data.width, data.height)
		local x, y = parseNumpair(data.position, data.x, data.y)
		local ax, ay = parseNumpair(data.anchor, data.anchorx, data.anchory)
		local pax, pay = parseNumpair(data.parentanchor, data.parentanchorx, data.parentanchory)

		function view:layout()
			local node = self.node
			if (not node) then
				return
			end
			local px, py
			if (self.parent) then
				px, py = self.parent:getContentSize()
			else
				local stage = self.node
				if (stage.camera) then
					px, py = stage.camera.width, stage.camera.height
				else
					px, py = display.getContentSize()
				end
			end
			node.x = pax*px-ax*cw + x
			node.y = pay*py-ay*ch + y
		end
		function view:setPosition(_x, _y)
			x, y = _x, _y
			self:layout(self)
		end
		function view:setAnchor(x, y)
			ax, ay = x, y
			self:layout(self)
		end
		function view:setParentAnchor(x, y)
			pax, pay = x, y
			self:layout(self)
		end
		function view:setContentSize(w, h)
			cw, ch = w, h
		end
		function view:getPosition()
			return x, y
		end
		function view:getContentSize()
			return cw, ch
		end
		function view:getAnchor()
			return ax, ay
		end
		function view:getParentAnchor()
			return pax, pay
		end
	end
end

return _ENV