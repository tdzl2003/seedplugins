local Animation = requireClass("animation")
local uri = require("uri")
local pss = display.presentations
local ui = ui or require("ui")
local Font = requireClass("Font")
local Dispatcher   = event.Dispatcher
local config = require("debugcfg")

local function parseNumpair(str, dx, dy)
	if (not str) then
		return dx or 0, dy or 0
	end
	local x, y = str:match("([%-%d%.]+),%s*([%-%d%.]+)")
	return tonumber(x), tonumber(y)
end

local function image(data, baseuri, ns)
	local ax, ay = parseNumpair(data.anchor, data.anchorx, data.anchory)
	local uri = loadUri(data.img, baseuri, ns)
	
	local spax, spay = parseNumpair(data.parentanchor, data.parentanchorx, data.parentanchory)

	return function(view, rtagent)
		local ret = view.node:newImage(uri)
		
		ret:setAnchor(ax, ay)
		local pax, pay = spax, spay
		
		local px, py = view:getContentSize()
		ret.x = pax*px
		ret.y = pay*py
		
		function ret:setParentAnchor(ax, ay)
			pax, pay = ax, ay
			ret.x = pax*px
			ret.y = pay*py
		end
		
		if (ui.dbg_show_rect) then
			local dbg = view.node:newNode()
			local render2d = require("render2d")
			dbg.presentation = function()
				local w, h = view:getContentSize()
				render2d.drawRect(-w/2, -h/2, w/2, h/2)
			end
			dbg:setMaskColor(0, 1, 0)
		end
		if config.display.hide_ui then 
			ret:hide()
		end
		return ret
	end
end

local function sprite(data, baseuri, ns)
	local ax, ay = parseNumpair(data.anchor, data.anchorx, data.anchory)
	
	local action = data.action
	local ani = Animation.newWithPlist(loadUri(data.plist, baseuri, ns))
	
	local spax, spay = parseNumpair(data.parentanchor, data.parentanchorx, data.parentanchory)

	return function(view, rtagent)
		ani:load()
		local ret = view.node:newSpriteWith(rtagent, ani, action)
		
		ret:setAnchor(ax, ay)
		local pax, pay = spax, spay
		
		local px, py = view:getContentSize()
		ret.x = pax*px
		ret.y = pay*py
		
		function ret:setParentAnchor(ax, ay)
			pax, pay = ax, ay
			ret.x = pax*px
			ret.y = pay*py
		end
		
		if (ui.dbg_show_rect) then
			local dbg = view.node:newNode()
			local render2d = require("render2d")
			dbg.presentation = function()
				local w, h = view:getContentSize()
				render2d.drawRect(-w/2, -h/2, w/2, h/2)
			end
			dbg:setMaskColor(0, 1, 0)
		end
		if config.display.hide_ui then 
			ret:hide()
		end
		return ret
	end
end

local function text(data,baseuri,ns) --文本
	local ax, ay = parseNumpair(data.anchor, data.anchorx, data.anchory)
	local spax, spay = parseNumpair(data.parentanchor, data.parentanchorx, data.parentanchory)
	local fntUri = data.fnt
	local fnt = Font.newWithUri(loadUri(fntUri,baseuri,ns))
	local height = data.height

	local setText 
	if data.setText then 
		setText = loadFunction(data.setText or {}, baseuri, ns)
	end
	local defaultText = (setText and setText()) or (data.text and tostring(data.text)) or ""
	return function (view,rtagent)
		local stage = display:newStage2D()
		local text = view.node:newText(fnt, defaultText)
		text:setAnchor(ax, ay)
		local pax, pay = spax, spay
		local px, py = view:getContentSize()
		text.x = pax*px
		text.y = pay*py
		if height then 
			text:setLineHeight(height)
		end
		if (ui.dbg_show_rect) then
			local dbg = view.node:newNode()
			local render2d = require("render2d")
			dbg.presentation = function()
				local w, h = view:getContentSize()
				render2d.drawRect(-w/2, -h/2, w/2, h/2)
			end
			dbg:setMaskColor(0, 1, 0)
		end
		if config.display.hide_ui then 
			text:hide()
		end
		return text
	end
end
return {sprite = sprite, image = image ,text = text}
