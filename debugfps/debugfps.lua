
local interval = 5 --打印fps时间间隔

local lt = interval
local count = 0
runtime.enterFrame:addListener(function(t, dt)
	count = count + 1
	if (t > lt) then
		print("FPS:"..count/interval)
		count = 0
		lt = lt + interval
	end
end)