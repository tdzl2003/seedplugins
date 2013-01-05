require("seed_ex")

local Event = {}

function Event:__init__(ev)
	self.index = ev.index
	self.x, self.y = ev.x, ev.y
	self.time = ev.time
	
	self.evCapture = event.Dispatcher.new()
	self.evUpdate = event.Dispatcher.new()
end

function Event:update()
	if (self:overed()) then
		return
	end
	self.evCapture('update', self)
	
	if (not self:exclusive()) then
		self.evUpdate('update', self)
	end
end

function Event:touchUp()
	if (self:overed()) then
		return
	end
	self.evCapture('up', self)
	
	if (not self:exclusive()) then
		self.evUpdate('up', self)
	end
end

Event.captured = false_
Event.exclusive = false_
function Event:listened()
	return self._listenerCount and self._listenerCount>0
end
Event.overed = false_

function Event:capture(f)
	self.evCapture:clearListeners()
	self.evCapture:addListener(f)
	self.captured = true_
end

function Event:addListener(f)
	self.evUpdate:addListener(f)
	self._listenerCount = (self._listenerCount or 0) + 1
end

function Event:removeListener(f)
	self.evUpdate:removeListener(f)
	self._listenerCount = self._listenerCount - 1
end

function Event:exclude()
	self.evUpdate:clearListeners()
	self.exclusive = true_
end

function Event:over()
	self.captured = true_
	self.overed = true_
end

return define_type("ui.TouchEvent", Event)
