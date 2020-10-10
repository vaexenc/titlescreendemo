local Camera = require "Camera"
local Class = require "Class"
local Font = require "Font"
local easing = require "easing"
local g = require "globals"
local scene = require "scene"
local settings = require "settings"
local shaders = require "shaders"
local timerLib = require "timer"
local util = require "util"
local ui = require "ui"

local sceneLogo = {}
local camera = Camera()
local timer = timerLib.TimerContainer()

----------------------------------------------------------------------------
--- VARS
----------------------------------------------------------------------------

local BGCOLOR = {1 - 10/255, 1 - 10/255, 1 - 20/255}
local VIGNETTE = love.graphics.newImage("images/vignette_new.png")
local VIGNETTEALPHA = 0.3
local FADEDURATION = 1
local SOUNDBGVOLUME = 0.9
local CLASHDURATION = 0.6
local SWORDIMAGE = love.graphics.newImage("images/menusword.png")
local SWORDROTATIONTOTAL = -(math.pi*2) * 3.9
local SWORDDISTANCESTART = 550
local SWORDDISTANCEGOAL = 20
local SWORDANGLESTART = 90
local SWORDANGLEGOAL = -70
local SWORDSCALEX = 0.61
local SWORDSCALEY = 0.5
local SWORDTRAILALPHASTART = 0.4
local SWORDTRAILFADEAMOUNT = 0.08
local SHIELDIMAGE = love.graphics.newImage("images/menushield.png")
local SHIELDALPHASTART = 0
local SHIELDALPHAGOAL = 1
local SHIELDSCALESTART = 1.1
local SHIELDSCALEGOAL = 0.35
local SHIELDROTATIONSTART = math.rad(-55)
local SHIELDSTARTMULT = 0.325
local SHIELDENDMULT = 0.85
local SWORDFOLLOWTHROUGHDURATION = 0.075
local SWORDFOLLOWTHROUGHDISTANCE = 160
local ZOOMDURATION = 1.35
local ZOOMAMOUNT = 4
local CAMERASHAKEROTATIONNMAX = 0
local CAMERASHAKETRANSLATEXMAX = 0
local CAMERASHAKETRANSLATEYMAX = 140
local CAMERASHAKESTRENGTH = 1
local CAMERASHAKEDURATION = 0.31
local LETTERS = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}
local GAMETITLES = {
	"Eldaz", "Zacc", "Zain", "Zalgo", "Zambo", "Zamo", "Zamo", "Zane", "Zappa", "Zarf", "Zart",
	"Zato", "Zebu", "Zeet", "Zeez", "Zeggu", "Zeke", "Zen", "Zeno", "Zeph", "Zeppo", "Zett", "Ziggy",
	"Zigma", "Zigor", "Zima", "Zimba", "Zimmy", "Zippa", "Zippy", "Zodd", "Zoggi", "Zoki", "Zoko",
	"Zoldo", "Zombo", "Zondo", "Zoomo", "Zoop", "Zor", "Zorf", "Zorla", "Zort", "Zota",
	"Zuka", "Zulu", "Zunox", "Zuppo", "Zurrg"
}
local TITLEFONTSIZE = 160
local TITLEBASEFONT = love.graphics.newFont("fonts/Triforce.ttf", TITLEFONTSIZE)
local FIRSTTITLELETTERDURATION = 0.5
local FIRSTTITLELETTERSCALESTARTX = 20
local FIRSTTITLELETTERSCALESTARTY = 100
local SLIDEDELAY = 0.53
local SLIDEDURATION = 1.5
local GENERICTITLELETTERSLIDEDURATION = SLIDEDURATION*1.1
local GENERICTITLELETTERCHANGEINTERVAL = 0.1
local GENERICTITLELETTERSPAWNINTERVAL = 0.25
local TITLELETTERSPACING = -3
local SUBTITLETOPSTRING = "The Legend Of"
local SUBTITLEBOTTOMSTRING = "Bottom  Text"
local SUBTITLEFADEDURATION = 2
local SUBTITLEFADEDELAY = 1.2
local FONTSUBTITLEPATH = "fonts/CharlemagneBold.otf"
local SUBTITLETOPDISTANCEX = 101
local SUBTITLETOPDISTANCEY = -51
local SUBTITLEBOTTOMDISTANCEX = 70
local SUBTITLEBOTTOMDISTANCEY = 49
local SUBTITLEFONTSIZEFACTOR = 0.05
local SUBTITLEFONTSIZEMAX = 20
local STARTKEYBINDFADEDURATION = 1.5
local PRESSSTARTFONT = Font("fonts/FOT-ChiaroStd-B.otf", 27)
local LABELFONT = Font("fonts/FOT-ChiaroStd-B.otf", 16)
local ENDZOOMDURATION = 3.15
local ENDSWORDWHIRLYDURATION = 0.5
local ENDZOOMDELAY = 0.5
local ENDZOOMBIAS = 0.0019

