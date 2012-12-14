local Node = requireClass("ui.Node").methods

local function touchListener(self, ev)

	local function touchUpdateListener(type, ev)
		if (ev.type == 'up') then
			self._node:evTouchUp()
		end
	end

	self._node:evTouchDown()
	ev:addListener(touchUpdateListener)
	function removeUpdateListener()
		ev:removeListener(touchUpdateListener)
	end
end

function Node:catchTouch()
	self._node.evTouchDown = self._node.evTouchDown or event.Dispatcher.new()
	self._node.evTouchUp = self._node.evTouchUp or event.Dispatcher.new()
	self.evTouchDown = self._node.evTouchDown
	self.evTouchUp = self._node.evTouchUp

	table.insert(self._listeners, touchListener)

	self.catchTouch = values
	self.stopCatchTouch = function(self)
		self.catchTouch = nil
		self.stopCatchTouch =  nil
		
		table.remove(self._listeners, table.find(self.listeners, touchListener))
	end
	return self
end

Node.stopCatchTouch = values

return Node.catchTouch