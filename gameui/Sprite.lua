local UIBase = requireClass("gameui.UIBase")
local Sprite = {}

function Sprite:__init__WithData(father, data, symbolTable)
	UIBase.methods.__init__WithData(self, father, data, symbolTable)

	--MaskColor
	
	if data.data.color then
		self.color = {}
		for k, v in pairs(data.data.color) do
			self.color[k] = v
		end
	else
		self.color = {1, 1, 1, 1}
	end

	--blendEff
	
	if data.data.blendEff then
		self.blendEff = {}
		for k, v in pairs(data.data.blendEff) do
			self.blendEff[k] = v
		end
	end

end

function Sprite:toNode(selectorTable, rta)
	
	UIBase.methods.toNode(self, selectorTable, rta)
	local node = self.node
	
	local sheet_set = Animation.newWithPlist(gameui.toAbsolute(self.sets), 0, 0)
	if DEBUG and DEBUG.showUIData then
		print("self.action =", self.action)
	end

	if sheet_set and self.action and self.action ~= "" then
		node.presentation = display.presentations.newSpriteWith(rta, sheet_set, self.action)
		--newImageRectWithAni(sheet_set, self.action)
		node:setFlip(self.flipx, self.flipy)
		
		if self.flipx then self.anchorx = -self.anchorx end
		if self.flipy then self.anchory = -self.anchory end
		
		if self.anchorEnabled then
			node:setAnchor(self.anchorx, self.anchory)
		end
	else
		warning("the action of", self, "is nil or empty")
	end
--	if self.flag then
--		node:setFlag(self.flag)
--	end


	return self
end

function Sprite:withDebug()
	self.node:newNode().presentation = function()
		render2d.fillCircle(0, 0, 4)
	end
	return self
end

return extend_type("gameui.Sprite", Sprite, UIBase)
