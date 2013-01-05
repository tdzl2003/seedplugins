require("lua_ex")
local ScreenMask = {}

ScreenMask.test = true_

local render2d = require("render2d")
function ScreenMask:render()
	--TODO：
end

return define_type("ui.ScreenMask", ScreenMask)