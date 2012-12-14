local Node = requireClass("ui.Node").methods

local function tapListener(self, ev, x, y)
	local screenToLocal = self._node.screenToLocal or self._node.screenToWorld
	local function tapCaptureListener(type, ev)
		if (type == 'up') then
			ev:over()
			--TODO: TappedEvent
			local lx, ly = screenToLocal(self._node, ev.x, ev.y)
			local r = {
				rawx = ev.x, 
				rawy = ev.y,
				x = lx,
				y = ly,
			}
			self._node:evTapped(r)
		end
	end
	
	-- tap不处理已被他人截获的事件
	if (ev:captured() or ev:overed()) then
		return
	end
	
	ev.target = self
	ev:capture(tapCaptureListener)
end

function Node:catchTap()
	self._node.evTapped = self._node.evTapped or event.Dispatcher.new()
	self.evTapped = self._node.evTapped
	table.insert(self._listeners, tapListener)

	self.catchTap = values
	self.stopCatchTap = function(self)
		self.catchTap = nil
		self.stopCatchTap =  nil
		
		table.remove(self._listeners, table.find(self._listeners, tapListener))
	end
	return self
end

Node.stopCatchTap = values

return Node.catchTap
