local UIBase = requireClass("gameui.UIBase")
local ScreenMask = {}

function ScreenMask:__init__WithData(father, data, symbolTable)
	UIBase.methods.__init__WithData(self, father, data, symbolTable)
end

function ScreenMask:toNode(selectorTable, rta)
	UIBase.methods.toNode(self, selectorTable, rta)

	local sm = requireClass("ui.ScreenMask").new()
	local uiNode = ui.registerNode(rta, self.node):withShape(sm):catchTap():catchDrag()
	
	if self.selector then
		selectorTable[self.selector] = uiNode.evTapped
	elseif self.name then
		selectorTable[self.name .. "_evTapped" ] = uiNode.evTapped
	end
end

return extend_type("gameui.ScreenMask", ScreenMask, UIBase)

