local Node = requireClass("ui.Node").methods

local function holdListener(self, ev)
	local startTime = ev.time
	local sx, sy = ev.x, ev.y	-- 取屏幕坐标。
	local removeUpdateListener
	local function holdUpdateListener(type, ev)
	
		if (ev:overed() or ev:exclusive()) then
			return
		end
		
		local dx = sx - ev.x
		local dy = sy - ev.y
		if (math.abs(dx)+math.abs(dy) > 5) then
			removeUpdateListener()
			return
		end
		
		if (ev.time - startTime > 0.5) then
			ev:capture(nop)
			ev.target = self
			ev:exclude()
			self._node:evHolded(ev)
		end
	end
	
	if (ev:overed() or ev:exclusive()) then
		return
	end
	
	ev:addListener(holdUpdateListener)
	
	function removeUpdateListener()
		ev:removeListener(holdUpdateListener)
	end
end

function Node:catchHold()
	self._node.evHolded = self._node.evHolded or event.Dispatcher.new()
	self.evHolded = self._node.evHolded
	table.insert(self._listeners, holdListener)

	self.catchHold = values
	self.stopCatchHold = function(self)
		self.catchHold = nil
		self.stopCatchHold =  nil
		
		table.remove(self._listeners, table.find(self.listeners, holdListener))
	end
	return self
end

Node.stopCatchHold = values

return Node.catchHold