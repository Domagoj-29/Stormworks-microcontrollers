-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

local function clamp(value, min, max)
	return math.max(min, math.min(value, max))
end
local function createCounter(startValue)
	local counter = startValue
	return function(down, up, increment, min, max, reset, resetValue)
		if down then
			counter = counter - increment
		end
		if up then
			counter = counter + increment
		end
		if reset then
			counter = resetValue
		end
		counter = clamp(counter, min, max)
		return counter
	end
end

azimuthCounter = createCounter(-0.5)

AzimuthTurns = -0.5

RadarDirections = { [1] = "Up", [2] = "Down" }
RadarFacing = RadarDirections[property.getNumber("Radar facing")]

function onTick()
	local radarOn = input.getBool(1)
	AzimuthTurns = azimuthCounter(false, true, 0.001, -0.5, 0.5, (not radarOn) or AzimuthTurns == 0.5, -0.5)

	output.setNumber(1, AzimuthTurns) -- Output for the target data module
	if RadarFacing == "Up" then -- Output for the radar itself
		output.setNumber(2, AzimuthTurns)
	elseif RadarFacing == "Down" then
		output.setNumber(2, -AzimuthTurns)
	end
end
