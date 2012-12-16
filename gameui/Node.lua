local UIBase = requireClass("gameui.UIBase")
local Node = {}

function Node:__init__WithData(father, data, symbolTable)
	UIBase.methods.__init__WithData(self, father, data, symbolTable)
end

function Node:toNode(selectorTable, rta)
	UIBase.methods.toNode(self, selectorTable, rta)
end

return extend_type("gameui.MenuNode", Node, UIBase)