local util = {}

----------------------------------------------------------------------------
--- MATHY STUFF
----------------------------------------------------------------------------

function util.getDistance(x1, y1, x2, y2)
	return math.sqrt((x1-x2)^2 + (y1-y2)^2)
end

function util.getAngleRad(x1, y1, x2, y2)
	return math.atan2(y2 - y1, x2 - x1) -- normally: (y2 - y1, x2 - x1)
end

function util.getAngleDeg(x1, y1, x2, y2)
	return math.deg(util.getAngleRad(x1, y1, x2, y2))
end

function util.getPointRad(x, y, angleInRadians, distance)
	local newX = distance * math.cos(angleInRadians) + x
	local newY = distance * math.sin(angleInRadians) + y
	return newX, newY
end

function util.getPointDeg(x, y, angleInDegrees, distance)
	return util.getPointRad(x, y, math.rad(angleInDegrees), distance)
end

function util.getShortestAngleDifferenceRad(angleStart, angleGoal)
	angleStart = angleStart % (math.pi*2)
	angleGoal = angleGoal % (math.pi*2)
	local angleMin, angleMax
	if angleStart < angleGoal then
		angleMin = angleStart
		angleMax = angleGoal
	else
		angleMin = angleGoal
		angleMax = angleStart
	end
	local diff = angleMax - angleMin
	if diff > math.pi then
		diff = (angleMin + math.pi*2 - angleMax) * -1
	end
	if angleStart < angleGoal then
		return diff
	end
	return -diff
end

function util.round(value, decimalPlaces)
	local mult = 10^(decimalPlaces or 0)
	return math.floor(value * mult + 0.5) / mult
end

function util.roundNearest(value, nearest)
	return util.round(value / nearest) * nearest
end

function util.average(t)
	local rv = 0
	for i = 1, #t do
		rv = rv + t[i]
	end
	rv = rv / #t
	return rv
end

function util.clamp(value, minimum, maximum)
	minimum = minimum or 0
	maximum = maximum or 1
	return math.max(math.min(value, maximum), minimum)
end

function util.lerp(min, max, t) -- lerp(0, 100, 0.5) == 50
	return min + t * (max - min)
	-- return (1 - t) * min + t * max
end

function util.norm(min, max, value) -- norm(0, 100, 50) == 0.5
	return (value - min) / (max - min)
end

function util.getBias(time, bias) -- http://demofox.org/biasgain.html
	return (time / ((((1.0/bias) - 2.0)*(1.0 - time))+1.0))
end

function util.getGain(time, gain)
	if time < 0.5 then
		return util.getBias(time * 2.0, gain)/2.0
	else
		return util.getBias(time * 2.0 - 1.0, 1.0 - gain)/2.0 + 0.5
	end
end

function util.getRandomNegOneToOne()
	return math.random()*2-1
end

return util