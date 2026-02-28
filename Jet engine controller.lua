-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

-- onTick functions

local function createPID()
	local oldError=0
	local integral=0
	return function(setpoint,processVariable,P,I,D,active)
		if not active then
			oldError=0
			integral=0
			return 0
		end

		local error=setpoint-processVariable
		local derivative=error-oldError
		oldError=error
		integral=integral+error*I

		return error*P+integral+derivative*D
	end
end
local function createUpDown(startValue)
	local counter=startValue
	return function(down,up,increment,min,max)
		if down then
			counter=counter-increment
		end
		if up then
			counter=counter+increment
		end
		counter=math.max(min,math.min(counter,max))
		return counter
	end
end
local function linearInterpolation(x,x1,x2,y1,y2)
	return y1+((x-x1)*(y2-y1)/(x2-x1))
end
local function clamp(value,min,max)
	value=math.max(min,math.min(value,max))
	return value
end

local throttlePID=createPID()
local upDownGeneratorClutch=createUpDown(0)

MaxRPS=property.getNumber("RPS limiter")
MinimumIdleRPS=property.getNumber("Idle RPS")
MinThrottle=property.getNumber("Min throttle")
MaxThrottle=property.getNumber("Max throttle")

function onTick()
	local throttle=input.getNumber(1)
	local turbineRPS=input.getNumber(2)
	local batteryCharge=input.getNumber(3)

	local engine=input.getBool(1)

	throttle=clamp(linearInterpolation(throttle,MinThrottle,MaxThrottle,0,1),0,1)
	local engineThrottle=linearInterpolation(throttle,0,1,MinimumIdleRPS,MaxRPS)
	local compressorThrottle=clamp(throttlePID(engineThrottle,turbineRPS,0.5,0,0.01,engine),0.1,200)
	local generatorClutch=upDownGeneratorClutch(batteryCharge>0.997,batteryCharge<0.996,0.01,0,1)
	local starterMotor=(engine and turbineRPS<=0.65) and 1 or 0

	output.setNumber(1,compressorThrottle)
	output.setNumber(2,generatorClutch)
	output.setNumber(3,starterMotor)

	output.setBool(1,engine and turbineRPS<=0.65)
end