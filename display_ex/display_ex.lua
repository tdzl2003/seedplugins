require("lua_ex")

-- 重写display.render、display.addStage/removeStage/clearStages
display.render = event.Dispatcher.new()
local function addStage(stage)
	if (is_function(stage)) then
		display.render:addListener(stage)
		if (type(stage) == 'table') then
			function stage:remove()
				display.removeStage(self)
			end
		end
	elseif (type(stage) == 'table' and is_function(stage.render)) then
		assert(stage ~= display, "display:addStage(stage) is deprecated, use display.addStage(stage) instead.")
		stage.__dorender = stage.__dorender or bind(stage.render, stage)
		display.render:addListener(stage.__dorender)
	else
		assert(false, "stage for display_ex must can be called.")
	end
end
display.addStage = addStage

local function removeStage(stage)
	if (type(stage) == 'table' and stage.__dorender) then
		display.render:removeListener(stage.__dorender)
	else
		display.render:removeListener(stage)
	end
end
display.removeStage = removeStage

local function removeAllStages(stage)
	display.render:clearListeners()
end
display.removeAllStages = removeAllStages
display.clearStages = removeAllStages

local Stage2D = display.Stage2D
local BgColorStage = display.BgColorStage
-- 使引擎提供的Stage可以被当做函数使用
function display:newBgColorStage(...)
	local ret = BgColorStage.new(...)
	addStage(ret)
	return ret
end

function display:newStage2D(...)
	local ret = Stage2D.new(...)
	addStage(ret)
	return ret
end

-- setBrightness
local function setBrightness(self, v)
	self:setMaskColor(v, v, v)
end
display.Stage2D.methods.setBrightness = setBrightness
display.Stage2D.Node.methods.setBrightness = setBrightness

