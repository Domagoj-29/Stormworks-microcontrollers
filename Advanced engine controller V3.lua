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
		if math.abs(error)<2 then
			integral=integral+error*I
		else
			integral=integral*0.9
		end

		return error*P+integral+derivative*D
	end
end
local function linearInterpolation(x,x1,x2,y1,y2)
	return y1+((x-x1)*(y2-y1)/(x2-x1))
end
local function clamp(value,min,max)
	value=math.max(min,math.min(value,max))
	return value
end
local function createDelta()
	local oldVariable=0
	return function(variable)
		local delta=variable-oldVariable
		oldVariable=variable
		return delta
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

local idlePID=createPID()
local deltaBatteryCharge=createDelta()
local upDownAFR=createUpDown(0.5)
local upDownAlternator=createUpDown(0)
local upDownDynamicThrottle=createUpDown(0)

MaxRPS=property.getNumber("RPS limiter")
ManualLimiterSensitivity=property.getNumber("RPS limiter sensitivity")
MinimumIdleRPS=property.getNumber("Idle RPS")
MaxClutchRPS=property.getNumber("RPS to fully engage the clutch")
OverheatingProtectionThreshold=property.getNumber("Overheating protection threshold")
MaxFluidPumpTemperature=property.getNumber("Temperature to fully engage the fluid pump")
RadiatorFanTemperatureThreshold=property.getNumber("Radiator fan activation temperature")
MaxBatteryCharge=property.getNumber("Max battery charge")
MinThrottle=property.getNumber("Min throttle")
MaxThrottle=property.getNumber("Max throttle")

DynamicIdleRPS=property.getBool("Dynamic idle RPS")

IdleRPS=MinimumIdleRPS

function onTick()
	local air=input.getNumber(1)
	local fuel=input.getNumber(2)
	local engineTemperature=input.getNumber(3)
	local throttle=input.getNumber(4)
	local crankshaftRPS=input.getNumber(5)
	local batteryCharge=input.getNumber(6)

	local engine=input.getBool(1)

	if engine and engineTemperature<OverheatingProtectionThreshold then
		if DynamicIdleRPS then
			IdleRPS=MinimumIdleRPS+upDownDynamicThrottle(batteryCharge>MaxBatteryCharge-0.003,batteryCharge<MaxBatteryCharge-0.004 and deltaBatteryCharge(batteryCharge)<0.0000001,0.01,0,MaxRPS-IdleRPS)
		end

		local idleThrottle=idlePID(IdleRPS,crankshaftRPS,0.8,0,0,true)

		throttle=clamp(linearInterpolation(throttle,MinThrottle,MaxThrottle,0,1),0,1)
		engineThrottle=((throttle<0.2) and idleThrottle or throttle)

		local limiterSensitivity=(ManualLimiterSensitivity==0) and MaxRPS or ManualLimiterSensitivity
		local airManifold=engineThrottle/(clamp((2+0.2*limiterSensitivity)^(crankshaftRPS-MaxRPS),1,100))

		local realAFR=air/fuel
		local stoichiometryFormula=clamp(engineTemperature*0.004,0,0.4)
		local setpointAFR=13.6+stoichiometryFormula
		local fuelManifold=airManifold*upDownAFR(realAFR<setpointAFR,realAFR>setpointAFR,0.00005,0.3,0.7)

		local starter=crankshaftRPS<2.1

		local clutch=((crankshaftRPS<2.1 or throttle<0.05) and 0 or crankshaftRPS*(1/MaxClutchRPS))

		local fluidPump=clamp(engineTemperature*(1/MaxFluidPumpTemperature),0,1)
		local radiatorFan=engineTemperature>RadiatorFanTemperatureThreshold

		local alternator=upDownAlternator(batteryCharge>MaxBatteryCharge-0.003,batteryCharge<MaxBatteryCharge-0.004,0.01,0,1)

		output.setNumber(1,airManifold)
		output.setNumber(2,fuelManifold)
		output.setNumber(3,clutch)
		output.setNumber(4,fluidPump)
		output.setNumber(5,alternator)

		output.setBool(1,starter)
		output.setBool(2,radiatorFan)
	else
		idlePID(0,0,0,0,0,false)

		output.setNumber(1,0)
		output.setNumber(2,0)
		output.setNumber(3,0)
		output.setNumber(4,0)
		output.setNumber(5,0)

		output.setBool(1,false)
		output.setBool(2,false)
	end
end
