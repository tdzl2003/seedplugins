
math.randomseed(os.time())	
local urilib = require("uri")
local r2d = require("render2d")
local plistParser = require("plist")


function __init__()
	error("Use newWithPlist/newWithData instead!")
end


--根据平均值和抖动范围计算最终值，可以加到数学库里
local function calcVariance(value, variance)
	return value + (math.random() - 0.5) * variance * 2
end

local function createNodePool(emit, psd, parentNode)
	for i = 1, psd.maxParticles do
		if(emit.debugMode) then 
			emit.node[i] = parentNode:newNode()
			emit.node[i].presentation = function()
				r2d.drawPoint(0,0)
			end
		elseif emit.texture == nil then
			emit.node[i] = parentNode:newNode()
			emit.node[i].presentation = function()
				r2d.fillRect(-emit.imgW / 2, -emit.imgH / 2, emit.imgW / 2, emit.imgH / 2)
			end
		else
			--使用了image，取消了宽高
			emit.node[i] = parentNode:newImage(emit.texture) -- 创建出全部粒子的Node
			emit.node[i]:setAnchor(0.5, 0.5)
		end
			emit.node[i]:hide()
			emit.particlesNeedActive[i] = i
	end
	if psd.particleLifespan ~= 0 then
		emit.maxParticlePerFrame = psd.maxParticles / (psd.particleLifespan * 60) 
	end
end

--初始化粒子系统所有属性，参数有效性检查都在这里进行
local function initAttr(data, emit, parentNode)
	local psd = {}
	psd = data
	
	--有效性检查，如数据为nil则赋初值
	psd.maxParticles = psd.maxParticles or 3500

	psd.particleLifespan = psd.particleLifespan or 0
	psd.particleLifespanVariance = psd.particleLifespanVariance or 0

	psd.sourcePositionx = psd.sourcePositionx or 0
	psd.sourcePositiony = psd.sourcePositiony or 0
	psd.sourcePositionVariancex = psd.sourcePositionVariancex or 0
	psd.sourcePositionVariancey = psd.sourcePositionVariancey or 0

	psd.startColorRed = psd.startColorRed or 1
	psd.startColorGreen = psd.startColorGreen or 1
	psd.startColorBlue = psd.startColorBlue or 1
	psd.startColorAlpha = psd.startColorAlpha or 1
	psd.startColorVarianceRed = psd.startColorVarianceRed or 0
	psd.startColorVarianceGreen = psd.startColorVarianceGreen or 0
	psd.startColorVarianceBlue = psd.startColorVarianceBlue or 0
	psd.startColorVarianceAlpha = psd.startColorVarianceAlpha or 0

	psd.startParticleSize = psd.startParticleSize or 0 
	psd.startParticleSizeVariance = psd.startParticleSizeVariance or 1
	psd.finishParticleSize = psd.finishParticleSize or 1	
	psd.finishParticleSizeVariance = psd.finishParticleSizeVariance or 0

	psd.finishColorVarianceRed = psd.finishColorVarianceRed or 0
	psd.finishColorVarianceGreen = psd.finishColorVarianceGreen or 0
	psd.finishColorVarianceBlue = psd.finishColorVarianceBlue or 0
	psd.finishColorVarianceAlpha = psd.finishColorVarianceAlpha or 0
	
	psd.finishColorRed = psd.finishColorRed or 0
	psd.finishColorGreen = psd.finishColorGreen or 0
	psd.finishColorBlue = psd.finishColorBlue or 0
	psd.finishColorAlpha = psd.finishColorAlpha or 0
	
	psd.angle = psd.angle or 0
	psd.angleVariance = psd.angleVariance or 0
	psd.speed = psd.speed or 0
	psd.speedVariance = psd.speedVariance or 0

	psd.gravityx = psd.gravityx or 0
	psd.gravityy = psd.gravityy or 0
	
	psd.tangentialAcceleration = psd.tangentialAcceleration or 0	-- 切向加速度
	psd.tangentialAccelVariance = psd.tangentialAccelVariance or 0	
	psd.radialAcceleration = psd.radialAcceleration or 0			-- 径向加速度
	psd.radialAccelVariance = psd.radialAccelVariance or 0

	psd.rotationStart = psd.rotationStart or 0						-- 
	psd.rotationEnd = psd.rotationEnd or 0							-- 
	psd.rotationStartVariance = psd.rotationStartVariance or 0		-- 
	psd.rotationEndVariance = psd.rotationEndVariance or 0			-- 
	
	psd.minRadius = psd.minRadius or 0
	psd.minRadiusVariance = psd.minRadiusVariance or 0
	psd.maxRadius = psd.maxRadius or 0
	psd.maxRadiusVariance = psd.maxRadiusVariance or 0
	psd.emitterType = psd.emitterType or 0							-- 标记直线发射还是回旋发射
	psd.rotatePerSecond = psd.rotatePerSecond or 0					-- 角速度
	psd.rotatePerSecondVariance = psd.rotatePerSecondVariance or 0	-- 角速度抖动范围
	psd.omegaAcceleration = psd.omegaAcceleration or 0				-- 角加速度
	psd.omegaAccelVariance = psd.omegaAccelVariance or 0			-- 角加速度抖动范围
	
	psd.textureFileName = emit.texture
	
	createNodePool(emit, psd, parentNode)							-- 创建对象池	
	
	return psd
