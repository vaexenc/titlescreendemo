local Class = require "Class"
local util = require "util"

local SHAKE_TRANSLATION_MAX = 50
local SHAKE_ROTATION_MAX = math.pi*0.08
local SHAKE_DECAY_SPEED = 0.015
local SMOOTH_WEIGHT = 0.125

----------------------------------------------------------------------------
--- CAMERA CLASS
----------------------------------------------------------------------------

local Camera = Class()

function Camera:init(windowBaseWidth, windowBaseHeight, windowScaleX, windowScaleY)
	self.windowBaseWidth = windowBaseWidth
	self.windowBaseHeight = windowBaseHeight
	self.windowScaleX = windowScaleX
	self.windowScaleY = windowScaleY

	self.x = 0
	self.y = 0
	self.scaleX = 1
	self.scaleY = 1
	self.rotation = 0
	self.shakeLevel = 0
	self.shakeOffsetX = 0
	self.shakeOffsetY = 0
	self.shakeOffsetRotation = 0

	self.shakeDecaySpeed = SHAKE_DECAY_SPEED
	self.shakeTranslationXMax = SHAKE_TRANSLATION_MAX
	self.shakeTranslationYMax = SHAKE_TRANSLATION_MAX
	self.shakeRotationMax = SHAKE_ROTATION_MAX
	self.smoothWeight = SMOOTH_WEIGHT

	self.isSmoothLockOnEnabled = false
	self.isStretchingEnabled = true

	self.width = nil
	self.height = nil
	self.lockOnTargetReferenceTable = nil
	self.limitTop = nil
	self.limitBottom = nil
	self.limitLeft = nil
	self.limitRight = nil

	----------------------------------------------------------------------------

	self:setAppropriateWidthAndHeightBasedOnStretchEnabled()
end

----------------------------------------------------------------------------

function Camera:updateShakeLevel()
	self.shakeLevel = math.max(self.shakeLevel - self.shakeDecaySpeed, 0)
end

function Camera:updateShakeOffsets()
	local shakeMult = self.shakeLevel * self.shakeLevel
	self.shakeOffsetX = util.getRandomNegOneToOne() * self.shakeTranslationXMax * shakeMult
	self.shakeOffsetY = util.getRandomNegOneToOne() * self.shakeTranslationYMax * shakeMult
	self.shakeOffsetRotation = util.getRandomNegOneToOne() * self.shakeRotationMax * shakeMult
end

function Camera:updateLockOn()
	if self.lockOnTargetReferenceTable then
		local goalX, goalY
		local targetX = self.lockOnTargetReferenceTable.x
		local targetY = self.lockOnTargetReferenceTable.y
		if self.isSmoothLockOnEnabled then
			local centerX, centerY = self:getCenterPos()
			goalX = centerX + (targetX-centerX)*self.smoothWeight
			goalY = centerY + (targetY-centerY)*self.smoothWeight
		else
			goalX, goalY = targetX, targetY
		end
		self:setCenterPos(goalX, goalY)
	end
end

function Camera:setAppropriateWidthAndHeightBasedOnStretchEnabled()
	self.width = self.isStretchingEnabled and self.windowBaseWidth or love.graphics.getWidth()
	self.height = self.isStretchingEnabled and self.windowBaseHeight or love.graphics.getHeight()
end

function Camera:limitScale()
	if self.scaleX < 0 then
		self.scaleX = 0
	end
	if self.scaleY < 0 then
		self.scaleY = 0
	end
end

----------------------------------------------------------------------------

function Camera:update()
	self:limitScale()
	self:setAppropriateWidthAndHeightBasedOnStretchEnabled()
	self:updateLockOn()
	self:updateShakeLevel()
	self:updateShakeOffsets()
	self:enforceLimits()
end