local phase
local phaseFunctions
local sword
local shield
local backgroundRectangleAlpha
local swordDistance
local swordAngle
local swordShieldX
local swordShieldXOri
local swordShieldY
local titleLetters
local titleRenderFont
local titleLettersCoordinates
local titleLettersTotalWidth
local subtitleTop
local subtitleBottom
local subtitleFont
local subtitleFontSize
local shaderStencil
local keybindButtons

local generalDraw

local timers = {}
local fadeDuration = FADEDURATION

local soundClash = love.audio.newSource("sounds/clash.mp3", "stream")
local soundBG = love.audio.newSource("sounds/vokraz.mp3", "stream")
local soundEndZoom = love.audio.newSource("sounds/endzoom.mp3", "stream")
local soundEndSword = love.audio.newSource("sounds/endsword.mp3", "stream")
soundClash:setVolume(0.6)
soundBG:setVolume(SOUNDBGVOLUME)
soundEndZoom:setVolume(1)
soundEndSword:setVolume(0.6)

----------------------------------------------------------------------------
--- SWORD CLASS
----------------------------------------------------------------------------

local Sword = Class()

function Sword:init()
	self.image = SWORDIMAGE
	self.x = 0
	self.y = 0
	self.rotation = 0
	self.scaleX = SWORDSCALEX
	self.scaleY = SWORDSCALEY
	self.offsetX = self.image:getWidth()/2
	self.offsetY = self.image:getHeight()/2
	self.alpha = 1
	self.trail = {}
	self.trailEnabled = true
end

