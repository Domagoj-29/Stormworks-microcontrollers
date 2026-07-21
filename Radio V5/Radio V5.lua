-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

-- onDraw functions

local function propertyToColors(propertyName) -- Colors are stored as "255,255,255","0,0,0", etc.
	local colors = property.getText(propertyName)
	local tempTable = {}
	for color in colors:gmatch("%d+") do
		table.insert(tempTable, tonumber(color))
	end
	return tempTable
end
local function setColor(i, isHighlighted)
	isHighlighted = isHighlighted or false
	if isHighlighted and i == 0 then
		screen.setColor(255, 127, 0)
	elseif i == 0 then
		screen.setColor(UIRGB[1], UIRGB[2], UIRGB[3])
	elseif i == 1 then
		screen.setColor(0, 0, 0)
	end
end
-- Every character is stored as 4 hexadecimal numbers, with each bit representing one pixel (3x5 = 15, the last bit is ignored)
FontString = property.getText("Font 1/3") .. property.getText("Font 2/3") .. property.getText("Font 3/3")
CharacterTable = {}
for hexValue in FontString:gmatch("....") do
	table.insert(CharacterTable, tonumber(hexValue, 16))
end
local function drawText(x, y, text, size, isUpsideDown, width, horizontalAlign)
	size, isUpsideDown, width, horizontalAlign = size or 1, isUpsideDown or false, width or 0, horizontalAlign or -1
	text = (isUpsideDown) and text:reverse() or text
	text = text:upper()
	local length = text:len()
	if horizontalAlign == 0 then -- drawTextBox style alignment
		x = (x + width / 2) - (length * 4 * size / 2)
	elseif horizontalAlign == 1 then
		x = (x + width) - (length * 4 * size) + 1
	end
	for char in text:gmatch(".") do
		local key = char:byte() - 31 -- Convert ASCII value into a key for the character table
		if key >= 92 then	  -- For ASCIIs after the lowercase letters
			key = key - 26
		end
		local charValue = CharacterTable[key] or 65534 -- Default value draws a filled rectangle
		for i = 14, 0, -1 do
			local pixelX, pixelY = i % 3 * size, i // 3 * size
			if (charValue & 2 ^ (15 - i)) ~= 0 then
				if not isUpsideDown then
					screen.drawRectF(x + pixelX, y + pixelY, size, size)
				else
					screen.drawRectF(x + (2 - pixelX), y + (4 - pixelY), size, size)
				end
			end
		end
		x = x + 4 * size
	end
end
local function drawFrequencyArrow(x, y, isUpsideDown)
	local offsetY = (isUpsideDown) and 1 or 0
	screen.drawRectF(x + 1, y + offsetY, 1, 1)
	screen.drawRectF(x, y + 1 - offsetY, 3, 1)
end
local function clamp(value, min, max)
	return math.max(min, math.min(value, max))
end
local function truncate(number)
	if number > 0 then
		return math.floor(number)
	else
		return math.ceil(number)
	end
end
local function round(x)
	return math.floor(x + 0.5)
end
local function dynamicRounding(number)
	local min = -10 ^ (4 + WidthScale) + 1
	local max = 10 ^ (5 + WidthScale) - 1
	local clampedNumber = clamp(number, min, max)
	local truncatedNumber = truncate(clampedNumber)
	local numberLength = string.len(truncatedNumber)
	local decimalPlaces = math.max(0, 4 + round(WidthScale) - numberLength) -- WidthScale NEEDS to get rounded, a crash will happen otherwise
	local roundedNumber = string.format("%." .. decimalPlaces .. "f", clampedNumber)

	return roundedNumber
end
local function drawInvisibleRectangles()
	screen.drawRectF(1, 1, w - 2, 6)
	screen.drawRectF(1, 7 + ScrollLimit - 1, w - 2, h - (7 + ScrollLimit - 1))
end
local function boolToString(value)
	if value then
		return "ON"
	else
		return "OFF"
	end
end
local function drawReturnArrow(x, y, width)
	screen.drawRectF(x, y + 2, width, 1)
	screen.drawRectF(x + 1, y + 1, 1, 3)
	screen.drawRectF(x + 2, y, 1, 1)
	screen.drawRectF(x + 2, y + 4, 1, 1)
