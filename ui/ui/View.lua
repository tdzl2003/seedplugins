require("fungus")
local FObject = requireClass("FObject")
require("ui")
local defaultlayout = require("ui.layout").default

local View = {}

function View:__init__WithData(data, baseuri, ns)
	FObject.methods.__init__WithData(self, data, baseuri, ns)
	
	self.displayFunc = data.display and loadFunction(data.display, baseuri, ns)
	
	self.layoutFunc = (data.layout and loadFunction(data.layout, baseuri, ns, defaultlayout)) 
		or defaultlayout({}, baseuri, ns)
	
	self.interactionFuncs = event.Dispatcher.new()
	for i,v in ipairs(data.interactions or {}) do
		self.interactionFuncs:addListener(
			loadFunction(v, baseuri, ns)
		)
	end
	
	self.visible = (data.visible == nil) or data.visible
	
	self.bg = data.background
end

function View:start(rta, parentNode)
	if (not parentNode) then
		if (self.bg) then
			local bg = display:newBgColorStage()
			if (type(self.bg) == 'table') then
				local t = {'red', 'green', 'blue', 'alpha'}
				for i,v in ipairs(t) do
					if (self.bg[v]) then
						bg[v] = self.bg[v]
					end
				end
			end
		end
		local stage = display:newStage2D()
		local camera = display.Camera2D.new()
		camera.x, camera.y = 0,0
		stage.camera = camera
		parentNode = stage
	end
	self.parentNode = parentNode
	
	self.node = parentNode:newNode()
	
	if (not self.visible) then
		self.node:hide()
	end
	
	if (self.layoutFunc) then
		self:layoutFunc(rta)
	end

	if (self.displayFunc) then
		self.display = self:displayFunc(rta)
	end
	
	self:interactionFuncs(rta)
	
	for i,v in ipairs(self.childs) do
		v:start(rta, self.node)
	end
		
	self:layout()
	return self.node
end

function View:getContentSize()
	return 0, 0
end

function View:setContentSize(w, h)
end

function View:setPosition(x, y)
end

function View:getPosition()
	return 0, 0
end

function View:layout()
end

function View:requestLayout()
end

local ViewType = extend_type("ui.View", View, FObject)
View.childType = ViewType

return ViewType
