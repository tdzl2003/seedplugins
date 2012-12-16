local UIBase = requireClass("gameui.UIBase")
local Layer = {}

function Layer:__init__WithData(father, data, symbolTable)
	UIBase.methods.__init__WithData(self, father, data, symbolTable)
end

function Layer:toNode(selectorTable, rta)
	UIBase.methods.toNode(self, selectorTable, rta)
end

return extend_type("gameui.Layer", Layer, UIBase)