end
local function setSignalColor(signalStrength)
	if signalStrength <= 0.25 then
		screen.setColor(255, 0, 0)
	elseif signalStrength <= 0.5 then
		screen.setColor(250, 70, 22)
	elseif signalStrength <= 0.75 then
		screen.setColor(255, 255, 0)
	else
		screen.setColor(8, 255, 8)
	end
end
local function drawSignalStrengthIndicator(signalStrength, x, y, width, NotVideoMode)
	if NotVideoMode then
		screen.setColor(35, 35, 35)
		for i = 4, 1, -1 do
			local offsetX = (4 - i) * (2 + WidthScale)
			screen.drawRectF(x - offsetX, y, width, i)
		end
	end
	if signalStrength > 0 then
		setSignalColor(signalStrength)
		for i = round(signalStrength * 4), 1, -1 do
			local offsetX = (4 - i) * (2 + WidthScale)
			screen.drawRectF(x - offsetX, y, width, i)
		end
	end
end
local function drawBackgroundDetails()
	screen.setColor(25, 25, 25)
	screen.drawRectF(0, 0, w, 1)
	screen.drawRectF(0, 0, 1, h)
	screen.drawRectF(0, h - 1, w, 1)
	screen.setColor(15, 15, 15)
	screen.drawRectF(w - 1, 0, 1, h)
end

-- onTick functions

local function textWidth(chars)
	local gapCharW, charW = 4, 3
	return gapCharW * (chars - 1) + charW
end
local function getCoordinates()
	local charH = 5
	return
	{
		Return = { X = 1, Y = 1, Width = 5 + WidthScale, Height = charH },
		SignalStrength = { X = w - 2 - WidthScale, Y = 1, Width = 1 + WidthScale, Height = 4 }, -- Rightmost signalStrength rectangle

		Frequency = { X = cx - 6, Y = cy - 14, Width = textWidth(3), Height = charH },
		PTT = { X = cx - 6, Y = cy - 8 + HeightScale, Width = textWidth(3), Height = charH },
		Data = { X = cx - 8, Y = cy - 2 + HeightScale * 2, Width = textWidth(4), Height = charH },
		Mute = { X = cx - 8, Y = cy + 4 + HeightScale * 3, Width = textWidth(4), Height = charH },
		Version = { X = w - 9, Y = h - 6 },

		Scan = { X = cx - 8, Y = h - 8, Width = textWidth(4), Height = charH},
		ArrowUp = { X = cx + 10, Y = cy - 6, Width = 3, Height = 2 }, -- Rightmost arrow value
		ArrowDown = { X = cx + 10, Y = cy + 3, Width = 3, Height = 2 },
		FrequencyValue = { X = cx - 14, Y = cy - 3 }, -- Leftmost frequency digit value

		Channel = { X = 1, Y = 7, Width = textWidth(2), Height = charH},
		ChangeData = { X = cx - 7, Y = 1, Width = textWidth(3), Height = charH },
		Up = { X = 0, Y = 0, Width = w, Height = cy - 2 },
		Down = { X = 0, Y = cy + 1, Width = w, Height = cy - 1 }
	}
end
local function touchRectF(inputX, inputY, x, y, rectW, rectH)
	return
		inputX >= x and inputY >= y and
		inputX <= x + rectW - 1 and inputY <= y + rectH - 1
end
local function createPulse()
	local oldVariable = false
	return function(variable)
		local risingEdge = not oldVariable and variable
		oldVariable = variable
		return risingEdge
	end
end
local function createToggle()
	local oldVariable = false
	local toggleVariable = false
	return function(variable)
		if variable and not oldVariable then
			toggleVariable = not toggleVariable
		end
		oldVariable = variable
		return toggleVariable
	end
end
local function createSRLatch()
	local output = false
	return function(set, reset)
		if set and reset then
			output = false
		elseif set then
			output = true
		elseif reset then
			output = false
		end
		return output
	end
end
local function createDelayedWrappedCounter(delayTicks)
	local timer, counter = 0, 0
	return function(down, up, min, max, overrideSignal, overrideValue)
		if up or down then
			timer = timer + 1
			if timer > delayTicks then
				counter = up and counter + 1 or counter
				counter = down and counter - 1 or counter
				timer = 0
			end
		else
			timer = delayTicks
		end
		if overrideSignal then
			counter = overrideValue
		end
		counter = (counter == min - 1) and max or counter
		counter = (counter == max + 1) and min or counter
		return counter
	end
