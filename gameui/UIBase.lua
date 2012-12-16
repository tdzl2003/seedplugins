local UIBase = {}

function UIBase:__init__WithData(father, data, symbolTable)
	self.father = father
	if data.data then
		for k, v in pairs(data.data) do
			self[k] = v
		end
	end
--	print(data.type)

--	printTable(data, 2)
	--读取子节点的数据
	if data.childs then
		self.childs = {}
		for k, v in pairs(data.childs) do
			local node = gameui.createCCBNode(self, v, symbolTable)
			table.insert(self.childs, node)
		end
	end

	if type(data.name) == "string" and data.name ~= "" then
		self.name = data.name
		if symbolTable then
			symbolTable[data.name] = self
		end
	end

	--手动创建节点时，可以不填anchorEnabled选项，默认为支持锚点
	if self.anchorEnabled == nil then
		self.anchorEnabled = true
	end

end

function UIBase:toNode(selectorTable, rta)
--	print("======================")
--	print("createNode: ")

	local node = self.father.node:newNode()
	node.x, node.y, node.z = self.x or 0, self.y or 0, self.z or 0
	node.scalex, node.scaley = self.scalex or 1, self.scaley or 1
	node.rotation = self.rotation or 0
	if self.visible then
		node:show()
	else
		node:hide()
	end
	self.node = node
	if self.childs then
		for k, v in pairs(self.childs) do
			self.childs[k]:toNode(selectorTable, rta)
		end
	end
end

function UIBase:getNode()
	return self.node
end

function UIBase:withDebug()
	self.node:newNode().presentation = function()
		render2d.fillCircle(0, 0, 4)
	end
	return self
end

function UIBase:move(dx, dy)
	self.x = self.x + (dx or 0)
	self.y = self.y + (dy or 0)
	local node = self.node
	node.x, node.y = self.x, self.y
end

function UIBase:setPosition(x, y)
	self.x, self.y = x or self.x, y or self.y
	local node = self.node
	node.x, node.y = self.x, self.y
end

--使用hide和show方法，代替手动指定visible
function UIBase:hide()
	self.visible = false
	self.node:hide()
end

function UIBase:show()
	self.visible = true
	self.node:show()
	print(self.node:localToWorld(0, 0))
end
--使用transition对self.node 做渐变
function UIBase:transition(trs, rta,t,from,to)
	trs.start(rta,function()
		trs.linearAttrPeriodEx(self.node, t, {{"setAlpha",from,to}})
	end)
end

return define_type("gameui.UIBase", UIBase)