end


local tr = require("transition")

local function updateLineVA(sx,sy,vx,vy,gx,gy,ra,ta,dt)
	local rax,ray = 0, 0
	local tax,tay = 0, 0
	local angle = math.atan2 (sy, sx) 
	rax, ray = math.cos(angle) * ra, math.sin(angle) * ra
	tax, tay = math.cos(angle + math.pi / 2) * ta, math.sin(angle + math.pi / 2) * ta
	vx = vx + (gx + rax + tax) * dt
	vy = vy + (gy + ray + tay) * dt
	sx = sx + vx * dt
	sy = sy + vy * dt
	return sx,sy,vx,vy
end

local function updaterotateVA(theta, omega, omegaAccel, dt)
	omega = omega + omegaAccel * dt
	theta = theta + omega * dt
	return theta, omega
end



local function createParticleWithGravity(emit,id,osx,osy,spd,angle,span,ss,es,scr,scg,scb,sca,ecr,ecg,ecb,eca,ra,ta,sspin,espin)
	--参数预处理
	if es == -1 then es = ss end 
	ss = ss / emit.imgW
	es = es / emit.imgW
	sspin = math.rad(sspin)
	espin = math.rad(espin)
	span = math.abs(span)

	--方便计算所用的本地变量
	local sx,sy = 0, 0
	local vx, vy = spd * math.cos(math.rad(angle)), spd * math.sin(math.rad(angle))
	local ds,dr = es - ss, espin - sspin
	local dcr, dcg, dcb, dca = ecr - scr, ecg - scg, ecb - scb, eca - sca
	
	--确定初始状态
	emit.node[id].rotation = sspin
	emit.node[id]:show()
	emit.node[id].x, emit.node[id].y = osx, osy
	emit.node[id].scalex, emit.node[id].scaley = ss, ss
	emit.node[id]:setMaskColor(scr,scg,scb,sca)
	
	tr.start(emit.runtime, function()
		if(span > 0) then
			tr.timePeriod(span, function(t, dt)
				-- 这里要加入带有速度√、加速度√、径向加速度√、切向加速度√、颜色变化√的公式
				emit.node[id]:setMaskColor(
					scr + dcr * t / span,
					scg + dcg * t / span,
					scb + dcb * t / span)
				emit.node[id]:setAlpha(sca + dca * t / span)											--color
				emit.node[id].rotation = sspin + dr * t / span
				emit.node[id].scalex, emit.node[id].scaley = ss + ds * t / span, ss + ds * t / span 	--scale
				sx,sy,vx,vy = updateLineVA(sx,sy,vx,vy,emit.psd.gravityx,emit.psd.gravityy,ra,ta,dt)
				emit.node[id].x, emit.node[id].y = osx + sx, osy - sy
			end)
		end
		emit.node[id]:hide()
		table.insert(emit.particlesNeedActive,id)
	end)
	