function Sword:update()
	--- UPDATE TRAIL
	if self.trailEnabled then
		--- ITERATE THROUGH FADE OBJECTS, FADE OUT OR REMOVE OBJECT
		for i, v in pairs(self.trail) do
			v.alpha = v.alpha - SWORDTRAILFADEAMOUNT
			if v.alpha <= 0 then
				table.remove(self.trail, i)
			end
		end

		--- ADD TRAIL OBJECT
		table.insert(self.trail, {})
		local trailObject = self.trail[#self.trail]
		trailObject.x = self.x
		trailObject.y = self.y
		trailObject.rotation = self.rotation
		trailObject.scaleX = self.scaleX
		trailObject.scaleY = self.scaleY
		trailObject.offsetX = self.offsetX
		trailObject.offsetY = self.offsetY
		trailObject.alpha = self.alpha * SWORDTRAILALPHASTART
	end
end

function Sword:draw()
	local cr, cg, cb, ca = love.graphics.getColor()

	--- DRAW TRAIL
	if self.trailEnabled then
		for _, v in ipairs(self.trail) do
			love.graphics.setColor(cr, cg, cb, v.alpha)
			generalDraw(self.image, v.x, v.y, v.rotation, v.scaleX, v.scaleY, v.offsetX, v.offsetY)
		end
	end

	--- DRAW SELF
	love.graphics.setColor(cr, cg, cb, self.alpha)
	generalDraw(self.image, self.x, self.y, self.rotation, self.scaleX, self.scaleY, self.offsetX, self.offsetY)

	--- RESTORE COLOR
	love.graphics.setColor(cr, cg, cb, ca)
end

----------------------------------------------------------------------------
--- SHIELD CLASS
----------------------------------------------------------------------------
local Shield = Class()

function Shield:init()
	self.image = SHIELDIMAGE
	self.x = 0
	self.y = 0
	self.rotation = 0
	self.scaleX = 1
	self.scaleY = 1
	self.offsetX = self.image:getWidth()/2
	self.offsetY = self.image:getHeight()/2
	self.alpha = 1
end

function Shield:draw()
	local cr, cg, cb, ca = love.graphics.getColor()

	--- DRAW SELF
	love.graphics.setColor(cr, cg, cb, self.alpha * ca)
	love.graphics.draw(self.image, self.x * g.windowScaleX, self.y * g.windowScaleY, self.rotation, self.scaleX * g.windowScaleX, self.scaleY * g.windowScaleY , self.offsetX, self.offsetY)

	--- RESTORE COLOR
	love.graphics.setColor(cr, cg, cb, ca)
end

----------------------------------------------------------------------------
--- TITLE LETTER CLASS
----------------------------------------------------------------------------
local TitleLetter = Class()

function TitleLetter:init()
	self.x = 0
	self.y = 0
	self.rotation = 0
	self.scaleX = 1
	self.scaleY = 1
	self.alpha = 1
	self.offsetX = 0
	self.offsetY = 0
	self.offsetAnchorX = 0
	self.offsetAnchorY = 0
	self.baseText = nil
	self.renderText = nil
	self.letterString = nil
end

function TitleLetter:draw()
	local cr, cg, cb, ca = love.graphics.getColor()
	love.graphics.setColor(cr, cg, cb, self.alpha * ca)
	love.graphics.draw(self.renderText, self.x * g.windowScaleX, self.y * g.windowScaleY, self.rotation, self.scaleX, self.scaleY, self.offsetAnchorX * self.renderText:getWidth(), self.offsetAnchorY * self.renderText:getHeight())
	love.graphics.setColor(cr, cg, cb, ca)
end

local FirstTitleLetter = TitleLetter()

function FirstTitleLetter:init(letterString, duration, x, y, scaleStartX, scaleStartY)
	self.letterString = letterString or "-"
	self.baseText = love.graphics.newText(TITLEBASEFONT, self.letterString)
	self.renderText = love.graphics.newText(titleRenderFont, self.letterString)
	self.offsetAnchorX = 0.5
	self.offsetAnchorY = 0.5
	self.x = x
	self.y = y
	self.scaleXGoal = self.scaleX
	self.scaleYGoal = self.scaleY
	self.scaleStartX = scaleStartX
	self.scaleStartY = scaleStartY

	self.actualWidth = self.baseText:getWidth()
	self.timer = timer:newTimer(duration)
end

function FirstTitleLetter:update()
	self.scaleX = self.scaleXGoal + (self.scaleStartX - self.scaleXGoal) - (self.scaleStartX - self.scaleXGoal) * self.timer:getProgress()
	self.scaleY = self.scaleYGoal + (self.scaleStartY - self.scaleYGoal) - (self.scaleStartY - self.scaleYGoal) * self.timer:getProgress()
	self.alpha = self.timer:getProgress("inCubic")
end

local GenericTitleLetter = TitleLetter()

function GenericTitleLetter:init(letterString, startX, startY, delay, slideDuration, firstLetterObject)
	self.letterString = letterString
	self.x = startX
	self.y = startY
	self.startX = 0
	self.goalX = 0
	self.delay = delay
	self.slideDuration = slideDuration
	self.firstLetterObject = firstLetterObject

	self.baseText = love.graphics.newText(TITLEBASEFONT, self.letterString)
	self.actualWidth = self.baseText:getWidth()
	self.renderText = love.graphics.newText(titleRenderFont, LETTERS[math.random(1, #LETTERS)])
	self.offsetAnchorX = 0
	self.offsetAnchorY = 0.5
	self.alpha = 0
	self.changeInterval = GENERICTITLELETTERCHANGEINTERVAL

	self.delayTimer = timer:newTimer(self.delay)
	self.slideTimer = timer:newTimer(self.slideDuration)
	self.changeTimer = timer:newTimer(self.changeInterval)
end

function GenericTitleLetter:update()
	if self.delayTimer and not self.delayTimer:isFinished() then
		return
	end
	if self.delayTimer and self.delayTimer:isFinished() then
		self.slideTimer = timer:newTimer(self.slideDuration)
		self.changeTimer = timer:newTimer(self.changeInterval)
		self.delayTimer = nil
		self.startX = self.firstLetterObject.x
	end

	if self.slideTimer then
		self.x = self.startX + (self.goalX - self.startX) * self.slideTimer:getProgress("outSine")
		self.alpha = self.slideTimer:getProgress("outSine")

		if not self.slideTimer:isFinished() then
			if self.changeTimer:isFinished() then
				self.renderText:set(LETTERS[math.random(1, #LETTERS)])
				self.changeTimer = timer:newTimer(self.changeInterval)
			end
		else
			-- self.x = self.goalX
			self.renderText:set(self.letterString)
			self.slideTimer = nil
		end
	end
end

----------------------------------------------------------------------------
--- SUBTITLE CLASS
----------------------------------------------------------------------------
local Subtitle = Class()

function Subtitle:init(textString)
	self.x = 0
	self.y = 0
	self.rotation = 0
	self.scaleX = 1
	self.scaleY = 1
	self.offsetAnchorX = 0
	self.offsetAnchorY = 0
	self.textString = textString
	self.renderText = love.graphics.newText(subtitleFont, self.textString)
	self.fadeTimer = timer:newTimer(SUBTITLEFADEDURATION, SUBTITLEFADEDELAY)
end

function Subtitle:draw()
	local cr, cg, cb, ca = love.graphics.getColor()
	love.graphics.setColor(cr, cg, cb, ca * self.fadeTimer:getProgress("outSine"))
	love.graphics.draw(self.renderText, self.x * g.windowScaleX, self.y * g.windowScaleY, self.rotation, self.scaleX, self.scaleY, self.renderText:getWidth() * self.offsetAnchorX, self.renderText:getHeight() * self.offsetAnchorY)
	love.graphics.setColor(cr, cg, cb, ca)
end

----------------------------------------------------------------------------
--- FUNCTIONS
----------------------------------------------------------------------------

local function swordShieldStencil()
	love.graphics.setShader(shaderStencil)
	sword:draw()
	shield:draw()
	love.graphics.setShader()
end

local function createTitleLetters()
	--- PICK A RANDOM TITLE
	local title = GAMETITLES[math.random(1, #GAMETITLES)]

	--- CREATE FIRST LETTER OBJECT
	titleLetters[1] = FirstTitleLetter(string.upper(string.sub(title, 1, 1)), FIRSTTITLELETTERDURATION, swordShieldX, swordShieldY, FIRSTTITLELETTERSCALESTARTX, FIRSTTITLELETTERSCALESTARTY)

	--- CREATE THE REST OF THE LETTER OBJECTS
	for i = #title, 2, -1 do
		local delay = (#title-i) * GENERICTITLELETTERSPAWNINTERVAL
		titleLetters[i] = GenericTitleLetter(string.lower(string.sub(title, i, i)), swordShieldX, swordShieldY, delay + SLIDEDELAY, GENERICTITLELETTERSLIDEDURATION - delay, titleLetters[1])
	end

	--- MEASURE TOTAL WIDTH OF LETTERS
	for i = 1, #titleLetters do
		titleLettersTotalWidth = titleLettersTotalWidth + titleLetters[i].actualWidth
	end

	--- CALCULATE GOAL COORDINATES FOR LETTERS
	local add = g.windowBaseWidth/2 - titleLettersTotalWidth/2
	for i = 1, #titleLetters do
		titleLettersCoordinates[i] = add
		add = add + titleLetters[i].actualWidth + TITLELETTERSPACING
	end

	--- SET GOAL COORDINATES OF LETTERS
	for i = 1, #titleLetters do
		titleLetters[i].goalX = titleLettersCoordinates[i]
	end
end

local function drawTitleLetters()
	for _, titleObject in pairs(titleLetters) do
		titleObject:draw()
	end
end

local function updateTitleLetters()
	if #titleLetters > 0 then
		titleLetters[1].x = shield.x
	end

	for _, titleObject in pairs(titleLetters) do
		titleObject:update()
	end
end

function generalDraw(drawable, x, y, rotation, scaleX, scaleY, offsetX, offsetY)
	love.graphics.draw(drawable, x * g.windowScaleX, y * g.windowScaleY, rotation, scaleX * g.windowScaleX, scaleY * g.windowScaleY, offsetX, offsetY)
end

function gametitleStringsTest()
	for _, str in pairs(GAMETITLES) do
		if #str <= 5 then
			print(str)
		end
	end
end

----------------------------------------------------------------------------
--- SCENE FUNCTIONS
----------------------------------------------------------------------------

function sceneLogo.load()
	local width, height = g.windowBaseWidth, g.windowBaseHeight

	love.graphics.setBackgroundColor(5/255, 5/255, 7/255)
	backgroundRectangleAlpha = 0

	sword = Sword()
	sword.rotation = math.pi/2
	swordDistance = SWORDDISTANCESTART
	swordAngle = SWORDANGLESTART

	shield = Shield()
	shield.scaleX, shield.scaleY = SHIELDSCALESTART, SHIELDSCALESTART
	shield.rotation = SHIELDROTATIONSTART
	shield.alpha = SHIELDALPHASTART

	swordShieldX = width/2
	swordShieldY = height/2
	swordShieldXOri = swordShieldX

	titleRenderFont = love.graphics.newFont("fonts/Triforce.ttf", TITLEFONTSIZE * g.windowScaleY)
	titleLetters = {}
	titleLettersCoordinates = {}
	titleLettersTotalWidth = 0

	shaderStencil = love.graphics.newShader(shaders.stencil)

	camera:setZoom(1)
	camera.isStretchingEnabled = false
	camera.shakeRotationMax = CAMERASHAKEROTATIONNMAX
	camera.shakeTranslationXMax = CAMERASHAKETRANSLATEXMAX
	camera.shakeTranslationYMax = CAMERASHAKETRANSLATEYMAX
	camera.shakeDecaySpeed = CAMERASHAKESTRENGTH/(CAMERASHAKEDURATION*60)

	timers.bgFade = timer:newTimer(fadeDuration)
	phase = 1

	keybindButtons = {}

	sceneLogo.resize()
end

phaseFunctions = {}

--- FADE IN
phaseFunctions[1] = function()
	backgroundRectangleAlpha = timers.bgFade:getProgress()

	if timers.bgFade:isFinished() then
		phase = 2
		timers.clash = timer:newTimer(CLASHDURATION)
		love.audio.play(soundClash)
	end
end

--- SWORDWHIRLY
phaseFunctions[2] = function()
	--- SWORD
	swordDistance = SWORDDISTANCESTART * (1-timers.clash:getProgress()) + SWORDDISTANCEGOAL
	swordAngle = SWORDANGLESTART - (SWORDANGLESTART - SWORDANGLEGOAL) * timers.clash:getProgress()
	sword.rotation = SWORDROTATIONTOTAL * timers.clash:getProgress()

	--- SHIELD
	local shieldProgress = util.clamp(util.norm(SHIELDSTARTMULT, SHIELDENDMULT, timers.clash:getProgress()))

	shield.alpha = SHIELDALPHASTART + (SHIELDALPHAGOAL - SHIELDALPHASTART) * easing.outSine(shieldProgress, 0, 1, 1)
	shield.rotation = SHIELDROTATIONSTART - (SHIELDROTATIONSTART * easing.outSine(shieldProgress, 0, 1, 1))
	shield.scaleX = SHIELDSCALESTART - (SHIELDSCALESTART - SHIELDSCALEGOAL) * easing.outQuad(shieldProgress, 0, 1, 1)
	shield.scaleY = shield.scaleX

	if timers.clash:isFinished() then
		sword.trailEnabled = false
		camera:shake(CAMERASHAKESTRENGTH)
		phase = 3
		createTitleLetters()
		timers.swordFollowThrough = timer:newTimer(SWORDFOLLOWTHROUGHDURATION)
		timers.zoom = timer:newTimer(ZOOMDURATION)
		camera:setZoom(ZOOMAMOUNT)
		timers.slideDelay = timer:newTimer(SLIDEDELAY)

		love.audio.play(soundBG)
		soundBG:setVolume(SOUNDBGVOLUME)
	end
end

--- CLASHED
phaseFunctions[3] = function()
	local followThroughProgress = timers.swordFollowThrough:getProgress()
	if followThroughProgress <= 0.5 then
		swordDistance = SWORDDISTANCEGOAL - SWORDFOLLOWTHROUGHDISTANCE * easing.linear(followThroughProgress, 0, 1, 0.5)
	else
		swordDistance = SWORDDISTANCEGOAL - SWORDFOLLOWTHROUGHDISTANCE * (1-easing.linear(followThroughProgress - 0.5, 0, 1, 0.5))
	end
	camera:setZoom(ZOOMAMOUNT - (ZOOMAMOUNT-1) * timers.zoom:getProgress("outQuint"))

	if timers.slideDelay:isFinished() then
		if not timers.slide then
			timers.slide = timer:newTimer(SLIDEDURATION)
		end

		--- CREATE SUBTITLES
		if not subtitleTop or not subtitleBottom then
			subtitleFontSize = math.min(titleLettersTotalWidth * SUBTITLEFONTSIZEFACTOR, SUBTITLEFONTSIZEMAX)
			subtitleFont = love.graphics.newFont(FONTSUBTITLEPATH, subtitleFontSize * g.windowScaleY)
			subtitleTop = Subtitle(SUBTITLETOPSTRING)
			subtitleBottom = Subtitle(SUBTITLEBOTTOMSTRING)
			subtitleTop.offsetAnchorY = 1
		end

		local distance = swordShieldXOri - titleLettersTotalWidth/2 - swordShieldXOri + titleLetters[1].actualWidth/2
		swordShieldX = swordShieldXOri + distance * timers.slide:getProgress("inOutCubic")

		subtitleTop.x = swordShieldX + SUBTITLETOPDISTANCEX
		subtitleTop.y = swordShieldY + SUBTITLETOPDISTANCEY
		subtitleBottom.x = swordShieldX + SUBTITLEBOTTOMDISTANCEX
		subtitleBottom.y = swordShieldY + SUBTITLEBOTTOMDISTANCEY

		if timers.slide:isFinished() then
			timers.startKeybind = timer:newTimer(STARTKEYBINDFADEDURATION)

			--- CREATE KEYBIND BUTTONS
			local moveButtonsX, moveButtonsY = 90, 350
			local actionButtonsX, actionButtonsY = g.windowBaseWidth * 0.75, 370
			local buttonSize = 34

			local function setKey(scancode, keyName)
				settings.keybinds[keyName] = scancode
			end

			table.insert(keybindButtons, ui.KeybindButton(settings.keybinds.up, setKey, "up", moveButtonsX, moveButtonsY, buttonSize))
			table.insert(keybindButtons, ui.KeybindButton(settings.keybinds.down, setKey, "down", moveButtonsX, moveButtonsY + buttonSize*1.15, buttonSize))
			table.insert(keybindButtons, ui.KeybindButton(settings.keybinds.left, setKey, "left", moveButtonsX - buttonSize*1.15, moveButtonsY + buttonSize*1.15, buttonSize))
			table.insert(keybindButtons, ui.KeybindButton(settings.keybinds.right, setKey, "right", moveButtonsX + buttonSize*1.15, moveButtonsY + buttonSize*1.15, buttonSize))

			table.insert(keybindButtons, ui.KeybindButton(settings.keybinds.a, setKey, "a", actionButtonsX, actionButtonsY, buttonSize))
			table.insert(keybindButtons, ui.KeybindButton(settings.keybinds.b, setKey, "b", actionButtonsX + buttonSize*1.15, actionButtonsY, buttonSize))
			table.insert(keybindButtons, ui.KeybindButton(settings.keybinds.start, setKey, "start", actionButtonsX + buttonSize*3.5, actionButtonsY, buttonSize*1.3))

			---
			phase = 4
		end
	end
end

---
phaseFunctions[4] = function()

end

--- END ZOOM
phaseFunctions[5] = function()
	sword.scaleX = SWORDSCALEX + 40 * util.clamp(util.norm(0.3, 1, timers.endSwordwhirly:getProgress("inQuad")))
	sword.scaleY = SWORDSCALEY + 40 * util.clamp(util.norm(0.2, 1, timers.endSwordwhirly:getProgress("inQuad")))

	sword.offsetY = sword.image:getHeight()/2 - (sword.image:getHeight()/2) * 0.9 * util.clamp(util.norm(0, 0.4, timers.endSwordwhirly:getProgress()))
	swordDistance = SWORDDISTANCEGOAL + (g.windowBaseWidth - swordShieldX)*1.3 * util.clamp(util.norm(0, 1, timers.endSwordwhirly:getProgress("inSine")))
	swordAngle = SWORDANGLEGOAL - SWORDANGLEGOAL * util.clamp(util.norm(0, 1, timers.endSwordwhirly:getProgress("outSine")))
	sword.rotation = SWORDROTATIONTOTAL - (SWORDROTATIONTOTAL + math.pi*4 - (math.pi/2)) *  util.clamp(util.norm(0, 1, timers.endSwordwhirly:getProgress("outSine")))

	local progress = util.getBias(timers.endZoom:getProgress(), ENDZOOMBIAS)
	camera:setZoom(1+15*progress)

	soundBG:setVolume(SOUNDBGVOLUME - SOUNDBGVOLUME * util.clamp(util.norm(0, 0.8, timers.endZoomDelay:getProgress())))
end

function sceneLogo.update(dt)
	----------------------------------------------------------------------------
	--- UPDATE TIMER CONTAINER AND CAMERA
	----------------------------------------------------------------------------
	timer:update(dt)
	camera:update()

	----------------------------------------------------------------------------
	--- PHASES
	----------------------------------------------------------------------------

	--- FADE IN
	phaseFunctions[phase]()

	----------------------------------------------------------------------------
	--
	----------------------------------------------------------------------------

	sword.x, sword.y = util.getPointDeg(swordShieldX, swordShieldY, swordAngle, swordDistance)
	sword:update()

	shield.x, shield.y = swordShieldX, swordShieldY
	-- shield:update()

	updateTitleLetters()
end

function sceneLogo.draw()
	local w = g.windowBaseWidth
	local h = g.windowBaseHeight
	local backgroundRectangleWidth = w*3
	local backgroundRectangleHeight = h*3
	local hh = love.graphics.getHeight()

	--- SET CAMERA
	camera:drawSet()

	--- DRAW BACKGROUND
	love.graphics.setColor(BGCOLOR[1], BGCOLOR[2], BGCOLOR[3], backgroundRectangleAlpha) -- 245, 245, 230; 5 5 7
	love.graphics.rectangle("fill", -w/2 * g.windowScaleX, -h/2 * g.windowScaleY, backgroundRectangleWidth * g.windowScaleX, backgroundRectangleHeight * g.windowScaleY)

	--- DRAW KEYBINDS AND START MESSAGE
	if timers.startKeybind then
		love.graphics.setColor(0, 0, 0, timers.startKeybind:getProgress("inSine"))

		--- DRAW KEYBIND BUTTONS
		if #keybindButtons > 0 then
			for _, button in pairs(keybindButtons) do
				button:draw()
			end
		end

		--- DRAW KEYBIND LABELS
		love.graphics.setColor(0, 0, 0, timers.startKeybind:getProgress("inSine") * 0.8)
		love.graphics.printf("Move", LABELFONT:getFont(), 68 * g.windowScaleX, 310 * g.windowScaleY, 200*g.windowScaleX)
		love.graphics.printf("Sword", LABELFONT:getFont(), 550 * g.windowScaleX, 331 * g.windowScaleY, 200*g.windowScaleX)
		love.graphics.printf("Shield", LABELFONT:getFont(), 591 * g.windowScaleX, 390 * g.windowScaleY, 200*g.windowScaleX)
		love.graphics.printf("Start/Pause", LABELFONT:getFont(), 650 * g.windowScaleX, 324 * g.windowScaleY, 200*g.windowScaleX)

		--- DRAW PRESS START MESSAGE
		love.graphics.setColor(0, 0, 0, ((math.cos(love.timer.getTime()*2) + 1)/2 + 0.1) * timers.startKeybind:getProgress("inSine"))
		love.graphics.printf("Press Start + Sword", PRESSSTARTFONT:getFont(), 0, hh*0.83 , w*g.windowScaleX, "center")

		love.graphics.setColor(1, 1, 1, 1)
	end

	--- DRAW SWORD AND SHIELD and EXPERIMENTAL FLASH EFFECT
	love.graphics.setColor(0, 0, 0)

	sword:draw()

	love.graphics.setColor(0, 0, 0)
	shield:draw()

	--- DRAW SUBTITLE (THE LEGEND OF, ETC)
	if subtitleTop and subtitleBottom then
		subtitleTop:draw()
		subtitleBottom:draw()
	end

	--- DRAW BLACK BG AFTER SWORD GROW
	if timers.endSwordwhirly and timers.endSwordwhirly:isFinished() then
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", -1, -1, love.graphics.getWidth(), love.graphics.getHeight())
	end

	--- CLASHED
	if phase >= 3 then
		--- DRAW STENCIL
		love.graphics.stencil(swordShieldStencil)

		--- DRAW WHITE COLORED TITLE INSIDE OF SWORD AND SHIELD
		love.graphics.setStencilTest("greater", 0)
		love.graphics.setColor(1, 1, 1)
		drawTitleLetters()

		--- DRAW BLACK COLORED TITLE OUTSIDE OF SWORD AND SHIELD
		love.graphics.setStencilTest("less", 1)
		love.graphics.setColor(0, 0, 0)
		drawTitleLetters()

		love.graphics.setStencilTest()
	end

	--- DRAW BLACK END SCREEN
	if timers.endZoom and timers.endZoom:isFinished() then
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", -1, -1, love.graphics.getWidth(), love.graphics.getHeight())
	end

	--- UNSET CAMERA
	camera:drawUnset()

	--- DRAW VIGNETTE
	love.graphics.setColor(1, 1, 1, VIGNETTEALPHA)
	love.graphics.draw(VIGNETTE, 0, 0, 0, VIGNETTE:getWidth()/g.windowBaseWidth*g.windowScaleX, VIGNETTE:getHeight()/g.windowBaseHeight*g.windowScaleY)
end

function sceneLogo.keypressed(key, scancode, isrepeat)
	--- START
	if phase == 4 then
		if love.keyboard.isDown(settings.keybinds.start) and love.keyboard.isDown(settings.keybinds.a) then
			timers.endZoom = timer:newTimer(ENDZOOMDURATION, ENDZOOMDELAY)
			timers.endZoomDelay = timer:newTimer(ENDZOOMDELAY, 0, function() love.audio.play(soundEndZoom) end)
			timers.endSwordwhirly = timer:newTimer(ENDSWORDWHIRLYDURATION)
			love.audio.play(soundEndSword)
			phase = 5
		end
	end

	--- KEYBIND BUTTONS
	if #keybindButtons > 0 then
		for _, button in pairs(keybindButtons) do
			button:keypressed(key, scancode, isrepeat)
		end
	end

	--- RE-ENTER SCENE
	if key == "f12" then
		love.audio.stop()
		fadeDuration = 0
		scene.setScene("sceneLogo")
	end
end

function sceneLogo.resize()
	--- update titleletters text
	titleRenderFont = love.graphics.newFont("fonts/Triforce.ttf", TITLEFONTSIZE * g.windowScaleY)
	for _, letter in pairs(titleLetters) do
		letter.renderText = love.graphics.newText(titleRenderFont, letter.letterString)
	end

	--- update subtitle text
	if subtitleFontSize then
		subtitleFont = love.graphics.newFont(FONTSUBTITLEPATH, subtitleFontSize * g.windowScaleY)
	end
	if subtitleTop and subtitleBottom then
		subtitleTop.renderText = love.graphics.newText(subtitleFont, subtitleTop.textString)
		subtitleBottom.renderText = love.graphics.newText(subtitleFont, subtitleBottom.textString)
	end

	--- update keybindbuttons
	if #keybindButtons > 0 then
		for _, button in pairs(keybindButtons) do
			button:resize()
		end
	end

	--- update other fonts
	PRESSSTARTFONT:resize()
	LABELFONT:resize()
end

function sceneLogo.mousepressed(x, y, button, istouch, presses)
	if #keybindButtons > 0 then
		for _, keybindButton in pairs(keybindButtons) do
			keybindButton:mousepressed(x, y, button, istouch, presses)
		end
	end
end

function sceneLogo.exit()
	sword = nil
	shield = nil
	titleLetters = nil
	subtitleTop = nil
	subtitleBottom = nil
	timer:deleteTimers()
	timers = {}
end

return sceneLogo