function pid(p,i,d)
	return {
		p=p,i=i,d=d,
		E=0,D=0,I=0,
		run = function(s,sp,pv)
		local E=sp-pv
		local D=E-s.E
		s.E=E
		if math.abs(E)<2 then
			s.I=s.I+E*s.i
		else
			s.I=s.I*0.9
		end
		local output=E*s.p+s.I+D*s.d
		return math.max(0,math.min(output,1))
	end }
end
function linearInterpolation(x,x1,x2,y1,y2)
	return y1+((x-x1)*(y2-y1)/(x2-x1))
end
function clamp(value,min,max)
	value=math.max(min,math.min(value,max))
	return value
end
function createDelta()
	local oldVariable=0
	return function(variable)
		local delta=variable-oldVariable
		oldVariable=variable
		return delta
	end
end
function createUpDown(startValue)
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
pid1=pid(0.18,0.0003,0.02)
delta=createDelta()
upDownAFR=createUpDown(0.5)
upDownAlternator=createUpDown(0)
upDownDynamicThrottle=createUpDown(0)
function onTick()
    local air=input.getNumber(1)
	local fuel=input.getNumber(2)
	local engineTemperature=input.getNumber(3)
	local throttle=input.getNumber(4)
	local crankshaftRPS=input.getNumber(5)
	local batteryCharge=input.getNumber(6)

    local maxRPS=property.getNumber("RPS limiter")
	local idleRPS=property.getNumber("Idle RPS")
	local maxClutchRPS=property.getNumber("RPS to fully engage the clutch")
	local overheatingProtectionThreshold=property.getNumber("Overheating protection threshold")
    local maxFluidPumpTemperature=property.getNumber("Temperature to fully engage the fluid pump")
	local radiatorFanTemperatureThreshold=property.getNumber("Radiator fan activation temperature")
	local maxBatteryCharge=property.getNumber("Max battery charge")
	local minThrottle=property.getNumber("Min throttle")
	local maxThrottle=property.getNumber("Max throttle")

    local engine=input.getBool(1)

	local dynamicIdleRPS=property.getBool("Dynamic idle RPS")

    if engine and engineTemperature<overheatingProtectionThreshold then
		local deltaBatteryCharge=delta(batteryCharge)
		if dynamicIdleRPS then
			idleRPS=idleRPS+upDownDynamicThrottle(batteryCharge>maxBatteryCharge-0.003 or deltaBatteryCharge>0.00000015,batteryCharge<maxBatteryCharge-0.004 and deltaBatteryCharge<0.0000001,0.01,0,maxRPS-idleRPS)
		end

		throttle=clamp(linearInterpolation(throttle,minThrottle,maxThrottle,0,1),0,1)
		local engineThrottle=linearInterpolation(throttle,0,1,idleRPS,maxRPS)
		--local engineThrottle=clamp(throttle,1/maxRPS*idleRPS,2)
		--engineThrottle=engineThrottle*maxRPS

		local airManifold=pid1:run(engineThrottle,crankshaftRPS)

		local realAFR=air/fuel
		local stoichiometryFormula=clamp(engineTemperature*0.004,0,0.4)
		local setpointAFR=13.6+stoichiometryFormula
		local fuelManifold=airManifold*upDownAFR(realAFR<setpointAFR,realAFR>setpointAFR,0.00005,0.3,0.7)

		local starter=crankshaftRPS<2.1

		local clutch=((throttle<0.001 or crankshaftRPS<2.1) and 0 or crankshaftRPS*(1/maxClutchRPS))

		local fluidPump=clamp(engineTemperature*(1/maxFluidPumpTemperature),0,1)
		local radiatorFan=engineTemperature>radiatorFanTemperatureThreshold

		local alternator=upDownAlternator(batteryCharge>maxBatteryCharge-0.003,batteryCharge<maxBatteryCharge-0.004,0.01,0,1)

		output.setNumber(1,airManifold)
		output.setNumber(2,fuelManifold)
		output.setNumber(3,clutch)
		output.setNumber(4,fluidPump)
		output.setNumber(5,alternator)

		output.setBool(1,starter)
		output.setBool(2,radiatorFan)
	else
		output.setNumber(1,0)
		output.setNumber(2,0)
		output.setNumber(3,0)
		output.setNumber(4,0)
		output.setNumber(5,0)

		output.setBool(1,false)
		output.setBool(2,false)
	end
end