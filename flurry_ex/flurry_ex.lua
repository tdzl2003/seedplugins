--插件名称:flurry_ex
--插件版本:ver1.0
--插件作用:加载flurry模块,自动统计进入界面的事件及时间
--插件用法:
	--require("flurry_ex") 或 local flurry = require("flurry_ex")
	--此时会统计所有界面的事件.事件名称与界面名称一致
	--需要添加统计参数时,在对应界面的代码中添加flurry.args = {parm1 = "test"}

require("director")

local function nop() --空函数
end
_G.flurry = require("flurry") 

if _OS_NAME == "win32" then 
 	flurry = {init = nop,logEvent = nop,endTimedEvent = nop,setUserInfo = nop}
end
if not director.enterModule then 
	error("需要director 0.2版本以上支持/need director ver.0.2")
end

director.enterModule:addListener(function(module,rtAgent)
		flurry.logEvent(module,args,true) 
		-- print("加载模块:",module)
	end)
director.leavingModule:addListener(function(module,rtAgent)
		-- print("卸载模块:",module)
		flurry.args = nil
		flurry.endTimedEvent(module)
	end)
return flurry