end

local function createParticleWithRotation(emit,id,osx,osy,omega,omegaAccel,fai,span,ss,es,scr,scg,scb,sca,ecr,ecg,ecb,eca,sr,er,sspin,espin)
	emit.node[id]:show()
	local sx,sy = 0, 0
	if es == -1 then es = ss end
	ss = ss / emit.imgW 
	es = es / emit.imgW
	local theta = fai + 180
	local radius = sr
	sx, sy = radius * math.cos(math.rad(theta)), radius * math.sin(math.rad(theta))
	emit.node[id].x, emit.node[id].y = osx + sx, osy - sy
	emit.node[id].scalex, emit.node[id].scaley = ss, ss
	emit.node[id]:setMaskColor(scr,scg,scb)
	emit.node[id]:setAlpha(sca)
	sspin = math.rad(sspin)
	espin = math.rad(espin)
	emit.node[id].rotation = sspin
	local ds,dr = es - ss, espin - sspin
	local dcr, dcg, dcb, dca = ecr - scr, ecg - scg, ecb - scb, eca - sca
	span = math.abs(span)
	tr.start(runtime, function()
		if(span > 0) then
			tr.timePeriod(span, function(t, dt)
				-- 这里要加入带有角速度、相位、半径变化、颜色变化√的公式
				emit.node[id]:setMaskColor(
					scr + dcr * t / span,
					scg + dcg * t / span,
					scb + dcb * t / span)					--color
				emit.node[id]:setAlpha(sca + dca * t / span)		--alpha
				emit.node[id].rotation = sspin + dr * t / span
				emit.node[id].scalex, emit.node[id].scaley = ss + ds * t / span, ss + ds * t / span --scale
				radius = sr + (er - sr) * t / span
				theta, omega = updaterotateVA(theta, omega, omegaAccel, dt)
				sx, sy = radius * math.cos(math.rad(theta)), radius * math.sin(math.rad(theta))
				emit.node[id].x, emit.node[id].y = osx + sx, osy - sy
			end)
		end
		emit.node[id]:hide()
		table.insert(emit.particlesNeedActive,id)
	end)
end

