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
	else
		assert(false, "stage for display_ex must can be called.")
	end
end
display.addStage = addStage

local function removeStage(stage)
	display.render:removeListener(stage)
end
display.removeStage = removeStage

local function removeAllStages(stage)
	display.render:clearListeners()
end
display.removeAllStages = removeAllStages
display.clearStages = removeAllStages

-- 使引擎提供的Stage可以被当做函数使用
local Stage2D = display.Stage2D
local BgColorStage = display.BgColorStage
display.Stage2D.__call = display.Stage2D.methods.render
display.BgColorStage.__call = display.BgColorStage.methods.render

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

