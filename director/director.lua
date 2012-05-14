module(..., package.seeall)

local runtime = require("runtime")

local current = nil
local currt = nil

leavingModule = event.Dispatcher.new()
enterModule = event.Dispatcher.new()

function load(module, ...)
	if (currt) then
		leavingModule(current, currt)
		currt:remove()
	end
	
	display:clearStages()
	
	local m = module
	if (type(m) == 'string') then
		m = loadscript(m)
	end
	
	local rt = runtime:newAgent()
	local ret = m(rt, ...)
	
	current = ret
	currt = rt
	enterModule(ret, rt)
	return ret
end
