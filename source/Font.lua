local Class = require "Class"
local g = require "globals"

local Font = Class()

function Font:init(filename, size, hinting)
	self.ORIGINALFILENAME = filename
	self.ORIGINALSIZE = size
	self.ORIGINALHINTING = hinting
	self.font = love.graphics.newFont(filename, size * g.windowScaleY, hinting)
end

function Font:getFont()
	return self.font
end

function Font:resize()
	self.font = love.graphics.newFont(self.ORIGINALFILENAME, self.ORIGINALSIZE * g.windowScaleY, self.ORIGINALHINTING)
end

return Font