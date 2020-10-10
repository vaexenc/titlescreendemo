----------------------------------------------------------------------------
--- GENERAL
----------------------------------------------------------------------------

math.randomseed(os.time())

----------------------------------------------------------------------------
--- REQUIRE
----------------------------------------------------------------------------

local g = require "globals"
local scene = require "scene"
local settings = require "settings"

----------------------------------------------------------------------------
--- SCENES
----------------------------------------------------------------------------

scene.addScene("sceneLogo", require "scenelogo")

----------------------------------------------------------------------------
--- GENERAL FUNCTIONS
----------------------------------------------------------------------------

local function setWindowTitle()
	love.window.setTitle( love.graphics.getWidth() .. "x" .. love.graphics.getHeight())
end

local function setWindowScale()
	g.windowScaleX = love.graphics.getWidth() / g.windowBaseWidth
	g.windowScaleY = love.graphics.getHeight() / g.windowBaseHeight
end

local function readWindowPositionFromFileAndSet(shouldJustDisplayBeLoaded)
	shouldJustDisplayBeLoaded = shouldJustDisplayBeLoaded or false
	local data = love.filesystem.read("windowpos.txt")
	if not data then
		return
	end
	local x, y, display = string.match(data, "^(%d+),(%d+),(%d+)")
	if display then
		if shouldJustDisplayBeLoaded then
			x, y = love.window.getPosition()
		end
		if x and y then
			love.window.setPosition(x, y, display)
		end
	end
end

----------------------------------------------------------------------------
--- LOVE FUNCTIONS
----------------------------------------------------------------------------

function love.load()
	readWindowPositionFromFileAndSet(true)
	setWindowTitle()
	scene.setScene("sceneLogo")
end

function love.keypressed(key, scancode, isrepeat)
	if key == "escape" then
		love.audio.stop()
		love.timer.sleep(0.01)
		love.event.quit()
	end

	scene.executeCurrentSceneFunction("keypressed", key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
	scene.executeCurrentSceneFunction("keyreleased", key, scancode)

end

function love.mousepressed(x, y, button, istouch, presses)
	scene.executeCurrentSceneFunction("mousepressed", x, y, button, istouch, presses)

end

function love.mousereleased(x, y, button, istouch, presses)
	scene.executeCurrentSceneFunction("mousereleased", x, y, button, istouch, presses)

end

local accumulator = 0
local fpsTarget = 60
local dtTarget = 1/fpsTarget
local currentWindowWidth
local currentWindowHeight

function love.update(dt)
	----------------------------------------------------------------------------
	--- LIMIT dt
	----------------------------------------------------------------------------
	dt = math.min(dt, dtTarget)

	----------------------------------------------------------------------------
	--- SET WINDOW SCALE VARIABLES
	----------------------------------------------------------------------------
	setWindowScale()

	----------------------------------------------------------------------------
	--- FRAMERATE INDEPENDENT UPDATE LOOP
	----------------------------------------------------------------------------
	scene.executeCurrentSceneFunction("updateUnrestricted", dt)

	----------------------------------------------------------------------------
	--- MAIN LOOP, FRAME ADVANCE
	----------------------------------------------------------------------------
	accumulator = accumulator + dt

	if accumulator >= dtTarget then
		scene.executeCurrentSceneFunction("update", accumulator)
		accumulator = accumulator - dtTarget
		collectgarbage("collect")
	end

	currentWindowWidth = love.graphics.getWidth()
	currentWindowHeight = love.graphics.getHeight()
end

function love.draw()
	scene.executeCurrentSceneFunction("draw")
end

local previousVolume

function love.focus(focused)
	--- SOUND IN BACKGROUND
	if settings.muteSoundInBackground then
		if not focused then
			previousVolume = love.audio.getVolume()
			love.audio.setVolume(0)
		elseif previousVolume then
			love.audio.setVolume(previousVolume)
		end
	end

	--- SCENE FUNCTION
	scene.executeCurrentSceneFunction("focus", focused)
end

local maxWindowWidth
local maxWindowHeight

function love.resize()
	local screenBaseAspectRatio = (g.windowBaseWidth/g.windowBaseHeight)
	local resizedWidth, resizedHeight, flags = love.window.getMode()
	local widthDifference = math.abs(currentWindowWidth - resizedWidth)
	local heightDifference = math.abs(currentWindowHeight - resizedHeight)
	local newWidth, newHeight

	if widthDifference > heightDifference then
		newWidth, newHeight = resizedWidth, resizedWidth / screenBaseAspectRatio
	else
		newWidth, newHeight = resizedHeight * screenBaseAspectRatio, resizedHeight
	end

	love.window.setMode(0, 0, flags)
	maxWindowWidth, maxWindowHeight = love.window.getMode()

	if newWidth > maxWindowWidth then
		newWidth = maxWindowWidth
		newHeight = newWidth / screenBaseAspectRatio
	end

	if newHeight > maxWindowHeight then
		newHeight = maxWindowHeight
		newWidth = newHeight * screenBaseAspectRatio
	end

	love.window.setMode(newWidth, newHeight, flags)

	setWindowTitle()
	setWindowScale()

	---
	scene.executeCurrentSceneFunction("resize")
end

function love.quit()
	--- write window position to file
	local x, y, display = love.window.getPosition()
	love.filesystem.write("windowpos.txt", string.format("%i,%i,%i", x, y, display))
end