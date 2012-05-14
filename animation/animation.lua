require("sprite_ex")
require("seed_ex")
local urilib = require("uri")
local plist = require("plist")

local Animation = {}

local _loaded = newWeakValueTable()

function Animation:__init__()
	error("Use newWith/newWithPlist/newWithData instead!")
end

function Animation:__init__With(sheet, set, shedata,setdata, framemap, imguri)
	self._sheet = sheet
	self._set = set
	
	self._shedata = shedata
	self._framemap = framemap
	self._imguri = imguri
end

function Animation:__init__WithPlist(uri,fps,flags)
	local flags = flags or "sprite"
	uri = urilib.absolute(uri, 2)
	local org = _loaded[uri]
	if (org) then
		self:__init_With(org._sheet, org._set)
	else
		self:__init__With(plist.loadPlistSheet(uri,fps,flags))
	end
end
function Animation:__init__WithArray(uri,array)
	uri = urilib.absolute(uri, 2)
	local org = _loaded[uri]
	if (org) then
		self:__init_With(org._sheet, org._set)
	else
		self:__init__With(plist.loadPlistSheet(uri,array))
	end
end

function Animation:WithDirections(dt)
	self._dt = dt
	return self
end

define_type("Animation", Animation)

local pss = display.presentations
pss.newSpriteWith = function(rt, ani, action)
	if (ani.type == Animation.type) then
		if (ani._dt) then
			return pss.newDSprite(rt, ani._sheet, ani._set, ani._dt, action)
		else
			return pss.newSprite(rt, ani._sheet, ani._set, action)
		end
	end
	return nil
end

local unpack = table.unpack
pss.newImageRectWithAni = function(self, name)
	local id = self._framemap[name]
	assert(id)
	local r = self._shedata[id]
	assert(r)
	local sx, sy, sr, sb = unpack(r, 1, 4)
	local dx, dy, dr, db = unpack(r, 5, 8)
	local ret = pss.newImageRect(self._imguri, 
			{sx, sy, sr-sx, sb-sy},
			{dx, dy, dr-dx, db-dy}
		)
	local w,h =  dr-dx, db-dy
	
	function ret:getSize()
		return w,h
	end
	return ret
end


