--[[
Seed 插件
	particle
	包含文件
		particle.lua - 提供创建粒子的方法
	依赖组件
		transition
		plist
		lua_ex
	最后修改日期
		2012-8-3
	更新记录
		2012-8-3：重构、提升效率、增加调节粒子浓度的方法
		2012-6-15：增加了self:pause(),self:resume(),self:stop(),self:start()方法，扩大粒子池size
]]--
math.randomseed(os.time())	
local urilib = require("uri")
local r2d = require("render2d")
local plistParser = require("plist")
require("lua_ex")

local function numToBlendState(num)
	if num == 0 then return "zero"
	elseif num == 1 then return "one"
	elseif num == 770 then return "srcAlpha"
	elseif num == 772 then return "dstAlpha"
	elseif num == 771 then return "invSrcAlpha"
	elseif num == 773 then return "invDstAlpha"
	elseif num == 768 then return "srcColor"
	elseif num == 774 then return "dstColor"
	elseif num == 769 then return "invSrcColor"
	elseif num == 775 then return "invDestColor"
	else
		print("blend func id:", num, " not supported yet, setted it to GL_ONE")
		return "one"
	end
end

--根据平均值和抖动范围计算最终值，可以加到数学库里
local function calcVariance(value, variance)
	return value + (math.random() - 0.5) * variance * 2
end

--初始化粒子系统所有属性，参数有效性检查都在这里进行
local function initAttr(data, emit, parentNode)
	
	local psd = data
	
	--有效性检查，如数据为nil则赋初值
	psd.maxParticles = psd.maxParticles or 120

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
	
	psd.tangentialAcceleration = tonumber(psd.tangentialAcceleration or 0)	-- 切向加速度
	psd.tangentialAccelVariance = tonumber(psd.tangentialAccelVariance or 0)	
	psd.radialAcceleration = tonumber(psd.radialAcceleration or 0)			-- 径向加速度
	psd.radialAccelVariance = tonumber(psd.radialAccelVariance or 0)

	psd.rotationStart = psd.rotationStart or 0						-- 
	psd.rotationEnd = psd.rotationEnd or 0							-- 
	psd.rotationStartVariance = psd.rotationStartVariance or 0		-- 
	psd.rotationEndVariance = psd.rotationEndVariance or 0			-- 
	
	psd.minRadius = psd.minRadius or 0
	psd.minRadiusVariance = psd.minRadiusVariance or 0
	psd.maxRadius = psd.maxRadius or 0
	psd.maxRadiusVariance = psd.maxRadiusVariance or 0
	
	psd.rotatePerSecond = psd.rotatePerSecond or 0					-- 角速度
	psd.rotatePerSecondVariance = psd.rotatePerSecondVariance or 0	-- 角速度抖动范围
	psd.omegaAcceleration = psd.omegaAcceleration or 0				-- 角加速度
	psd.omegaAccelVariance = psd.omegaAccelVariance or 0			-- 角加速度抖动范围
	psd.duration = psd.duration or -1

	psd.emitterType = psd.emitterType or 0							-- 标记直线发射还是回旋发射
	if psd.emitterType == 0 and psd.tangentialAcceleration == 0 and psd.tangentialAccelVariance == 0 and psd.radialAcceleration == 0 and psd.radialAccelVariance == 0 then
		psd.emitterType = 2
		print("useFast")
	elseif psd.emitterType == 1 then
		psd.sourcePositionVariancex, psd.sourcePositionVariancey = 0, 0
		print("useCircle")
	end
	
	local sr = psd.startColorRed
	local sg = psd.startColorGreen
	local sb = psd.startColorBlue
	local sa = psd.startColorAlpha

	local srv = psd.startColorVarianceRed
	local sgv = psd.startColorVarianceGreen
	local sbv = psd.startColorVarianceBlue 
	local sav = psd.startColorVarianceAlpha
	
	local fr = psd.finishColorRed
	local fg = psd.finishColorGreen
	local fb = psd.finishColorBlue 
	local fa = psd.finishColorAlpha

	local frv = psd.finishColorVarianceRed
	local fgv = psd.finishColorVarianceGreen
	local fbv = psd.finishColorVarianceBlue 
	local fav = psd.finishColorVarianceAlpha

	local function getSColor()
		return calcVariance(sr, srv),
		calcVariance(sg, sgv),
		calcVariance(sb, sbv),
		calcVariance(sa, sav)
	end

	local function getFColor()
		return calcVariance(fr, frv),
		calcVariance(fg, fgv),
		calcVariance(fb, fbv),
		calcVariance(fa, fav)
	end
	
	return psd, getSColor, getFColor
