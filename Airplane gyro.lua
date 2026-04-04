-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

-- Credits:
-- ZE Airplane Flight Controller: https://steamcommunity.com/sharedfiles/filedetails/?id=2135313815
-- Physics Sensor Transformer: https://steamcommunity.com/sharedfiles/filedetails/?id=2936283512

-- onTick functions

local function makeMatC(phi,theta,psi)
	local mar={{math.cos(theta)*math.cos(psi), math.sin(phi)*math.sin(theta)*math.cos(psi)-math.cos(phi)*math.sin(psi),
		math.cos(phi)*math.sin(theta)*math.cos(psi)+math.sin(phi)*math.sin(psi)},{math.cos(theta)*math.sin(psi),
		math.sin(phi)*math.sin(theta)*math.sin(psi)+math.cos(phi)*math.cos(psi),math.cos(phi)*math.sin(theta)*math.sin(psi)-math.sin(phi)*math.cos(psi)},
		{-math.sin(theta),math.sin(phi)*math.cos(theta),math.cos(phi)*math.cos(theta)}}
	return mar
end
local function rotate(mat,vec)
	local temp={0,0,0}
	for i=1, 3 do
		local ali=0
		for j=1,3 do
			ali=ali+mat[i][j]*vec[j]
		end
		temp[i]=ali
	end
	return temp
end
local function transposeMatrix(maa)
	local grr={{0,0,0},{0,0,0},{0,0,0}}
	for i=1,3 do
		for j=1,3 do
			grr[j][i]=maa[i][j]
		end
	end
	return grr
end
local function clamp(inputNumber,minValue,maxValue)
	return math.max(minValue,math.min(inputNumber,maxValue))
end
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
local function createOriginalPID()
	local integral=0
	local output=0
	local timer=0
	return function(setpoint,processVariable,sensitivity,trim,trimMultiplier,I)
		local P=sensitivity*0.5+2

		if setpoint>-0.01 and setpoint<0.01 then
			timer=math.min(timer+1,60)
		else
			timer=0
		end
		local error=setpoint-processVariable
		if timer==60 and output>-1 and output<1 then
			integral=clamp(integral+I*error,-1,1)
		else
			integral=clamp(integral-I*integral,-1,1)
		end

		output=clamp(P*error+integral,-1,1)+(trim*trimMultiplier)
		return output
	end
end
local function createUpDown()
	local counter=0
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
local function createDelta()
	local oldValue=0
	return function(inputValue)
		local deltaValue=inputValue-oldValue
		oldValue=inputValue
		return deltaValue
	end
end
local function thresholdGate(inputNumber,lowThreshold,highThreshold)
	return (inputNumber>=lowThreshold and inputNumber<=highThreshold)
end
local function lerp(x,y,z)
	return x+z*(y-x)
end

local altitudeDelta=createDelta()
local stabUpDown=createUpDown()
local altHoldPID=createPID()
local pitchPID=createOriginalPID()
local rollPID=createOriginalPID()
local yawPID=createPID()

PitchTurnSpeed=0.3+property.getNumber("Pitch turn speed")*0.05 -- 0.3 --> 0.4 in the gyro version
PitchTrim=property.getNumber("Pitch trim")
RollTurnSpeed=-0.4-property.getNumber("Roll turn speed")*0.05
RollTrim=property.getNumber("Roll trim")
YawTurnSpeed=0.12+property.getNumber("Yaw turn speed")*0.02
YawTrim=property.getNumber("Yaw trim")*0.01
StabilizedPitchRoll=0.25+property.getNumber("Stabilized pitch and roll")*0.03

PitchPIDSensitivity=property.getNumber("Pitch PID sensitivity")
RollPIDSensitivity=property.getNumber("Roll PID sensitivity")
YawPIDSensitivity=5+property.getNumber("Yaw PID sensitivity")

