local g = require "globals"

function love.conf(t)
	local m = 3
	t.window.width = 256 * m
	t.window.height = 144 * m
	t.window.minwidth = t.window.width
	t.window.minheight = t.window.height

	g.windowBaseWidth = t.window.width
	g.windowBaseHeight = t.window.height
	g.windowScaleX = 1
	g.windowScaleY = 1

	t.console = false
	t.window.resizable = true
	t.identity = "titlescreendemo"
	t.window.title = " "
	t.window.vsync = false
end