end

--所有粒子从属于self对象，发射器从属于self对象，发射器的移动对于已知的粒子不影响
local function _newParticleEmit(self, data, runtimeAgent, texture, preHeat)
	preHeat = preHeat or 0
	
	local ra = runtimeAgent:newAgent()
	local timeLine
	local startTime
	local emit = self:newNode()
	local stage = emit.stage
	local psd, getSColor, getFColor = initAttr(data)
	
	--local psd = createPsdData()
	if preHeat > psd.particleLifespan then
		preHeat = psd.particleLifespan - 0.05
	end
	
	local particleTable = {}
	local minLife = math.max(0, psd.particleLifespan - psd.particleLifespanVariance)
	local maxLife = psd.particleLifespan + psd.particleLifespanVariance
	emit.maxLife = maxLife
	local avgLifespan = (minLife + maxLife)/2
	local emitRate = psd.maxParticles / avgLifespan
	local keyInx = 0		--每一个粒子的唯一key

	local eff = display.BlendStateEffect.new()
	eff.srcFactor = numToBlendState(data.blendFuncSource)
	eff.destFactor = numToBlendState(data.blendFuncDestination)
	emit.blendState = eff
	
	emit.particleTable = particleTable
	emit.ra = ra

	--粒子的逻辑过程分为发射、运动和销毁
	--发射时，粒子的发射方向、发射位置等等都是以emit为参照

	--粒子的大小，在数据中的表现形式是像素
	local pps
	local ppsWidth

	if os.exists(texture) then
		pps = display.presentations.newImage(texture)	-- particle presentation
		ppsWidth = nil
	else
		pps = function()
			render2d.fillRect(-20, -20, 20, 20)			--如果图片不存在，粒子的表现形式就是一个40x40像素的矩形
		end
		ppsWidth = 40
	end

	local function createParticle(st)
		keyInx = keyInx + 1
		local particle = stage:newNode()
		particle:addEffect(eff)			--大约会掉3帧
		
		particle.presentation = pps

		if not ppsWidth then
			ppsWidth = particle.width
		end
		
		local osx, osy = emit.x + calcVariance(psd.sourcePositionx, psd.sourcePositionVariancex), emit.y + calcVariance(psd.sourcePositiony, psd.sourcePositionVariancey)
		particle.x, particle.y = osx, osy
		local key = keyInx

		--根据发射角和射速求初速度矢量
		local angle = math.rad(calcVariance(psd.angle, psd.angleVariance)) + emit.rotation
		local speed = calcVariance(psd.speed, psd.speedVariance)
		local vx, vy = speed * math.cos(angle), speed * math.sin(angle)
		local lifeSpan = calcVariance(psd.particleLifespan, psd.particleLifespanVariance)

		local sSize = calcVariance(psd.startParticleSize, psd.startParticleSizeVariance) / ppsWidth
		local fSize = calcVariance(psd.finishParticleSize, psd.finishParticleSizeVariance) / ppsWidth

		local sr, sg, sb, sa = getSColor()
		local fr, fg, fb, fa = getFColor()
		local life				--粒子生存时间线，0~1
		local gx, gy = psd.gravityx, psd.gravityy
		local ra = calcVariance(psd.radialAcceleration, psd.radialAccelVariance)
		local ta = calcVariance(psd.tangentialAcceleration, psd.tangentialAccelVariance)

		local sRot = calcVariance(psd.rotationStart, psd.rotationStartVariance)
		local eRot = calcVariance(psd.rotationEnd, psd.rotationEndVariance)

		local lastt = st
		local sx, sy = 0, 0
		local function _update(t, dt)
			t = t - st
			dt = t - lastt
			if t >= lifeSpan then
				particleTable[key] = nil
				particle:remove()
				return
			end
			life = t/lifeSpan
			
			--自旋
			particle.rotation = sRot + (eRot - sRot) * life

			--大小变化
			particle.scalex = sSize + (fSize - sSize) * life
			particle.scaley = particle.scalex
			
			--颜色变化
			local alpha = sa + (fa - sa) * life
			particle:setMaskColor((sr + (fr - sr) * life)/alpha, (sg + (fg - sg) * life)/alpha, (sb + (fb - sb) * life)/alpha, alpha)		--大约掉10帧
			
			--TODO：求解偏微分方程，求s = f(t)
			--已知粒子的发射角angle、射速标量speed、重力加速度gx，gy、沿着发射器位置和粒子当前所在位置的加速度标量ra、与ra垂直的加速度的标量ta，求粒子位置与运动时间的关系
			--径向与切向加速度暂时无法导出其与时间线的关系
			local i = 0

			local times = math.min(math.floor(dt * 30) + 1, 30)
			local ddt = dt / times

			for i = 1, times do					-- 模拟粒子运动的迭代方法
				angle = math.atan2(sy, sx)		-- 从发射器位置到粒子当前位置的方位角

				rax, ray = math.cos(angle) * ra, math.sin(angle) * ra		--沿着粒子发射出去的方向（从发射器位置到粒子当前位置的方向）的加速度
				tax, tay = math.cos(angle + math.pi / 2) * ta, math.sin(angle + math.pi / 2) * ta	--垂直于粒子所在位置方向的加速度

				vx, vy = vx + (rax + tax + gx) * ddt, vy + (ray + tay + gy) * ddt
				sx, sy = sx + vx * ddt, sy + vy * ddt
				i = i + 1
			end
			particle.x, particle.y = osx + sx, osy - sy
			lastt = t
		end

		local function _updateFast(t, dt)
			t = t - st
			if t >= lifeSpan then
				particleTable[key] = nil
				particle:remove()
				return
			end
			life = t/lifeSpan

			--运动，无径向与切向加速度时，可以使用快速算法
			particle.x, particle.y = osx + vx * t + gx * t * t / 2, osy - (vy * t + gy * t * t / 2)

			--自旋
			particle.rotation = sRot + (eRot - sRot) * life

			--大小变化
			particle.scalex = sSize + (fSize - sSize) * life
			particle.scaley = particle.scalex
			
			--颜色变化
			local alpha = sa + (fa - sa) * life
			particle:setMaskColor((sr + (fr - sr) * life)/alpha, (sg + (fg - sg) * life)/alpha, (sb + (fb - sb) * life)/alpha, alpha)		--大约掉10帧
		end
		
		local r, theta
		local omega = math.rad(calcVariance(psd.rotatePerSecond, psd.rotatePerSecondVariance))
		local sR= calcVariance(psd.maxRadius, psd.maxRadiusVariance)
		local eR= calcVariance(psd.minRadius, psd.minRadiusVariance)

		local function _updateR(t, dt)
			t = t - st
			if t >= lifeSpan then
				particleTable[key] = nil
				particle:remove()
				return
			end
			life = t/lifeSpan
		
			--圆周运动			
			theta = angle + math.pi + omega * t
			r = sR + (eR - sR) * life
			particle.x, particle.y = osx + math.cos(theta)*r, osy - (math.sin(theta) * r)

			--自旋
			particle.rotation = sRot + (eRot - sRot) * life

			--大小变化
			particle.scalex = sSize + (fSize - sSize) * life
			particle.scaley = particle.scalex
			
			--颜色变化
			local alpha = sa + (fa - sa) * life
			particle:setMaskColor((sr + (fr - sr) * life)/alpha, (sg + (fg - sg) * life)/alpha, (sb + (fb - sb) * life)/alpha, alpha)		--大约掉10帧
		end
		if psd.emitterType == 0 then
			particle.update = _update
		elseif psd.emitterType == 1 then
			particle.update = _updateR
		else
			particle.update = _updateFast
		end
		return particle, key
	end

	local function preHeatFunc(particle, t)
		for i = 1, t * 20 do
			particle.update(0, 1 / 20)
		end
	end

	local function createParticles(t, dt)
		local i = 0
		if emitRate == 0 then
			return 
		end
		while i / emitRate < dt do
			local p, key = createParticle(t - (dt - i / emitRate))
			particleTable[key] = p
			i = i + 1
		end
	end

	local emitFunc = createParticles

	local function _particleSystemUpdate(t, dt)
		if not startTime then
			startTime = t - preHeat
			dt = preHeat
		end
		timeLine = t - startTime
		if psd.duration ~= -1 and timeLine >= psd.duration then		--这也意味着包含duration选项的粒子的预热时间不能超过总发射时间，否则粒子不会出现
			 emitFunc = function() end
		end
		emitFunc(timeLine, dt)
		for k, v in pairs(particleTable) do
			if v then
				v.update(timeLine, dt)
			end
		end
	end

	ra.enterFrame:addListener(_particleSystemUpdate)

	emit.setGravity = function (self, gx, gy)
		psd.gravityx, psd.gravityy = gx, gy
	end

	emit.pause = function(self)
		ra:pause()
	end

	emit.resume = function(self)
		ra:resume()
	end

	emit.stop = function(self)
		emitFunc = function() end
	end
	
	emit.start = function(self)
		emitFunc = createParticles
	end
	
	emit.setDensity = function(self, density)	--浓度
		local maxParticles = psd.maxParticles * density
		if maxParticles >= 10 and maxParticles <= 5000 then
			emitRate = maxParticles / avgLifespan
			return true
		end
		return false
	end

	emit.preHeat = function(self, t)
		preHeat = t
		if psd.emittype == 0 then
			createParticles(t, t)
		end
	end

	emit.setParticlePosition = function(self, x, y)
		psd.sourcePositionx, psd.sourcePositiony = x, y
	end

	emit.x, emit.y = psd.sourcePositionx, psd.sourcePositiony
	emit:setParticlePosition(0, 0)
	return emit
