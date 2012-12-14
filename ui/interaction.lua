require("fungus")
local ui = require("ui")

local loadFunction = loadFunction
local loadObject = loadObject
local require = require
local print = print
local _ENV = {}

function button(data, baseuri, ns)
	local evTapped = data.evTapped and loadFunction(data.evTapped, baseuri, ns)
	local shape = data.shape and loadObject(data.shape, baseuri, ns)
	return function(view, rta)
		local node = 
			ui.registerNode(rta, view.node:newNode())
				:catchTap()
				:withShape(shape)
			
		if (evTapped) then
			node.evTapped:addListener(evTapped)
		end
		
		if (ui.dbg_show_interaction_rect) then
			local dbg = view.node:newNode()
			dbg.presentation = function()
				shape:render()
			end
			dbg:setMaskColor(0.4, 1, 0.6, 0.6)
		end
	end
end

return _ENV
