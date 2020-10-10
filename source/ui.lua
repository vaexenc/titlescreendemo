local Class = require "Class"
local g = require "globals"

local ui = {}

----------------------------------------------------------------------------
--- GENERAL SQUARE BUTTON CLASS
----------------------------------------------------------------------------

local ButtonBase = Class()

function ButtonBase:init()
	self.size = 24
	self.lineWidthFactor = 0.1
	self.lineWidth = self.size * self.lineWidthFactor
	self.alpha = 1
	self.alphaWeakFactor = 0.6
	self.x = 0
	self.y = 0
	self.isActive = true
	self.isVisible = true

	self.lineWidth = self.size * self.lineWidthFactor -- !
end

function ButtonBase:update()
end

function ButtonBase:draw()
end

function ButtonBase:mousepressed(_) -- mousepressed(x, y, button, istouch, presses)
	if self:isBeingHovered() then
		self:onMousepressed()
	else
		self:onMousepressedOutside()
	end
end

function ButtonBase:setActive(isActive)
	self.isActive = isActive or true
end

function ButtonBase:setVisible(isVisible)
	self.isVisible = isVisible or true
end

function ButtonBase:isBeingHovered()
	local mouseX = love.mouse.getX() / g.windowScaleX
	local mouseY = love.mouse.getY() / g.windowScaleY

	local lineWidthExtra = self.lineWidth/2
	if mouseX >= self.x - (self.size/2+lineWidthExtra) and mouseX <= self.x + (self.size/2+lineWidthExtra)
	and mouseY >= self.y - (self.size/2+lineWidthExtra) and mouseY <= self.y + (self.size/2+lineWidthExtra) then
		return true
	end

	return false
end

function ButtonBase:onMousepressed()
end

function ButtonBase:onMousepressedOutside()
end

----------------------------------------------------------------------------
--- KEYBIND BUTTON CLASS
----------------------------------------------------------------------------

local KeybindButton = ButtonBase()

function KeybindButton:init(keyString, onKeystringChange, keyName, x, y, size)
	self.keyString = keyString or "XX"
	self.keyString = string.lower(self.keyString)
	self.onKeystringChange = onKeystringChange
	self.isWaitingForKeypress = false
	self.x = x or self.x
	self.y = y or self.y
	self.size = size or self.size
	self.lineWidthFactor = 0.05
	self.cornerRoundednessFactor = 0.25
	self.fontPath = "fonts/FOT-ChiaroStd-B.otf"
	self.keyName = keyName

	self.lineWidth = self.size * self.lineWidthFactor
	self.cornerRoundness = self.size * self.cornerRoundednessFactor

	self.blinkingStartTime = nil

	self:updateFont()
end


function KeybindButton:draw()
	if self.isVisible then
		love.graphics.push("all")
			local cr, cg, cb, ca = love.graphics.getColor()
			local alpha = self:isBeingHovered() and self.alpha or self.isWaitingForKeypress and self.alpha or self.alpha * self.alphaWeakFactor
			local size = self:isBeingHovered() and self.size*1.1 or self.size

			love.graphics.setColor(cr, cg, cb, ca * alpha)
			love.graphics.setLineStyle("smooth")
			love.graphics.setLineWidth(self.lineWidth)

			love.graphics.push("all") -- because the font already scales
				love.graphics.scale(g.windowScaleX, g.windowScaleY)

				--- DRAW OUTER RECTANGLE
				love.graphics.rectangle("line", (self.x - size/2), (self.y - size/2), size, size, self.cornerRoundness, self.cornerRoundness, 20)

				--- DRAW FLASHING OVERLAY WHEN WAITING FOR KEYPRESS
				if self.isWaitingForKeypress then
					local alpha = (alpha * math.sin(((love.timer.getTime()-self.blinkingStartTime)*7)) + 1) / 2
					love.graphics.setColor(cr, cg, cb, ca * alpha)
					love.graphics.rectangle("fill", (self.x -size/2), (self.y -size/2),size,size, self.cornerRoundness, self.cornerRoundness, 20)
				end

			love.graphics.pop()

			--- DRAW KEYSTRING
			if not self.isWaitingForKeypress then
				local keyString = self.keyString
				if #self.keyString > 3 then
					--- FIRST, MIDDLE AND LAST LETTER
					local middleOfString = math.floor(#self.keyString/2)
					local endOfString = #self.keyString
					keyString = string.sub(self.keyString, 1, 1) .. string.sub(self.keyString, middleOfString, middleOfString) .. string.sub(self.keyString, endOfString, endOfString)

					--- FIRST THREE LETTERS
					keyString = string.sub(self.keyString, 1, 3)
				end
				love.graphics.printf(keyString, self.font, (self.x -size/2) * g.windowScaleX, self.y * g.windowScaleY - self.font:getHeight()/3.5,size * g.windowScaleX, "center")
			end
		love.graphics.pop()
	end
end

function KeybindButton:keypressed(key, scancode, _)
	if self.isWaitingForKeypress then
		self.keyString = key
		self.onKeystringChange(scancode, self.keyName)
		self.isWaitingForKeypress = false
	end
end

function KeybindButton:resize()
	self:updateFont()
end

function KeybindButton:onMousepressed()
	if not self.isWaitingForKeypress then
		self.blinkingStartTime = love.timer.getTime() + 0.2
	end

	self.isWaitingForKeypress = not self.isWaitingForKeypress
end

function KeybindButton:onMousepressedOutside()
	if self.isWaitingForKeypress then
		self.isWaitingForKeypress = not self.isWaitingForKeypress
	end
end

function KeybindButton:updateFont()
	self.font = love.graphics.newFont(self.fontPath, self.size * 0.5 * g.windowScaleY)
end

ui.ButtonBase = ButtonBase
ui.KeybindButton = KeybindButton

return ui