end
local function createCapacitor()
	local oldCharge=false
	local chargeCounter=0
	local dischargeCounter=nil
	return function(charge,chargeTicks,dischargeTicks)
		if dischargeCounter==nil then
			dischargeCounter=dischargeTicks
		end

		if charge then
			chargeCounter=math.min(chargeCounter+1,chargeTicks)
		else
			chargeCounter=0
		end

		if oldCharge and not charge then
			dischargeCounter=0
		end

		if not charge and dischargeCounter<dischargeTicks then
			dischargeCounter=dischargeCounter+1
		end

		oldCharge=charge

		local storedCharge=(dischargeCounter>0 and dischargeCounter<dischargeTicks) or (chargeCounter==chargeTicks and charge)
		return storedCharge
	end
end
local function getDigit(value, digit)
	return math.floor(value / (10 ^ (digit - 1))) % 10
end
local function createCounter(startValue)
	local counter = startValue
	return function(down, up, increment, min, max, reset)
		if down then
			counter = counter - increment
		end
		if up then
			counter = counter + increment
		end
		if reset then
			counter = 0
		end
		counter = clamp(counter, min, max)
		return counter
	end
end

local returnPulse = createPulse()
local pulseUp, pulseDown = createPulse(), createPulse()
local dataModePulse = createPulse()
local muteToToggle = createToggle()
local pulseScan = createPulse()
local scanSRLatch = createSRLatch()
local pulseScanSR = createPulse()
local scanCounter = createDelayedWrappedCounter(5)
FunctionTable = {}
for i = 1, 7 do
	FunctionTable[i] =
	{
		DigitCounter = createDelayedWrappedCounter(15),
		IncrementCapacitor = createCapacitor(),
		DecrementCapacitor = createCapacitor()
	}
end
local numberDataCounterSP, logicDataCounterSP = createCounter(0), createCounter(0)
local numberDataCounterY, logicDataCounterY = createCounter(0), createCounter(0)

DataChannel = {}
for i = 1, 32 do
	DataChannel[i] = {Number = 0, Logic = false}
end
Coords = {}
LastDataMode = "NumberData"
ScreenMode = "Menu" -- "Menu", "Frequency", "NumberData", "LogicData", "VideoData"
ScanSR = false
StartFrequency = 0
MaxFreqDigits, OffsetX = 0, 0
DataPressedCheck = false
FreqCounter = {}
FrequencySet = 0
NumberDataScrollY, LogicDataScrollY = 0, 0
w, h = 0, 0

UIRGB = propertyToColors("UI color")

SkipVideoData = property.getBool("Skip video data")

