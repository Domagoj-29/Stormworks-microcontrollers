-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

-- onDraw functions

local function drawArrow(value,maxValue,x,y,radius)
	local radians=math.pi+(value/maxValue)*math.pi
	local arrowX=x+radius*math.cos(radians)
	local arrowY=y+radius*math.sin(radians)
	screen.drawLine(x,y,arrowX,arrowY)
end

-- onTick functions

--[[local function createDelta()
	local oldVariable=0
	return function(variable)
		local delta=variable-oldVariable
		oldVariable=variable
		return delta
	end
end]]
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
local function createPulse()
	local k=0
	return function(variable)
		if not variable then
			k=0
		else
			k=k+1
		end
		return k==1
	end
end
local function thresholdGate(value,low,high)
	return (value>=low and value<=high)
end
local function linearInterpolation(x,x1,x2,y1,y2)
	return y1+((x-x1)*(y2-y1)/(x2-x1))
end
--[[
function automaticGearbox(shifterAxis,RPS,downshiftRPS,upshiftRPS,deltaRPS)
	local downShift=downShiftPulse(thresholdGate(shifterAxis,-1,-0.5))
	local upShift=upShiftPulse(thresholdGate(shifterAxis,0.5,1))
	local manualShifterValue=shifterUpDown(downShift,upShift,1,-1,1)
	if manualShifterValue==1 then
		local automaticShifterValue=automaticUpDown(automaticDownshiftPulse(RPS<downshiftRPS and deltaRPS<0),automaticUpshiftPulse(RPS>upshiftRPS),1,1,4)
		return automaticShifterValue
	else
		return manualShifterValue
	end
end]]

local function manualGearbox(shifterAxis)
	local downShift=DownShiftPulse(thresholdGate(shifterAxis,-1,-0.5))
	local upShift=UpShiftPulse(thresholdGate(shifterAxis,0.5,1))
	local manualShifterValue=ShifterUpDown(downShift,upShift,1,-1,4)
	return manualShifterValue
end
local function gearPositionToText(gearPosition)
	if thresholdGate(gearPosition,-1,-1) then
		return "R"
	elseif thresholdGate(gearPosition,0,0) then
		return "P"
	else
		return gearPosition
	end
end

DownShiftPulse=createPulse()
UpShiftPulse=createPulse()
--local automaticDownshiftPulse=createPulse()
--local automaticUpshiftPulse=createPulse()
ShifterUpDown=createUpDown()
--local automaticUpDown=createUpDown()
--local rpsDelta=createDelta()

--DownshiftRPS=property.getNumber("Downshift RPS")
--UpshiftRPS=property.getNumber("Upshift RPS")
MaxFuel=property.getNumber("Max fuel")
function onTick()
	local shifter=input.getNumber(4)
	EngineTemperature=input.getNumber(5)
	Speed=input.getNumber(6)*3.6
	RPS=input.getNumber(7)
	BatteryCharge=input.getNumber(8)
	Fuel=input.getNumber(9)+input.getNumber(10)

	CruiseControlButton=input.getBool(3)
	LaneHoldButton=input.getBool(4)

	LeftBlinker=input.getBool(7)
	RightBlinker=input.getBool(8)

	--local deltaRPS=rpsDelta(RPS)
	--local gearPosition=automaticGearbox(shifter,RPS,DownshiftRPS,UpshiftRPS,deltaRPS)
	local gearPosition=manualGearbox(shifter)
	GearText=gearPositionToText(gearPosition)
	output.setBool(1,thresholdGate(gearPosition,-1,-1))
	output.setBool(2,thresholdGate(gearPosition,0,0))
	output.setBool(3,thresholdGate(gearPosition,1,1) or thresholdGate(gearPosition,-1,-1))
	output.setBool(4,thresholdGate(gearPosition,2,2))
	output.setBool(5,thresholdGate(gearPosition,3,3))
	-- 4th gear does not need to be output, the default gear ratio is used
