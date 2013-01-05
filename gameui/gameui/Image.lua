local UIBase = requireClass("gameui.UIBase")
local Image = {}

function Image:__init__WithData(father, data, symbolTable)
	UIBase.methods.__init__WithData(self, father, data, symbolTable)

	if data.data.color then
		--MaskColor
		self.color = {}
		for k, v in pairs(data.data.color) do
			self.color[k] = v
		end
	end

	if data.data.blendEff then
		--blendEff
		self.blendEff = {}
		for k, v in pairs(data.data.blendEff) do
			self.blendEff[k] = v
		end
	end
end

function Image:toNode(selectorTable, rta)
	UIBase.methods.toNode(self, selectorTable, rta)
	local node = self.node
	node.presentation = display.presentations.newImage(gameui.toAbsolute(self.image))
	if self.anchorEnabled then
		node:setAnchor(self.anchorx, self.anchory)
	else
		
	end
	
end

return extend_type("gameui.Image", Image, UIBase)