
local _rta = require("runtime").newAgent();

local total = 0;

resource.loadResource:addListener(function(res)
	total = total + res:getSize();
end)

resource.unloadResource:addListener(function(name, size)
	total = total - size;
end)

local lt = 5;
_rta.enterFrame:addListener(function(t, dt)
	local k, b = collectgarbage("count")     
	local code = k * 1024;
	if( t > lt )then
		print("Memory total: ",code+total,"Bytes.");
		lt = lt + 5;
	end
end);

