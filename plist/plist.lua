local io = io
local string = string
local table = table
local xmlParser = require("xmlParser")
local raw = require("raw")
local bit32 = bit32

local setmetatable = setmetatable
local assert = assert
local tonumber = tonumber
local tostring = tostring
local error = error
local type = type
local unpack = table.unpack
local ipairs = ipairs
local pairs = pairs

local display = display

local uri = require("uri")
local absolute = uri.absolute
local basename = uri.basename
local splitext = uri.splitext
local splituri = uri.split
local normjoin = uri.normjoin
local joinuri = uri.join
local print = print
_ENV = {}

local xmlhandler_mt = {
	__index = {
		result = function(self)
			return self._ret
		end,
		push = function(self, val)
			table.insert(self._stack, val)
		end,
		top = function(self, pos)
			local stack = self._stack
			pos = pos or 0
			return stack[#stack + pos]
		end,
		pop = function(self, pos)
			local stack = self._stack
			pos = #stack + (pos or 0)
			local top = stack[pos]
			stack[pos] = nil
			return top
		end,
		decl = function(self, t, a)
			if (a.encoding and a.encoding ~= "UTF-8") then
				error("plist was not encoded as UTF-8")
			end
			self._decl = true
		end,
		dtd = function(self, t, a)
			if (a._root == "plist" and a._uri == "http://www.apple.com/DTDs/PropertyList-1.0.dtd") then
				self._dtd = true
			end
		end,
		starttag = function(self,t,a,s,e)
			if (t == "plist") then
				assert(not self._stack)
				assert(self._decl and self._dtd)
				self._stack = {}
				self.ebp = 0
			else
				self:push(t)
				if (t == "dict" or t == "array") then
					self:push(self.ebp)
					self.ebp = #self._stack
				end
				self.ebp1 = #self._stack
			end
		end,
		endtag = function(self,t,s,e)
			if (t ==  "plist") then
				assert(#self._stack == 1)
				self._ret = self._stack[1]
				self._stack = nil
			else
				if (t == "true") then
					self:push(true)
				elseif (t == "false") then
					self:push(false)
				elseif (t == "dict") then
					local t = {}
					while (#self._stack > self.ebp) do
						local v = self:pop()
						local k = self:pop()
						t[k] = v
					end
					self.ebp = self:pop()
					self:push(t)
				elseif (t == "array") then
					local t= {}
					while (#self._stack > self.ebp) do
						local v = self:pop()
						table.insert(t, v)
					end
					local s = #t
					for i=1, s/2 do
						local v=t[i]
						t[i] = t[s-i+1]
						t[s-i+1]=v
					end
					self.ebp = self:pop()
					self:push(t)
				else
					assert(t == "string" or t == "integer" or t == "real" or t == "key" or top == "date")
					if (self.ebp1 == #self._stack) then
						if (t == "string") then
							self:push("")
						else
							error("Empty field for type "..t)
						end
					end
				end
				local tmp = self:pop()
				self:pop()
				self:push(tmp)
			end
		end,
		text = function(self,t,s,e)
			local top = self:top()
			if (top == "key" or top == "string" or top == "date") then
				self:push(t)
			elseif (top == "integer" or top == "real") then
				self:push(tonumber(t))
			end
		end,
		cdata = function(self,t,s,e)
		end,
		comment = function(self,t,s,e)
		end
	}
}

local function parseXml(s)
	local h = {}
	setmetatable(h, xmlhandler_mt)
	xmlParser.parse(h, s)
	return h:result()
end

local function bytesToInt(s, i, j)
	local r = 0
	i = i or 1
	j = j or #s
	for p = i, j do
		r = bit32.bor(bit32.lshift(r, 8), s:byte(p))
	end
	return r
end

local parseBinaryHelper

local function parseBinaryBool(s, id, h)
	if (h == 0) then
		return nil
	elseif (h == 8) then
		return false
	elseif (h == 9) then
		return true
	else
		error ("Plist: unknown header " .. h)
	end
end


local function parseBinaryInt(s, id, h, ofs)
	local c = bit32.lshift(1, bit32.band(h, 0xf))
	return bytesToInt(s, ofs+1, ofs+c)
end

local function parseBinaryReal(s, id, h, ofs)
	print(s, id, h, ofs)
	print(ofs)
	local c = bit32.lshift(1, bit32.band(h, 0xf))
	print(ofs+1)
	print(ofs+c)
	return raw.bytesToDoubleBE(s, ofs+1, ofs+c)
end

local function parseBinaryString(s, id, h, ofs)
	local count = bit32.band(h, 0xf)
	ofs = ofs + 1
	if (count >= 15) then
		local cc = bit32.lshift(1, bit32.band(s:byte(ofs), 0xf))
		count = bytesToInt(s, ofs+1, ofs+cc)
		ofs = ofs + cc + 1
	end
	
	return s:sub(ofs, ofs + count - 1)
end

local function getRefsForContainers(s, id, h, ofs, mult, ofst, objt, outt)
	local count = bit32.band(h, 0xf)
	ofs = ofs + 1
	if (count >= 15) then
		local cc = bit32.lshift(1, bit32.band(s:byte(ofs), 0xf))
		count = bytesToInt(s, ofs+1, ofs+cc)
		ofs = ofs + cc + 1
	end
	
	local r = outt or {}
	local bs = ofst.ors
	
	for i=1,count*mult do
		local ref = bytesToInt(s, ofs, ofs + bs - 1) + 1
		ofs = ofs + bs
		r[i] = objt[ref] or parseBinaryHelper(s, ref, ofst, objt)
	end
	return r
end

local function parseBinaryArray(s, id, h, ofs, ofst, objt)
	local t = {}
	objt[id] = t
	return getRefsForContainers(s, id, h, ofs, 1, ofst, objt, t)
end

local function parseBinaryDictionary(s, id, h, ofs, ofst, objt)
	local t = {}
	objt[id] = t
	local refs = getRefsForContainers(s, id, h, ofs, 2, ofst, objt)
	
	local count = #refs / 2
	for i = 1, count do
		local k = refs[i]
		if (type(k) ~= "string") then
			error "Plist: key of dictionary is not string"
		end
		t[k] = refs[i + count]
	end
	return t
end

local parseFuncSearchTable = {
	parseBinaryBool,
	parseBinaryInt,
	parseBinaryReal,
	parseBinaryDate,
	parseBinaryByteArray,
	parseBinaryString,
	
	[11] = parseBinaryArray,
	[14] = parseBinaryDictionary,
}

function parseBinaryHelper(s, id, ofst, objt)
	local ofs = ofst[id] + 1
	local h = s:byte(ofs)
	local t = bit32.rshift(h, 4) + 1
	
	local f = parseFuncSearchTable[t]
	local r = (f or error("Object type was not supported yet.")) and f(s, id, h, ofs, ofst, objt) 
	objt[id] = r
	return r
end

local function parseBinary(s)
	local size = #s
	if (size < 32) then
		error("not a valid plist file.")
	end
	
	local trailer = s:sub(-32)
	local _offsetByteSize = trailer:byte(7)
	local _objRefSize = trailer:byte(8)
	local _refCount = bytesToInt(trailer, 13, 16)
	local _offsetTableOffset = bytesToInt(trailer, 25, 32)
	
	local _offsetTable = {}
	local _objectTable = {}
	
	_offsetTable.bs = _offsetByteSize
	_offsetTable.ors = _objRefSize
	
	for i = _offsetTableOffset+1, size-32+1, _offsetByteSize do
		table.insert(_offsetTable, bytesToInt(s, i, i+_offsetByteSize-1))
	end
	
	return parseBinaryHelper(s, 1, _offsetTable, _objectTable)
end

function parse(s)
	if (string.sub(s, 1, 8) == "bplist00") then
		return parseBinary(s)
	else
		return parseXml(s)
	end
end

local function _parseUri(uri)
	local f = io.open(uri, "r")
	if (not f) then
		error("Cannot open uri "..uri)
	end
	local s = f:read()
	f:close()
	return parse(s)
end

--解析plist数据,返回table
function parseUri(uri)
	return _parseUri(absolute(uri, 2))
end

function matchInts(str, pat, scale)
	if not scale then 
		scale = 1
	end
	local rets = {str:match(pat)}
	for i,v in ipairs(rets) do
		rets[i] = tonumber(v) / scale
	end
	return unpack(rets)
end

local rectpat_tp = "{{([%d%.]+),%s*([%d%.]+)},%s*{([%d%.]+),%s*([%d%.]+)}}"
local sizepat_tp = "{([%-%d%.]+),%s*([%-%d%.]+)}"


local rectpat = "{{(%d+), (%d+)}, {(%d+), (%d+)}}"
local sizepat = "{(%d+), (%d+)}"


--plist动画
-- params:
--	uri - plist file URI
--	fps - played frame per seconds
--	flag -	0 action will be single frame
--			1 action will group be name
function loadPlistSheet(uri, fps,flag,array)
	uri = absolute(uri, 2)
	local suri, scale = uri, 1
	if (display.resourceFilter) then
		suri, scale = display.resourceFilter(uri)
		if (suri == true) then
			scale = 1
		end
	end
	local dir, name = splituri(uri)
	name = splitext(name)
	
	local plist = _parseUri(uri)
	local sheet = {}
	local set = {}
	
	pnguri = joinuri(dir, plist.metadata.realTextureFileName) or joinuri(dir, name..'.png')
	
	local frames = plist.frames
	local framenames = table.keys(frames)
	table.sort(framenames)
	
	local pref = name .. '_'
	
	local sets = {}

	local framemap = {}
	
	for i,v in ipairs(framenames) do
		local info = frames[v]
		framemap[v]=i
		v = splitext(v)
		if (v:startsWith(pref)) then
			v = v:sub(#name + 2)
		end
		local nn, id = v:match("([%w_]+)_(%d+)")
		if (not nn) then
			nn = v
			id = 1
		end
		
		if( info.frame ~= nil ) then
			do
				local sx, sy, sw, sh = matchInts(info.frame, rectpat_tp, scale)
				local dx, dy, dw, dh = matchInts(info.sourceColorRect, rectpat_tp, scale)
				local ox, oy = matchInts(info.offset, sizepat_tp, scale)
				local spw, sph = matchInts(info.sourceSize, sizepat_tp, scale)
				local flag
				local rot = info.rotated
				
				if rot == true then
					flag = 5
					sw, sh = sh, sw
					dw, dh = dh, dw
					spw, sph = sph, spw
					dx, dy = dy, dx
					ox, oy = oy, ox
				else
					flag = 0
				end
				dx = dx - spw / 2 + ox
				dy = dy - sph / 2 + oy
				sheet[i] = {sx, sy, sx+sw, sy+sh, dx, dy, dx + dw, dy + dh, spw, sph, flag} 
			end
		else
			do
				local sx, sy, sw, sh = matchInts(info.textureRect, rectpat_tp, scale)
				local dx, dy, dw, dh = matchInts(info.spriteColorRect, rectpat_tp, scale)
				local spw, sph = matchInts(info.spriteSourceSize, sizepat_tp, scale)
				dx = dx - spw/2
				dy = dy - sph/2
				sheet[i] = {sx, sy, sx+sw, sy+sh, dx, dy, dx+dw, dy+dh, spw, sph} 
			end
		end

		if flag == 1 then		
			local ff = 24
			
			if (fps) then
				if type(fps) == "table" then
					ff = fps[nn] or 24
				elseif type(fps) == "number" then
					ff = fps
				end
			end
			
	-----------lady samurai 专用----------------			
		if not array then 
			local se = sets[nn]
			if (se) then
				table.insert(se[2],i)
			else
				se = {nn, {i}, 1/24}
				table.insert(set, se)
				sets[nn] = se
			end
		end


		elseif flag == 0 then
			
			table.insert(set, {framenames[i], i, i, 1})
		
		else

		end

	end
	-----------lady samurai 专用----------------
		if array then 
		set = {}

		for i,v in pairs(array) do 
			local se = {tostring(i), {}, 1/24}
			for m,n in ipairs(v) do
				assert(framemap[n])
				table.insert(se[2],framemap[n])
			end
			if (#v > 0) then
				table.insert(set, se)
			end
		end
	end

	return display.newSheet(pnguri, sheet), display.newSpriteSet(set), sheet, set, framemap, pnguri
end

return _ENV
