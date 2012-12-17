--APIWrapper，将ImageRect的SrcRect对齐至纹理坐标左上角点更改为build126之前的不对齐
--在config.lua里面require该文件
if _SEED_VER_BUILD and _SEED_VER_BUILD >= 127 then

	local ori_ImageRect_new = display.presentations.ImageRect.new
	local ori_ImageRect_setSrcRect = display.presentations.ImageRect.methods.setSrcRect

	display.presentations.ImageRect.new = function(...)
		local pssImageR = ori_ImageRect_new(...)
		local l, t, r, b = pssImageR:getDestRect()
		local ax, ay = pssImageR:getAnchor()
		print(l, t, r, b)
		local sl, st, sr, sb = pssImageR:getSrcRect()
		print(sl, st, sr, sb)
		pssImageR:setDestRect(l + sl, t + st, r - l, b - t)
		print(pssImageR:getDestRect())
		return pssImageR
	end
	display.presentations.newImageRect = display.presentations.ImageRect.new

	display.presentations.ImageRect.methods.setSrcRect = function(self, ...)
		ori_ImageRect_setSrcRect(self, ...)
		local x, y, w, h = ...
		if type(x) == "table" then
			x, y, w, h = table.unpack(x)
		end
		local l, t, r, b = self:getDestRect()
		self:setDestRect(l + x, t + y, r - l, b - t)
	end
	
end