function onTick()
	local inputX, inputY = input.getNumber(3), input.getNumber(4)
	SignalStrength = input.getNumber(5)

	local updateFirstHalf = input.getBool(1)
	local isPressed = input.getBool(2)
	ExternalPTT = input.getBool(3)

	for i = 17, 32 do
		-- Input channels stay the same, the table index changes
		local j = (updateFirstHalf) and i - 16 or i
		DataChannel[j].Number = input.getNumber(i)
		DataChannel[j].Logic = input.getBool(i)
	end

	cx, cy = w / 2, h / 2
	WidthScale, HeightScale = w / 32 - 1, h / 32 - 1
	Coords = getCoordinates() -- Coords stores static coordinates, scrolling is added in onDraw()

	local returnButton = isPressed and touchRectF(inputX, inputY, Coords.Return.X - 1, Coords.Return.Y - 1, Coords.Return.Width + 2, Coords.Return.Height + 2 )
	if ScreenMode ~= "Menu" and returnPulse(returnButton) then
		LastDataMode = (ScreenMode ~= "Frequency") and ScreenMode or LastDataMode
		ScreenMode = "Menu"
	end

	local up = isPressed and touchRectF(inputX, inputY, Coords.Up.X, Coords.Up.Y, Coords.Up.Width, Coords.Up.Height)
	local down = isPressed and touchRectF(inputX, inputY, Coords.Down.X, Coords.Down.Y, Coords.Down.Width, Coords.Down.Height)
	local upPulse, downPulse = pulseUp(up), pulseDown(down)
	if not isPressed then
		DataPressedCheck = false
	end
	local changeDataMode = isPressed and touchRectF(inputX, inputY, Coords.ChangeData.X, Coords.ChangeData.Y, Coords.ChangeData.Width, Coords.ChangeData.Height)
	local notAnyButton = not (returnButton or DataPressedCheck or changeDataMode)
	local screenIsNarrow = w == 32
	local maxSetpoint = (screenIsNarrow) and 7 or 3
	ScrollLimit = (screenIsNarrow) and 24 or 56
	local changeDataModePulse = dataModePulse(changeDataMode)

	if ScreenMode == "Menu" then
		local frequencyPressed = isPressed and touchRectF(inputX, inputY, Coords.Frequency.X, Coords.Frequency.Y, Coords.Frequency.Width, Coords.Frequency.Height)
		PressedPTT = isPressed and touchRectF(inputX, inputY, Coords.PTT.X, Coords.PTT.Y, Coords.PTT.Width, Coords.PTT.Height)
		local dataPressed = isPressed and touchRectF(inputX, inputY, Coords.Data.X, Coords.Data.Y, Coords.Data.Width, Coords.Data.Height)
		local mutePressed = isPressed and touchRectF(inputX, inputY, Coords.Mute.X, Coords.Mute.Y, Coords.Mute.Width, Coords.Mute.Height)

		if frequencyPressed then
			ScreenMode = "Frequency"
		elseif dataPressed then
			DataPressedCheck = true
			ScreenMode = LastDataMode
		end
		MuteToggle = muteToToggle(mutePressed)
	elseif ScreenMode == "Frequency" then
		local scanPressed = isPressed and touchRectF(inputX, inputY, Coords.Scan.X, Coords.Scan.Y, Coords.Scan.Width, Coords.Scan.Height)
		local scanPulse = pulseScan(scanPressed)
		local signalFound = SignalStrength > 0
		ScanSR = scanSRLatch(scanPulse and not ScanSR, (scanPulse and ScanSR) or signalFound or FrequencySet == 10 ^ MaxFreqDigits - 1)
		local scanSRPulse = pulseScanSR(ScanSR)
		if scanSRPulse then
			StartFrequency = FrequencySet
		end
		local scanFrequency = StartFrequency + scanCounter(false, ScanSR, 0, (10 ^ MaxFreqDigits - 1) - StartFrequency, not ScanSR, 0)

		MaxFreqDigits, OffsetX = 7, 0
		if screenIsNarrow then
			MaxFreqDigits = 5
			OffsetX = 4
		end
		FrequencySet = 0
		for i = 1, MaxFreqDigits do
			local j = i - 1
			local incrementPressed = isPressed and touchRectF(inputX, inputY,
					Coords.ArrowUp.X - j * 4 - OffsetX, Coords.ArrowUp.Y - 1, Coords.ArrowUp.Width, Coords.ArrowUp.Height + 2)
			local decrementPressed = isPressed and touchRectF(inputX, inputY,
					Coords.ArrowDown.X - j * 4 - OffsetX, Coords.ArrowDown.Y - 1, Coords.ArrowDown.Width, Coords.ArrowDown.Height + 2)
			FreqCounter[i] =
			{
				Increment = FunctionTable[i].IncrementCapacitor(incrementPressed, 1, 15),
				Decrement = FunctionTable[i].DecrementCapacitor(decrementPressed, 1, 15),
				Digit = FunctionTable[i].DigitCounter(decrementPressed, incrementPressed, 0, 9, ScanSR, getDigit(scanFrequency, i))
			}
			FrequencySet = FrequencySet + FreqCounter[i].Digit * 10 ^ j
		end
	elseif ScreenMode == "NumberData" then
		local setpoint = numberDataCounterSP(upPulse and notAnyButton, downPulse and notAnyButton, 1, 0, maxSetpoint, false) * ScrollLimit
		NumberDataScrollY = numberDataCounterY(NumberDataScrollY > setpoint, NumberDataScrollY < setpoint, 1, 0, maxSetpoint * ScrollLimit, false)

		if changeDataModePulse then
			ScreenMode = "LogicData"
		end
	elseif ScreenMode == "LogicData" then
		local setpoint = logicDataCounterSP(upPulse and notAnyButton, downPulse and notAnyButton, 1, 0, maxSetpoint, false) * ScrollLimit
		LogicDataScrollY = logicDataCounterY(LogicDataScrollY > setpoint, LogicDataScrollY < setpoint, 1, 0, maxSetpoint * ScrollLimit, false)

		if changeDataModePulse and SkipVideoData then
			ScreenMode = "NumberData"
		elseif changeDataModePulse then
			ScreenMode = "VideoData"
		end
	elseif ScreenMode == "VideoData" then
		if changeDataModePulse then
			ScreenMode = "NumberData"
		end
	end

	output.setNumber(1, FrequencySet)

	output.setBool(1, PressedPTT or ExternalPTT)
	output.setBool(2, MuteToggle)
	output.setBool(3, ScreenMode == "VideoData")
