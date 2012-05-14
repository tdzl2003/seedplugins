require("lua_ex")

local pss = display.presentations
local Sprite = pss.Sprite

local orgPlayAction = Sprite.methods.playAction
local orgChangeAction = Sprite.methods.changeAction
local orgRestartAction = Sprite.methods.restartAction
local orgIsAniOver = Sprite.methods.isAniOver

local function DSplit_updateflip(self, d)
	self:setFlip(d and d.flipx, d and d.flipy)
end

local function DSprite_playAction(self, action, onover, ...)
	local st = self._coverlst or self._lst
	self._coverlst = st
	
	local a, d = self:_wdt(action)
	orgPlayAction(self, a, function()
		if onover then
			onover()
		end
		if (st and orgIsAniOver(self)) then
			orgRestartAction(self, self:_wdt(st))
			return true
		end
	end, ...)
	DSplit_updateflip(self, d)
end

local function DSprite_changeAction(self, action, ...)
	local a, d = self:_wdt(action)
	orgChangeAction(self, a, ...)
	DSplit_updateflip(self, d)
end

local function DSprite_restartAction(self, action)
	local a, d = self:_wdt(action)
	orgRestartAction(self, a)
	DSplit_updateflip(self, d)
end

local function DSprite_setDirection(self, x, y)
	self._dx = x
	self._dy = y
	local st = self._lst
	if (st) then
		local a, d = self:_wdt(st)
		orgChangeAction(self, a, true)
		DSplit_updateflip(self, d)
	end
end

local function wrap_dt(dt, set)
	local swrap = {}
	local dswrap = {}
	for i,v in ipairs(set.data) do
		local name = v[1]
		dswrap[name] = i
		
		for j,d in ipairs(dt) do
			if (name:endsWith('_'..d[3])) then
				local p = name:sub(1, -#d[3] -2)
				
				local t = swrap[p] or {}
				swrap[p] = t
				t[j] = i
			end
		end
	end
	return function(self, action)
		if (type(action) == 'number') then
			return action
		end
		local x, y = self._dx, self._dy
		
		local st
		if (type(action) == 'string') then
			st = swrap[action]
		else
			st = action
		end
		self._lst = st
		
		if (st) then
			local md, mv, ma
			for j,d in ipairs(dt) do
				if (st[j]) then
					local lv = x * d[1] + y * d[2]
					if (not md or lv > mv) then
						ma = st[j]
						mv = lv
						md = d
					end
				end
			end
			assert(md)
			return ma, md
		end
		
		local re = dswrap[action] or 0
		self._lst = re
		return re
	end
end

local function subtype(super, methods, name)
	local ret = {}
	
	for k,v in pairs(super) do
		ret[k] = v
	end

	local idx = ret.__index
	
	ret.__index = function(t, k)
		if (k == 'type') then
			return ret
		end
		return methods[k] or idx(t, k)
	end
	
	ret.name = name
	
	local orgnew = ret.new
	ret.new = function(...)
		local obj = orgnew(...)
		setmetatable(obj, ret)
		return obj
	end
	return ret
end


local DSprite = subtype(Sprite, {
	playAction = DSprite_playAction,
	changeAction = DSprite_changeAction,
	restartAction = DSprite_restartAction,
	setDirection = DSprite_setDirection,
	render = DSprite_render,
}, "display.presentations.DSprite")
pss.DSprite = DSprite

do
	local orgnew = DSprite.new
	local function new(rt, sheet, set, dt, action)
		local wdt = wrap_dt(dt, set)
		local ret = orgnew(rt, sheet, set)
		ret._wdt = wdt
		ret._dx = 1
		ret._dy = 0
		ret._fx = false
		ret._fy = false
		if (action) then
			ret:changeAction(action)
		end
		return ret
	end
	DSprite.new = new
	pss.newDSprite = new
end