OldYawPIDSetpoint=0
function onTick()
	local gpsX=input.getNumber(1)
	local altitude=input.getNumber(2)
	local gpsY=input.getNumber(3)
	local tiltFront=input.getNumber(15)
	local tiltRight=input.getNumber(16)
	local compass=input.getNumber(17)

	local rollAD=input.getNumber(18)
	local pitchWS=input.getNumber(19)
	local yawLR=input.getNumber(20)
	local altHoldAltitude=math.max(input.getNumber(21),0)
	local waypointX=input.getNumber(22)
	local waypointY=input.getNumber(23)

	local altHoldEnabled=input.getBool(1)
	local autopilotEnabled=input.getBool(2) and not(waypointX==0 and waypointY==0)
	local stabEnabled=input.getBool(3) -- stab=stabilizer

	-- Getting local angular speeds from the physics sensor
	local rotationMatrix=makeMatC(input.getNumber(4),input.getNumber(5),input.getNumber(6))
	local globalAngularSpeeds={input.getNumber(10),input.getNumber(11),input.getNumber(12)}
	local transposedMatrix=transposeMatrix(rotationMatrix)
	local localAngularSpeeds=rotate(transposedMatrix,globalAngularSpeeds)
	local angularSpeedFront=localAngularSpeeds[3]
	local angularSpeedRight=localAngularSpeeds[1]
	local angularSpeedUp=localAngularSpeeds[2]

	-- Stabilizer
	local stabCounter=stabUpDown(not stabEnabled,stabEnabled,0.02,0,1)
	-- Pitch stabilizer
	local tiltAdjustedStabilizerPitch=clamp(pitchWS*StabilizedPitchRoll+tiltFront*2,-0.2,0.2)
	local propertyAdjustedStabilizerPitch=(0.1+PitchTurnSpeed)*pitchWS -- This 0.1 is here to match the ZE airplane gyro (not the flight controller)
	local stabilizerPitch=lerp(propertyAdjustedStabilizerPitch,tiltAdjustedStabilizerPitch,stabCounter)
	-- Roll stabilizer
	local tiltAdjustedStabilizerRoll=clamp(-rollAD*StabilizedPitchRoll-tiltRight*2,-0.2,0.2)
	local propertyAdjustedStabilizerRoll=RollTurnSpeed*rollAD
	local stabilizerRoll=lerp(propertyAdjustedStabilizerRoll,tiltAdjustedStabilizerRoll,stabCounter) -- PID setpoint

	-- Autopilot and altHold
	local autoControl=altHoldEnabled or autopilotEnabled
	local deltaAltitude=altitudeDelta(altitude)
	local headingError=((compass+math.atan(gpsX-waypointX,gpsY-waypointY)/(math.pi*2)+1)%1-0.5)
	local switchHeadingError=(autopilotEnabled) and headingError or 0
	-- Autopilot (altHold) pitch
	local altHoldPIDSetpoint=(altHoldAltitude==0) and -pitchWS*0.3 or clamp(0.002*(altHoldAltitude-altitude),-0.3,0.3)
	local altHoldPIDEnabled=thresholdGate(tiltRight,-0.1,0.1) and autoControl
	local stabilizedAltHoldPitch=altHoldPID(altHoldPIDSetpoint,deltaAltitude,0.3,0.001,0,altHoldPIDEnabled)
	local tiltAdjustedPitch=math.abs(switchHeadingError)*0.6*lerp(0,1,math.abs(tiltRight)*4)
	local autopilotPitch=clamp(-stabilizedAltHoldPitch-tiltAdjustedPitch,-PitchTurnSpeed,PitchTurnSpeed)
	-- Autopilot roll
	local autopilotRoll=clamp(-tiltRight*2-switchHeadingError*0.5,-0.4,0.4)
	-- Autopilot yaw
	local autopilotYaw=clamp(headingError/(0.1*math.abs(headingError)+0.05)*lerp(1,0,math.abs(tiltRight)*4),-0.25,0.25)

	-- Pitch control
	local pitchPIDSetpoint=PitchTurnSpeed*pitchWS
	if autoControl then
		pitchPIDSetpoint=autopilotPitch
	elseif stabEnabled then
		pitchPIDSetpoint=stabilizerPitch
	end
	--local pitchPIDSetpoint=(autoControl) and autopilotPitch or PitchTurnSpeed*pitchWS
	local outputPitch=pitchPID(pitchPIDSetpoint,angularSpeedRight,PitchPIDSensitivity,PitchTrim,0.04,0.1)
	-- Roll control
	local rollPIDSetpoint=RollTurnSpeed*rollAD
	if autoControl then
		rollPIDSetpoint=autopilotRoll
	elseif stabEnabled then
		rollPIDSetpoint=stabilizerRoll
	end
	--local rollPIDSetpoint=(autoControl) and autopilotRoll or RollTurnSpeed*rollAD
	local outputRoll=-rollPID(rollPIDSetpoint,angularSpeedFront,RollPIDSensitivity,RollTrim,0.01,0)
	-- Yaw control
	local switchedYaw=(autopilotEnabled) and autopilotYaw or yawLR
	local yawPIDSetpoint=OldYawPIDSetpoint+0.02*(YawTurnSpeed*switchedYaw-OldYawPIDSetpoint)
	OldYawPIDSetpoint=yawPIDSetpoint
	local stabilizedYaw=yawPID(yawPIDSetpoint,angularSpeedUp,YawPIDSensitivity,0,0,true)
	local outputYaw=stabilizedYaw+YawTrim

	output.setNumber(1,outputPitch)
	output.setNumber(2,outputRoll)
	output.setNumber(3,outputYaw)
end