end

function onDraw()
	w, h = screen.getWidth(), screen.getHeight()

	if ScreenMode~="VideoData" then
		screen.setColor(20, 20, 20)
		screen.drawClear()
	end

	local charH = 5
	local textGap = clamp(h / 32, 1, 2)

	if ScreenMode == "Menu" then
		for i = 1, 0, -1 do
			setColor(i)
			drawText(Coords.Frequency.X + i, Coords.Frequency.Y, "FRQ")
			drawText(Coords.Data.X + i, Coords.Data.Y, "DATA")
			drawText(Coords.Version.X + i, Coords.Version.Y, "V5")
			setColor(i, PressedPTT or ExternalPTT)
			drawText(Coords.PTT.X + i, Coords.PTT.Y, "PTT")
			setColor(i, MuteToggle)
			drawText(Coords.Mute.X + i, Coords.Mute.Y, "MUTE")
		end
	elseif ScreenMode == "Frequency" then
		for i = 1, 0, -1 do
			for j = 1, MaxFreqDigits do
				setColor(i)
				drawText(Coords.FrequencyValue.X + i, Coords.FrequencyValue.Y, string.format("%0" .. MaxFreqDigits .. "d", FrequencySet), 1, false, textWidth(7), 0)
				setColor(i, ScanSR)
				drawText(Coords.Scan.X + i, Coords.Scan.Y, "SCAN")
				local k = j - 1
				setColor(i, FreqCounter[j].Increment and not ScanSR)
				drawFrequencyArrow(Coords.ArrowUp.X + i - k * 4 - OffsetX, Coords.ArrowUp.Y, false)
				setColor(i, FreqCounter[j].Decrement and not ScanSR)
				drawFrequencyArrow(Coords.ArrowDown.X + i - k * 4 - OffsetX, Coords.ArrowDown.Y, true)
			end
		end
	elseif ScreenMode == "NumberData" then
		for i = 1, 0, -1 do
			for j = 1, 32 do
				local k = j - 1
				setColor(i)
				drawText(Coords.Channel.X + i, Coords.Channel.Y + (k * (charH + textGap)) - NumberDataScrollY, tostring(j) .. ":")
				drawText(Coords.Channel.X + i, Coords.Channel.Y + (k * (charH + textGap)) - NumberDataScrollY, dynamicRounding(DataChannel[j].Number), 1, false, w - 3, 1)
			end
		end
		screen.setColor(20, 20, 20)
		drawInvisibleRectangles()
		for i = 1, 0, -1 do
			setColor(i)
			drawText(Coords.ChangeData.X + i, Coords.ChangeData.Y, "NUM")
		end
	elseif ScreenMode == "LogicData" then
		for i = 1, 0, -1 do
			for j = 1, 32 do
				local k = j - 1
				setColor(i)
				drawText(Coords.Channel.X + i, Coords.Channel.Y + (k * (charH + textGap)) - LogicDataScrollY, tostring(j) .. ":")
				drawText(Coords.Channel.X + i, Coords.Channel.Y + (k * (charH + textGap)) - LogicDataScrollY, boolToString(DataChannel[j].Logic), 1, false, w - 3, 1)
			end
		end
		screen.setColor(20, 20, 20)
		drawInvisibleRectangles()
		for i = 1, 0, -1 do
			setColor(i)
			drawText(Coords.ChangeData.X + i, Coords.ChangeData.Y, "LOG")
		end
	elseif ScreenMode == "VideoData" then
		for i = 1, 0, -1 do
			setColor(i)
			drawText(Coords.ChangeData.X + i, Coords.ChangeData.Y, "VID")
		end
	end

	for i = 1, 0, -1 do
		if ScreenMode ~= "Menu" then
			setColor(i)
			drawReturnArrow(Coords.Return.X + i, Coords.Return.Y, Coords.Return.Width)
		end
	end
	drawSignalStrengthIndicator(SignalStrength, Coords.SignalStrength.X, Coords.SignalStrength.Y, Coords.SignalStrength.Width, ScreenMode ~= "VideoData")
	if ScreenMode ~= "VideoData" then
		drawBackgroundDetails()
	end
end
