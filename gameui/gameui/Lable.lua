local UIBase = requireClass("gameui.UIBase")
require("Font")
--[[
	Lable类
]]
local Lable = {}

function Lable:__init__WithData(father, data, symbolTable)
	UIBase.methods.__init__WithData(self, father, data, symbolTable)

	if data.data.color then
		--MaskColor
		self.color = {}
		for k, v in pairs(data.data.color) do
			self.color[k] = v
		end
	end
end



function Lable:toNode(selectorTable, rta)
	UIBase.methods.toNode(self, selectorTable, rta)
	local node = self.node
	local fnt = Font.newWithUri(gameui.toAbsolute(self.font))
	node.presentation = display.presentations.newText(fnt, self.string)
	
	if self.anchorEnabled then
		node:setAnchor(self.anchorx, self.anchory)
	else
		
	end
end

return extend_type("gameui.Lable", Lable, UIBase)