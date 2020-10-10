local timer = {}

local Class = require "Class"
local easing = require "easing"
local util = require "util"

----------------------------------------------------------------------------
--- TIMER CLASS
----------------------------------------------------------------------------

local Timer = Class()

function Timer:init(duration, delay, callback, container)
	self.duration = duration or 0
	self.delay = delay or 0
	self.callback = callback or nil
	self.container = container

	self.elapsed = 0
	self.delayElapsed = 0
	self.finished = false
	self.paused = false
end

function Timer:isFinished()
	return self.finished
end

function Timer:getElapsed()
	return math.max(0, self.elapsed - self.delay + self.delayElapsed)
end

function Timer:getTimeLeft()
	return math.max(0, self.duration - self.elapsed - self.delay + self.delayElapsed)
end

function Timer:getProgress(easingMethod)
	if self.duration == 0 then
		if self.delayElapsed < self.delay then
			return 0
		end
		return 1
	end

	easingMethod = easingMethod or "linear"
	local progress = util.clamp((math.max(0, self.elapsed - self.delay + self.delayElapsed) / self.duration))
	return easing[easingMethod](progress, 0, 1, 1)
end

function Timer:toEnd()
	-- self.elapsed = self.duration
	-- self.delayElapsed = self.delay
	self.elapsed = math.max(self.elapsed, self.duration)
	self.delayElapsed = math.max(self.delayElapsed, self.delay)
end

function Timer:update(time)
	if self.paused then
		return
	end
	if self.delayElapsed < self.delay then
		self.delayElapsed = self.delayElapsed + time
		return
	end
	if not self.finished then
		self.elapsed = self.elapsed + time
		if self.elapsed - self.delay + self.delayElapsed >= self.duration then
			self.finished = true
			self:onFinish()
		end
	end
end

function Timer:pause()
	self.paused = true
end

function Timer:unpause()
	self.paused = false
end

function Timer:destroy()
	if self.container then
		local timerTable = self.container.timers
		for i, timerObject in pairs(timerTable) do
			if timerObject == self then
				table.remove(timerTable, i)
				self = nil -- ???
			end
		end
	end
end

function Timer:setCallback(callbackFunction)
	self.callback = callbackFunction
end

function Timer:reset(duration, delay, callback)
	self.duration = duration or self.duration
	self.delay = delay or self.delay
	self.callback = callback or self.callback
	self.elapsed = 0
	self.delayElapsed = 0
	self.finished = false
end

function Timer:onFinish()
	if self.callback then
		self.callback()
	end
end

----------------------------------------------------------------------------
--- TIMER CONTAINER CLASS
----------------------------------------------------------------------------

local TimerContainer = Class()

function TimerContainer:init()
	self.timers = {}
end

function TimerContainer:newTimer(duration, delay, callback)
	local timerObject = Timer(duration, delay, callback, self)
	self.timers[#self.timers+1] = timerObject
	return timerObject
end

function TimerContainer:update(time)
	for _, timer in pairs(self.timers) do
		timer:update(time)
	end
end

function TimerContainer:deleteTimers()
	self.timers = {}
end

function TimerContainer:pauseAll()
	-- take care of already paused timers
end

timer.Timer = Timer
timer.TimerContainer = TimerContainer

return timer