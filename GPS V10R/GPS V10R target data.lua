-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

-- x, y, z = physics sensor ch.1 - 3
-- pitch, yaw, roll = physics sensor ch.4 - 6
-- azimuth, elevation, distance = radar (azimuth and elevation turns -> radians!)
-- offsets are in workbench blocks, with X, Y, Z being right, up and forward
local function radarToGPS(x, y, z, pitch, yaw, roll, azimuth, elevation, distance, offsetX, offsetY, offsetZ)
	local pitchSin, pitchCos = math.sin(pitch), math.cos(pitch)
	local yawSin, yawCos = math.sin(yaw), math.cos(yaw)
	local rollSin, rollCos = math.sin(roll), math.cos(roll)
	local azSin, azCos = math.sin(azimuth), math.cos(azimuth)
	local elSin, elCos = math.sin(elevation), math.cos(elevation)

	local radarX = distance * azSin * elCos + offsetX / 4
	local radarY = distance * elSin + offsetY / 4
	local radarZ = distance * azCos * elCos + offsetZ / 4

	return
		radarX * rollCos * yawCos + radarY * (rollCos * pitchSin * yawSin - rollSin * pitchCos) +
		radarZ * (rollSin * pitchSin + rollCos * pitchCos * yawSin) + x,
		radarX * yawCos * rollSin + radarY * (rollCos * pitchCos + pitchSin * yawSin * rollSin) +
		radarZ * (-rollCos * yawSin + pitchCos * pitchSin * rollSin) + y,
		-radarX * yawSin + radarY * yawCos * pitchSin + radarZ * pitchCos * yawCos + z
end

pi2 = math.pi * 2

FOV = property.getNumber("FOV in degrees")
MaxDistance = property.getNumber("Radar/sonar type")
MinDistance = property.getNumber("Minimum target distance")
OffsetX = property.getNumber("Radar block offset [right]") -- offsets are relative to the physics sensor
OffsetY = property.getNumber("Radar block offset [up]")
OffsetZ = property.getNumber("Radar block offset [forward]")

function onTick()
	local gpsX, altitude, gpsY = input.getNumber(1), input.getNumber(2), input.getNumber(3)
	local eulerX, eulerY, eulerZ = input.getNumber(4), input.getNumber(5), input.getNumber(6) -- in radians
	local targetDistance, signalStrength = input.getNumber(18), input.getNumber(19)
	local targetElevation, targetAzimuth = input.getNumber(20), input.getNumber(21) -- in turns
	local radarOn = input.getBool(1)
	local targetFound = input.getBool(2)
	local targetWithinBounds = targetDistance > MinDistance and targetDistance < MaxDistance

	if radarOn and targetFound and targetWithinBounds then
		targetAzimuth = ((targetAzimuth + FOV / 360 * 0.5 + 0.5) % 1 - 0.5) * pi2 -- This is for a clockwise rotating radar
		targetElevation = targetElevation * pi2

		local targetX, targetAltitude, targetY =
			radarToGPS(gpsX, altitude, gpsY, eulerX, eulerY, eulerZ, targetAzimuth, targetElevation, targetDistance, OffsetX, OffsetY, OffsetZ)

		local dx, dy = targetX - gpsX, targetY - gpsY
		local targetHorizontalDistance = math.sqrt(dx ^ 2 + dy ^ 2) / 1000
		local targetBearing = (math.deg(math.atan(dx, dy)) + 360) % 360
		local targetWeight = targetDistance * signalStrength

		output.setNumber(1, targetX)
		output.setNumber(2, targetY)
		output.setNumber(3, targetHorizontalDistance)
		output.setNumber(4, targetBearing)
		output.setNumber(5, targetWeight)
	else
		for i = 1, 5 do
			output.setNumber(i, 0)
		end
	end
end