end
function onDraw()
	-- Background color
	screen.setColor(5,5,5)
	screen.drawClear()
	-- Inner, background circle (this needs to be here, because otherwise it will draw over the shading for dial text)
	screen.setColor(15,15,15)
	screen.drawCircleF(14,15,14)
	screen.drawCircleF(81,15,14)
	-- Shading
	screen.setColor(0,0,0)
	-- R (shading)
	screen.drawLine(10,8,10,13)
	screen.drawLine(12,8,13,8)
	screen.drawRectF(12,9,1,1)
	screen.drawRectF(11,10,1,1)
	screen.drawLine(12,11,12,13)
	-- P (shading)
	screen.drawRect(14,8,2,2)
	screen.drawLine(14,11,14,13)
	-- S (shading)
	screen.drawLine(20,8,17,8)
	screen.drawLine(18,9,18,11)
	screen.drawLine(19,10,21,10)
	screen.drawLine(20,11,20,13)
	screen.drawLine(19,12,17,12)
	-- K (shading)
	screen.drawLine(77,8,77,13)
	screen.drawRectF(78,10,1,1)
	screen.drawLine(79,8,79,10)
	screen.drawLine(79,11,79,13)
	-- P (shading)
	screen.drawRect(81,8,2,2)
	screen.drawLine(81,11,81,13)
	-- H (shading)
	screen.drawLine(85,8,85,13)
	screen.drawRectF(86,10,1,1)
	screen.drawLine(87,8,87,13)
	-- Fuel symbol (shading)
	screen.drawRect(30,3,4,3)
	screen.drawLine(35,4,35,7)
	screen.drawRectF(30,7,5,5)
	screen.drawLine(29,11,36,11)
	-- Battery symbol (shading)
	screen.drawRectF(63,4,1,1)
	screen.drawRectF(66,4,1,1)
	screen.drawRect(62,5,5,4)
	-- Cruise Control symbol (shading)
	if CruiseControlButton then
		screen.drawCircle(41,20,3)
		screen.drawLine(41,20,39,18)
	end
	-- Lane hold symbol (shading)
	if LaneHoldButton then
		screen.drawLine(53,23,54,16)
		screen.drawLine(56,17,56,20)
		screen.drawLine(56,21,56,24)
		screen.drawLine(59,23,58,16)
	end
	-- Engine overheating symbol (shading)
	if EngineTemperature>85 then
		screen.drawLine(48,17,48,22)
		screen.drawRectF(49,18,1,1)
		screen.drawRectF(49,20,1,1)
		screen.drawRectF(47,22,3,2)
	end
	-- Fuel gauge (shading)
	screen.drawLine(38,1,38,14)

	screen.drawRectF(39,1,2,1)
	screen.drawRectF(39,4,1,1)
	screen.drawRectF(39,7,2,1)
	screen.drawRectF(39,10,1,1)
	screen.drawRectF(39,13,2,1)

	screen.drawLine(44,1,44,14)

	screen.drawRectF(42,1,2,1)
	screen.drawRectF(43,4,1,1)
	screen.drawRectF(42,7,2,1)
	screen.drawRectF(43,10,1,1)
	screen.drawRectF(42,13,2,1)
	-- Battery Gauge (shading)
	screen.drawLine(53,1,53,14)

	screen.drawRectF(54,1,2,1)
	screen.drawRectF(54,4,1,1)
	screen.drawRectF(54,7,2,1)
	screen.drawRectF(54,10,1,1)
	screen.drawRectF(54,13,2,1)

	screen.drawLine(59,1,59,14)

	screen.drawRectF(57,1,2,1)
	screen.drawRectF(58,4,1,1)
	screen.drawRectF(57,7,2,1)
	screen.drawRectF(58,10,1,1)
	screen.drawRectF(57,13,2,1)
	-- Gear position text (shading)
	screen.drawText(47,1,GearText)
	-- RPS dial text (shading)
	screen.drawTextBox(11,18,10,5,string.format("%.0f",math.max(0,math.min(RPS,99))),0)
	-- KPH dial text (shading)
	screen.drawTextBox(75,18,15,5,string.format("%.0f",math.max(0,math.min(math.abs(Speed),999))),0)
	-- Left blinker
	if LeftBlinker then
		screen.drawLine(30,19,32,17)
		screen.drawLine(29,20,35,20)
		screen.drawLine(30,21,32,23)
	end
	-- Right blinker
	if RightBlinker then
		screen.drawLine(65,18,67,20)
		screen.drawLine(62,20,68,20)
		screen.drawLine(65,22,67,20)
	end

	-- Outer circle
	screen.drawCircle(14,15,14)
	screen.drawCircle(81,15,14)
	-- Circle around arrow center
	screen.setColor(100,0,0)
	screen.drawCircle(14,15,1)
	screen.drawCircle(81,15,1)
	-- Arrow
	screen.setColor(255,0,0)
	drawArrow(RPS,10,14,15,14)
	drawArrow(math.abs(Speed),130,81,15,14)
	-- Dial graduations
	screen.setColor(120,120,120)
	screen.drawLine(1,15,3,15)
	screen.drawLine(68,15,70,15)

	screen.drawLine(5,6,7,8)
	screen.drawLine(72,6,74,8)

	screen.drawLine(14,2,14,4)
	screen.drawLine(81,2,81,4)

	screen.drawLine(23,6,21,8)
	screen.drawLine(90,6,88,8)

	screen.drawLine(27,15,25,15)
	screen.drawLine(94,15,92,15)
	-- R
	screen.drawLine(9,8,9,13)
	screen.drawLine(10,8,12,8)
	screen.drawRectF(11,9,1,1)
	screen.drawRectF(10,10,1,1)
	screen.drawLine(11,11,11,13)
	-- P
	screen.drawRect(13,8,2,2)
	screen.drawLine(13,11,13,13)
	-- S
	screen.drawLine(19,8,16,8)
	screen.drawLine(17,9,17,11)
	screen.drawLine(18,10,20,10)
	screen.drawLine(19,11,19,13)
	screen.drawLine(18,12,16,12)

	-- K
	screen.drawLine(76,8,76,13)
	screen.drawRectF(77,10,1,1)
	screen.drawLine(78,8,78,10)
	screen.drawLine(78,11,78,13)
	-- P
	screen.drawRect(80,8,2,2)
	screen.drawLine(80,11,80,13)
	-- H
	screen.drawLine(84,8,84,13)
	screen.drawRectF(85,10,1,1)
	screen.drawLine(86,8,86,13)
	-- Fuel symbol
	if Fuel/MaxFuel<0.15 then
		screen.setColor(255,191,0)
	else
		screen.setColor(255,255,255)
	end
	screen.drawRect(29,3,4,3)
	screen.drawLine(34,4,34,7)
	screen.drawRectF(29,7,5,5)
	screen.drawLine(28,11,35,11)
	-- Battery symbol
	if BatteryCharge<0.3 then
		screen.setColor(255,191,0)
	else
		screen.setColor(255,255,255)
	end
	screen.drawRectF(62,4,1,1)
	screen.drawRectF(65,4,1,1)
	screen.drawRect(61,5,5,4)
	-- Cruise Control symbol
	if CruiseControlButton then
		screen.setColor(255,255,255)
		screen.drawCircle(40,20,3)
		screen.drawLine(40,20,38,18)
	end
	-- Lane hold symbol
	if LaneHoldButton then
		screen.setColor(255,255,255)
		screen.drawLine(52,23,53,16)
		screen.drawLine(55,17,55,20)
		screen.drawLine(55,21,55,24)
		screen.drawLine(58,23,57,16)
	end
	-- Engine overheating symbol
	if EngineTemperature>85 then
		screen.setColor(255,191,0)
		screen.drawLine(47,17,47,22)
		screen.drawRectF(48,18,1,1)
		screen.drawRectF(48,20,1,1)
		screen.drawRectF(46,22,3,2)
	end
	-- Fuel gauge
	screen.setColor(255,255,255)
	screen.drawLine(37,1,37,14)

	screen.drawRectF(38,1,2,1)
	screen.drawRectF(38,4,1,1)
	screen.drawRectF(38,7,2,1)
	screen.drawRectF(38,10,1,1)
	screen.drawRectF(38,13,2,1)

	screen.drawLine(43,1,43,14)

	screen.drawRectF(41,1,2,1)
	screen.drawRectF(42,4,1,1)
	screen.drawRectF(41,7,2,1)
	screen.drawRectF(42,10,1,1)
	screen.drawRectF(41,13,2,1)
	-- Battery Gauge
	screen.drawLine(52,1,52,14)

	screen.drawRectF(53,1,2,1)
	screen.drawRectF(53,4,1,1)
	screen.drawRectF(53,7,2,1)
	screen.drawRectF(53,10,1,1)
	screen.drawRectF(53,13,2,1)

	screen.drawLine(58,1,58,14)

	screen.drawRectF(56,1,2,1)
	screen.drawRectF(57,4,1,1)
	screen.drawRectF(56,7,2,1)
	screen.drawRectF(57,10,1,1)
	screen.drawRectF(56,13,2,1)
	-- Gear position text
	screen.drawText(46,1,GearText)
	-- RPS dial text
	screen.drawTextBox(10,18,10,5,string.format("%.0f",math.max(0,math.min(RPS,99))),0)
	-- KPH dial text
	screen.drawTextBox(74,18,15,5,string.format("%.0f",math.max(0,math.min(math.abs(Speed),999))),0)
	-- Fuel Gauge Line
	screen.setColor(255,0,0)
	screen.drawRectF(38,linearInterpolation(Fuel,0,MaxFuel,13,1),5,1)
	-- Battery Gauge Line
	screen.drawRectF(53,linearInterpolation(BatteryCharge,0,1,13,1),5,1)
	-- Left blinker
	if LeftBlinker then
		screen.setColor(8,255,8)
		screen.drawLine(29,19,31,17)
		screen.drawLine(28,20,34,20)
		screen.drawLine(29,21,31,23)
	end
	-- Right blinker
	if RightBlinker then
		screen.setColor(8,255,8)
		screen.drawLine(64,18,66,20)
		screen.drawLine(61,20,67,20)
		screen.drawLine(64,22,66,20)
	end
end
