-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

-- Credits:
-- Engine Based Fuel Calculator (L/sec, Total): https://steamcommunity.com/sharedfiles/filedetails/?id=3263506962

local totalConsumption=0
function onTick()
	local cylinderCount=property.getNumber("Cylinder count")
	local spawnFuel=property.getNumber("Spawned fuel")

	local fuelVolume=input.getNumber(2)
	local speed=input.getNumber(4)

	local fuelConsumption=fuelVolume*cylinderCount*216000
	totalConsumption=totalConsumption+fuelVolume*cylinderCount

	local range=0
	if fuelVolume>0 then
		range=(spawnFuel/fuelConsumption)*(speed*3.6)
	end

	output.setNumber(1,fuelConsumption)
	output.setNumber(2,totalConsumption)
	output.setNumber(3,range)
end