--喷射器的update方法
local function update(emit,psd) 				
	local currentLoopTime = 0

	while(currentLoopTime < emit.maxParticlePerFrame and #emit.particlesNeedActive > 1 ) do
		local posx, posy = emit:localToParent(emit.x, emit.y)
		if psd.emitterType == 0 then
			createParticleWithGravity(
				emit,
				table.remove(emit.particlesNeedActive),
				calcVariance(posx, psd.sourcePositionVariancex),
				calcVariance(posy, psd.sourcePositionVariancey),
				calcVariance(psd.speed, psd.speedVariance),
				calcVariance(psd.angle, psd.angleVariance),
				calcVariance(psd.particleLifespan, psd.particleLifespanVariance),
				calcVariance(psd.startParticleSize, psd.startParticleSizeVariance),
				calcVariance(psd.finishParticleSize, psd.finishParticleSizeVariance),
				calcVariance(psd.startColorRed, psd.startColorVarianceRed),
				calcVariance(psd.startColorGreen, psd.startColorVarianceGreen),
				calcVariance(psd.startColorBlue, psd.startColorVarianceBlue),
				calcVariance(psd.startColorAlpha, psd.startColorVarianceAlpha),
				calcVariance(psd.finishColorRed, psd.finishColorVarianceRed),
				calcVariance(psd.finishColorGreen, psd.finishColorVarianceGreen),
				calcVariance(psd.finishColorBlue, psd.finishColorVarianceBlue),
				calcVariance(psd.finishColorAlpha, psd.finishColorVarianceAlpha),
				calcVariance(psd.radialAcceleration, psd.radialAccelVariance),
				calcVariance(psd.tangentialAcceleration, psd.tangentialAccelVariance),
				calcVariance(psd.rotationStart, psd.rotationStartVariance),
				calcVariance(psd.rotationEnd, psd.rotationEndVariance)
			)
		else
			createParticleWithRotation(
				emit,
				table.remove(emit.particlesNeedActive),
				posx,
				posy,																-- 目前兼容的编辑器不支持旋转时圆心的偏移
				calcVariance(psd.rotatePerSecond, psd.rotatePerSecondVariance),
				calcVariance(psd.omegaAcceleration, psd.omegaAccelVariance),		-- 目前兼容的编辑器不支持角加速度
				calcVariance(psd.angle, psd.angleVariance),							
				calcVariance(psd.particleLifespan, psd.particleLifespanVariance),	
				calcVariance(psd.startParticleSize, psd.startParticleSizeVariance),	
				calcVariance(psd.finishParticleSize, psd.finishParticleSizeVariance),	
				calcVariance(psd.startColorRed, psd.startColorVarianceRed),			
				calcVariance(psd.startColorGreen, psd.startColorVarianceGreen),		
				calcVariance(psd.startColorBlue, psd.startColorVarianceBlue),		
				calcVariance(psd.startColorAlpha, psd.startColorVarianceAlpha),		
				calcVariance(psd.finishColorRed, psd.finishColorVarianceRed),		
				calcVariance(psd.finishColorGreen, psd.finishColorVarianceGreen),	
				calcVariance(psd.finishColorBlue, psd.finishColorVarianceBlue),		
				calcVariance(psd.finishColorAlpha, psd.finishColorVarianceAlpha),	
				calcVariance(psd.maxRadius, psd.maxRadiusVariance),
				calcVariance(psd.minRadius, psd.minRadiusVariance),					-- 目前兼容的编辑器不支持旋转结束半径的抖动
				calcVariance(psd.rotationStart, psd.rotationStartVariance),			-- 单一粒子的旋转变化
				calcVariance(psd.rotationEnd, psd.rotationEndVariance)				
			)
		end
		currentLoopTime = currentLoopTime + 1
	end
end

function removeEmit(emit)
	emit.runtime.enterFrame:removeListener(emit.update)
	emit:remove()
end

local function _newParticleEmit(self, texture, data, runtime )
	if type(data) == "table" then
	else
		data = plistParser.parseUri(urilib.absolute(data, 2))
	end

	local img = self:newImage(texture)
	img:hide()
	texW = img.width
	texH = img.height

	local emit = self:newNode()
	emit.debugMode = false
	emit.texture = texture

	emit.node = {}							--构成粒子的node对象
	emit.particlesNeedActive = {}			--记录粒子是否需要被激活
	emit.imgW, emit.imgH = texW, texH		--纹理尺寸
	emit.maxParticlePerFrame = 200			--每帧最多喷射粒子数

	emit.psd = initAttr(data,emit,self)
	emit.update = function() update(emit,emit.psd) end
	
	emit.x = emit.psd.sourcePositionx
	emit.y = emit.psd.sourcePositiony
	
	emit.useGlobleGravity = false
	emit.runtime = runtime
	
	emit.setGravity = function(gx, gy)
		emit.psd.gravityx = gx
		emit.psd.gravityy = gy
	end
	
	runtime.enterFrame:addListener(emit.update)
	return emit
end

local function _newParticleEmitWithPlist(self, data, runtime)
	data = plistParser.parseUri(urilib.absolute(data, 2))
	_newParticleEmit(self, data.textureFileName .. ".png", texW, texH, data, runtime)
end

display.Stage2D.methods.newParticleEmit = _newParticleEmit
display.Stage2D.Node.methods.newParticleEmit = _newParticleEmit

display.Stage2D.methods.newParticleEmitWithPlist = _newParticleEmit
display.Stage2D.Node.methods.newParticleEmitWithPlist = _newParticleEmit