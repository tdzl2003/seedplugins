--[[
seed插件：
	director

	版本：
		0.2.2

	最后更改日期：
		2012-12-24

	更新记录：
		v0.2.2:
			1.去除了currt.native的判定.现在可以正确的leavingModule了
		v0.2.1:
			1.现在可以获得模块名称了
		v0.2.
			1.插件重构
			2.加入手动的垃圾回收collectgarbage()
			3.加入leavingModule与enterModule事件
	说明：
		用来控制多个场景之间的切换
	
	注意：虽然与doscript用法很像，但director会释放掉之前的runtime，重新创建runtime，并清除之前的stage
]]--
module(..., package.seeall)

local runtime = require("runtime")

local current = nil
local currt = nil

local unpack = unpack or table.unpack

leavingModule = event.Dispatcher.new()
enterModule = event.Dispatcher.new()

--[[
函数：director.load(module [, ...])

	参数：
		module - 要载入的module,一般用来载入.lua脚本文件
			如果要载入"sample\sample_1\main.lua"，那么第一个参数要填写："sample.sample_1.main"
		... - 【可选】可以在要载入的脚本文件里使用 ... 来获取runtime以及额外参数
	
	返回值：
		载入的module会被当成一个函数返回

	用法示例：
		=============================================================
		
		--文件：main.lua
			local a, b = 12, 24
			local ret = director.load("sample.sample_1.main", a, b)
			print(ret)						--结果为：36

		=============================================================
		
		--文件：sample\sample_1\main.lua
			local runtime, a, b = ...		--runtime为director所创建
			print(a, b)						--结果为：12 24
			return a + b
		
		=============================================================

]]--

local loading
local chainLoad

function load(module, ...)
	if (loading) then
		chainLoad = {module, ...}
		return true
	end
	loading = true
	if currt then
		leavingModule(current, currt)
		currt:remove()
	end
	
	display:clearStages()
	
	local m = module
	if (type(m) == 'string') then
		m = loadscript(m)
	end
	
	local rt = runtime:newAgent()
	currt = rt
	
	local ret = m(rt, ...) or module
	
	collectgarbage()

	current = ret
	enterModule(ret, rt)
	
	loading = false
	if (chainLoad) then
		local cl = chainLoad
		chainLoad = nil
		return load(unpack(cl))
	end
	return ret
end


function currentRuntimeAgent()
	return currt
end

function currentModule()
	return current
end