end

function removeEmit(emit)
	emit:stop()
	emit.ra:setTimeout(function()
		emit.ra:remove()
		emit:remove()
	end, emit.maxLife)
end

local function _newParticleEmitWithPlist(self, data, ra, textureFileName, preHeat)
	local data = plistParser.parseUri(urilib.absolute(data, 2))
	local textureFileName = textureFileName or data.textureFileName
	textureFileName = urilib.absolute(textureFileName, 2)
	return _newParticleEmit(self, data, ra, textureFileName, preHeat)
end

--[[
方法：
	
	Stage2D:newParticleEmit(data, runtimeAgent, texture[, preHeat])
	Stage2D:newParticleEmitWithPlist(plist, runtimeAgent, texture[, preHeat])

	Stage2D.node:newParticleEmit(data, runtimeAgent, texture[, preHeat])           
	Stage2D.node:newParticleEmitWithPlist(plist, runtimeAgent, texture[, preHeat])         

	说明：

		创建粒子发射器

	参数：

		plist - plist格式的粒子描述文件
		data - 描述粒子各种属性的table
		runtimeAgent - runtime计时器
		texture - 粒子的纹理资源图
		preHeat - 粒子生成时预热的时间

	返回值：
		
		Stage.Node对象

	除Stage2D.Node默认提供的方法外，此node还包含如下方法：

		self:setParticlePosition(x, y)		--设置粒子发射起点与emit的相对位置
		self:setGravity(gx, gy)				--设置粒子系统的环境重力
		self:pause()						--暂停，已发射的粒子暂停运动，发射器暂停发射粒子
		self:resume()						--恢复，粒子重新开始运动，发射器重新发射粒子
		self:stop()							--停止，发射器停止发射粒子，已发射的粒子保持当前运动状态，知道释放
		self:start()						--开始，发射器重新发射粒子
		self:setDensity(density)			--设置粒子发射浓度，参数：density为浓度倍数，默认为1；返回值：设置成功返回true，不成功返回false
		self:preHeat(time)					--粒子预热，参数：time为预热时间

	使用例子：

		local rta = runtime:newAgent()
		local emit = node:newParticleEmitWithPlist("particle.plist", rta, "particle_star.png")
		emit:preHeat(4)					--预热四秒
		emit:setParticlePosition(0, 0)	--粒子发射点距离emit的相对位置设定为(0, 0)
		input.mouse:addListener(function(ev)
			emit.x, emit.y = ev.x, ev.y			--跟随鼠标移动的粒子发射器
		end)

	可以使用removeEmit(emit)移除一个粒子发射器

]]

display.Stage2D.methods.newParticleEmit = _newParticleEmit
display.Stage2D.Node.methods.newParticleEmit = _newParticleEmit

display.Stage2D.methods.newParticleEmitWithPlist = _newParticleEmitWithPlist
display.Stage2D.Node.methods.newParticleEmitWithPlist = _newParticleEmitWithPlist