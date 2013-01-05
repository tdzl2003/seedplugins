local Node = requireClass("ui.Node").methods

local function dragListener(self, ev)
	local startTime = ev.time
	local sx, sy = ev.x, ev.y	-- 取屏幕坐标。
	local removeUpdateListener

	
	local function dragCaptureListener(type, ev)
		if (type == 'up') then
			self._node:evDragEnd(ev)
		else
			self._node:evDragging(ev)
		end
	end
	
	local function dragUpdateListener(type, ev)
		if (ev:overed() or ev:exclusive()) then
			return
		end
		
		local dx = sx - ev.x
		local dy = sy - ev.y
		if (math.abs(dx)+math.abs(dy) > 5) then
			ev:capture(dragCaptureListener)
			ev.target = self
			ev:exclude()
			self._node:evDragBegin(ev)
		end
	end
	
	if (ev:overed() or ev:exclusive()) then
		return
	end
	
	ev:addListener(dragUpdateListener)
	
	function removeUpdateListener()
		ev:removeListener(dragUpdateListener)
	end
end

function Node:catchDrag()
	self._node.evDragBegin = self._node.evDragBegin or event.Dispatcher.new()
	self._node.evDragEnd = self._node.evDragEnd or event.Dispatcher.new()
	self._node.evDragging = self._node.evDragging or event.Dispatcher.new()
	self.evDragBegin = self._node.evDragBegin
	self.evDragEnd = self._node.evDragEnd
	self.evDragging = self._node.evDragging
	table.insert(self._listeners, dragListener)

	self.catchDrag = values
	self.stopCatchDrag = function(self)
		self.catchDrag = nil
		self.stopCatchDrag =  nil
		
		table.remove(self._listeners, table.find(self.listeners, dragListener))
	end
	return self
end

Node.stopCatchDrag = values

return Node.catchDrag