function Camera:drawSet()
	--- NEW GRAPHICS TRANSFORMATION, RESET IT
	love.graphics.push()
	love.graphics.origin()

	--- SET ZOOM / STRETCHING
	local stretchScaleX = self.isStretchingEnabled and self.windowScaleX or 1
	local stretchScaleY = self.isStretchingEnabled and self.windowScaleY or 1
	love.graphics.scale(
		self.scaleX * stretchScaleX,
		self.scaleY * stretchScaleY
	)

	--- MOVE CAMERA
	love.graphics.translate(
		-self.x - (self.width-self.width/self.scaleX)/2 - self.shakeOffsetX,
		-self.y - (self.height-self.height/self.scaleY)/2 - self.shakeOffsetY
	)

	--- ROTATE CAMERA
	local rotateOffsetX, rotateOffsetY = self:getCenterPos()
	love.graphics.translate(rotateOffsetX, rotateOffsetY)
	love.graphics.rotate(-self.rotation + self.shakeOffsetRotation)
	love.graphics.translate(-rotateOffsetX, -rotateOffsetY)
end

function Camera:drawUnset()
	love.graphics.pop()
end

function Camera:setZoom(zoom)
	self.scaleX = zoom
	self.scaleX = zoom
end

function Camera:getZoom()
	if self.scaleX == self.scaleY then
		return self.scaleX
	end
end

function Camera:getCenterPos()
	return self.x + self.width/2, self.y + self.height/2
end

function Camera:setPos(x, y)
	self.x = x or self.x
	self.y = y or self.y
end

function Camera:setCenterPos(x, y)
	self.x = x and (x - self.width/2) or self.x
	self.y = y and (y - self.height/2) or self.y
end

function Camera:setZoom(zoom)
	self.scaleX = zoom or self.scaleX
	self.scaleY = zoom or self.scaleY
end

function Camera:shake(amount)
	self.shakeLevel = math.min(self.shakeLevel+amount, 1)
end

function Camera:setNewLimits(top, bottom, left, right) -- overwrite even if nil
	self.limitTop = top
	self.limitBottom = bottom
	self.limitLeft = left
	self.limitRight = right
end

function Camera:setLimits(top, bottom, left, right) -- only if not nil
	self.limitTop = top or self.limitTop
	self.limitBottom = bottom or self.limitBottom
	self.limitLeft = left or self.limitLeft
	self.limitRight = right or self.limitRight
end

function Camera:getTop()
	-- if self.scaleY >= 1 then return self.y + (height-height/self.scaleY)/2 end
	return self.y - (self.height/self.scaleY-self.height)/2
end

function Camera:getLeft()
	return self.x - (self.width/self.scaleX-self.width)/2
end

function Camera:getBottom()
	return self.y+self.height + (self.height/self.scaleY-self.height)/2
end

function Camera:getRight()
	return self.x+self.width + (self.width/self.scaleX-self.width)/2
end

function Camera:setTop(y)
	self.y = y + self.y-self:getTop()
end

function Camera:setLeft(x)
	self.x = x + self.x-self:getLeft()
end

function Camera:setBottom(y)
	self.y = y - self.height - (self.y-self:getTop())
end

function Camera:setRight(x)
	self.x = x - self.width - (self.x-self:getLeft())
end

function Camera:enforceLimits()
	if self.limitTop and self.limitBottom and self:getBottom() - self:getTop() > self.limitBottom - self.limitTop then
		-- keep	camera vertically centered if out of bounds at top and bottom
		self:setCenterPos(nil, self.limitTop+((self.limitBottom-self.limitTop)/2))
	else
		-- push camera back in if out of bounds at top or bottom
		if self.limitTop and self:getTop() < self.limitTop then
			self:setTop(self.limitTop)
		elseif self.limitBottom and self:getBottom() > self.limitBottom then
			self:setBottom(self.limitBottom)
		end
	end

	if self.limitLeft and self.limitRight and self:getRight() - self:getLeft() > self.limitRight - self.limitLeft then
		-- keep	camera horizontally centered if out of bounds at left and right
		self:setCenterPos(self.limitLeft+((self.limitRight-self.limitLeft)/2), nil)
	else
		-- push camera back in if out of bounds at left or right
		if self.limitLeft and self:getLeft() < self.limitLeft then
			self:setLeft(self.limitLeft)
		elseif self.limitRight and self:getRight() > self.limitRight then
			self:setRight(self.limitRight)
		end
	end
end

function Camera:resize(windowBaseWidth, windowBaseHeight, windowScaleX, windowScaleY)
	self.windowBaseWidth = windowBaseWidth
	self.windowBaseHeight = windowBaseHeight
	self.windowScaleX = windowScaleX
	self.windowScaleY = windowScaleY
end

return Camera