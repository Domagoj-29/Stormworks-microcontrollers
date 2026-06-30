-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

-- onDraw functions

function propertyToColors(propertyName) -- Colors are stored as "255,255,255","0,0,0", etc.
	colors = property.getText(propertyName)
	tempTable = {}
	for color in colors:gmatch("%d+") do
		table.insert(tempTable, tonumber(color))
	end
	return tempTable
end
-- Every character is stored as 4 hexadecimal numbers, with each bit representing one pixel (3x5 = 15, the last bit is ignored)
FontString = property.getText("1") .. property.getText("2") .. property.getText("3")
CharacterTable = {}
for hexValue in FontString:gmatch("....") do
	table.insert(CharacterTable, tonumber(hexValue, 16))
end
function drawText(x, y, text, size, isUpsideDown, width, horizontalAlign)
	size, isUpsideDown, width, horizontalAlign = size or 1, isUpsideDown or false, width or 0, horizontalAlign or -1
	text = (isUpsideDown) and text:reverse() or text
	text = text:upper()
	length = text:len()
	if horizontalAlign == 0 then -- drawTextBox style alignment
		x = (x + width / 2) - (length * 4 * size / 2)
	elseif horizontalAlign == 1 then
		x = (x + width) - (length * 4 * size) + 1
	end
	for char in text:gmatch(".") do
		key = char:byte() - 31 -- Convert ASCII value into a key for the character table
		if key >= 92 then	  -- For ASCIIs after the lowercase letters
			key = key - 26
		end
		charValue = CharacterTable[key] or 65534 -- Default value draws a filled rectangle
		for i = 14, 0, -1 do
			pixelX, pixelY = i % 3 * size, i // 3 * size
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
function round(x)
	return math.floor(x + 0.5)
end
function setTargetColor(i, mass, alpha)
	roundedMass, MassTable = round(mass), {[25] = {255, 170, 0}, [500] = {0, 85, 255}, [2500] = {150, 0, 255}, [60500] = {255, 0, 0}} -- player/NPC, shark, whale and megalodon
	if i == 1 then
		screen.setColor(0, 0, 0)
	else
		color = MassTable[roundedMass] or {255, 0, 0}
		screen.setColor(color[1], color[2], color[3], alpha)
	end
end
function drawTarget(target)
	screenX, screenY = map.mapToScreen(StoredX, StoredY, Zoom, w, h, target.X, target.Y)
	alpha = math.max(50, target.Time * 255)

	alignX, offsetX = (screenX < cx) and 1 or -1, 9
	offsetY1, offsetY2 = (screenY < cy) and -3 or 6, (screenY < cy) and -10 or 13
	textSpace = (string.len(string.format("%.0f", target.Bearing))) * 4

	for i = 1, 0, -1 do
		targetDataX = (screenX - offsetX) + textSpace + i
		bearingRightX = screenX + 15 + i
		bearingY = screenY - offsetY2

		setTargetColor(i, target.Mass, alpha)
		if target.Toggle then
			drawText(targetDataX - textSpace, screenY - offsetY1, string.format("%.1f", target.Distance), 1, false, 20, alignX)
			drawText(targetDataX - textSpace, bearingY, string.format("%.0f", target.Bearing), 1, false, 20, alignX)
			if alignX == -1 then
				-- Degree symbol is manually drawn with squares, because drawCircle has some weird aliasing with the alpha channel.
				screen.drawRectF(targetDataX, bearingY, 1, 1)
				screen.drawRectF(targetDataX + 2, bearingY, 1, 1)
				screen.drawRectF(targetDataX + 1, bearingY - 1, 1, 1)
				screen.drawRectF(targetDataX + 1, bearingY + 1, 1, 1)
				--screen.drawCircle((screenX - offsetX) + textSpace + 1 + i, screenY - offsetY2, 1)
			else
				screen.drawRectF(bearingRightX, bearingY, 1, 1)
				screen.drawRectF(bearingRightX + 2, bearingY, 1, 1)
				screen.drawRectF(bearingRightX + 1, bearingY - 1, 1, 1)
				screen.drawRectF(bearingRightX + 1, bearingY + 1, 1, 1)
				--screen.drawCircle(screenX + 15 + i, screenY - offsetY2, 1)
			end
		end
		screen.drawRectF(screenX,screenY,2,2)
	end
end
function rotatePoint(x, y, angle)
	return x * math.cos(angle) - y * math.sin(angle), x * math.sin(angle) + y * math.cos(angle)
end
function drawTrianglePointer(x, y, heading)
	angle = math.rad(heading)
	tipX, tipY = rotatePoint(0, -5, angle)
	bottomLeftX, bottomLeftY = rotatePoint(-3, 3, angle)
	bottomRightX, bottomRightY = rotatePoint(3, 3, angle)
	screen.drawTriangleF(x + tipX, y + tipY, x + bottomLeftX, y + bottomLeftY, x + bottomRightX, y + bottomRightY)
end
function drawCompassOverlay(compassDegrees, shadingOffset, enabled)
	degreeArray, directionArray =
		{ 22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5, 360 },
		{ "N", "NE", "E", "SE", "S", "SW", "W", "NW", "N" }
	if enabled then
		for i = 1, 9 do
			if compassDegrees <= degreeArray[i] then
				drawText(Coords.Compass.X + shadingOffset, Coords.Compass.Y, directionArray[i], 1, false, Coords.Compass.Width, 0)
				break
			end
		end
	end
end
function drawMinus(x, y)
	screen.drawRectF(x, y + 2, 4, 1)
end
function drawPlus(x, y)
	screen.drawRectF(x, y + 2, 5, 1)
	screen.drawRectF(x + 2, y, 1, 5)
end
function setArrayColor(array, i)
	if i == 1 then
		screen.setColor(0, 0, 0)
	elseif i == 0 then
		screen.setColor(array[1], array[2], array[3])
	end
end
function setHighlightColor(isHighlighted, i)
	i = i or 0
	if isHighlighted and i == 0 then
		screen.setColor(255, 127, 0)
	elseif i == 0 then
		screen.setColor(UIRGB[1], UIRGB[2], UIRGB[3])
	elseif i == 1 then
		screen.setColor(0, 0, 0)
	end
end

-- onTick functions

function patternMatch(x, y, table)
	for i = 1, #table do
		if table[i].X == x and table[i].Y == y then
			return true
		end
	end
	return false
end
function clamp(value, min, max)
	return math.max(min, math.min(value, max))
end
function textWidth(chars)
	return 4 * (chars - 1) + 3
end
function getCoordinates()
	charH, symbolY, textX = 5, h - 6, cx - 14
	verticalGap = clamp((h / 32 - 1), 0, 2) * 2
	return
	{
		Up = { X = 0, Y = 0, Width = w, Height = cy - 2 },
		Down = { X = 0, Y = cy + 1, Width = w, Height = cy - 1 },
		Left = { X = 0, Y = 0, Width = cx - 1, Height = h },
		Right = { X = cx + 2, Y = 0, Width = cx - 2, Height = h },

		Compass = { X = cx - 4, Y = 2, Width = textWidth(2), Height = charH }, -- Now a textBox, compass2 is no longer necessary
		Minus = { X = w - 5, Y = symbolY, Width = 4, Height = charH },
		Plus = { X = w - 12, Y = symbolY, Width = 5, Height = charH },
		Reset = { X = w - 17, Y = symbolY, Width = textWidth(1), Height = charH },
		Data = { X = w - 22, Y = symbolY, Width = textWidth(1), Height = charH },
		Line = { X = w - 27, Y = symbolY, Width = textWidth(1), Height = charH },
		Clear = { X = w - 32, Y = symbolY, Width = textWidth(1), Height = charH },

		Xcoordinate = { X = textX, Y = cy - 13 - verticalGap * 4, Width = textWidth(7), Height = charH },
		Ycoordinate = { X = textX, Y = cy - 6 - verticalGap * 3, Width = textWidth(7), Height = charH },
		Heading = { X = cx - 6, Y = cy + 1 - verticalGap * 2, Width = textWidth(3), Height = charH },
		DistanceEstimate = { X = textX, Y = cy + 8 - verticalGap, Width = textWidth(7), Height = charH },
		TimeEstimate = { X = textX, Y = cy + 15, Width = textWidth(7), Height = charH },
		ChangeWaypointMode = { X = w - 5, Y = symbolY, Width = textWidth(1), Height = charH }
	}
end
function createSRLatch()
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
function waypointDistance(gpsX, gpsY, waypointX, waypointY, speed)
	distance = clamp(math.sqrt((waypointX - gpsX) ^ 2 + (waypointY - gpsY) ^ 2) / 1000, 0, 256)
	estimate = clamp((distance / (speed * 3.6)) * 3600, 0, 359940) -- 99h 59m
	return distance, estimate
end
function touchRectF(isPressed, inputX, inputY, x, y, rectW, rectH)
	return
		isPressed and
		inputX >= x and inputY >= y and
		inputX <= x + rectW - 1 and inputY <= y + rectH - 1
end
function createToggle()
	local oldVariable, toggleVariable = false, false
	return function(variable)
		if variable and not oldVariable then
			toggleVariable = not toggleVariable
		end
		oldVariable = variable
		return toggleVariable
	end
end
function createCounter(startValue)
	local counter = startValue
	return function(down, up, increment, min, max, reset)
		counter = (down) and counter - increment or counter
		counter = (up) and counter + increment or counter
		counter = (reset) and 0 or counter
		counter = clamp(counter, min, max)
		return counter
	end
end
function createPulse()
	local oldVariable = false
	return function(variable)
		local risingEdge = not oldVariable and variable
		oldVariable = variable
		return risingEdge
	end
end
function clearWaypointTable(waypointTable, defaultX, defaultY)
	repeat
		table.remove(waypointTable, 1)
	until #waypointTable == 0
	table.insert(waypointTable, { X = defaultX, Y = defaultY })
end
function createMemoryRegister()
	local storedValue = 0
	return function(valueToStore, set, reset, resetValue)
		if set then
			storedValue = valueToStore
		end
		if reset then
			storedValue = resetValue
		end
		return storedValue
	end
end

speedSRLatch = createSRLatch()
dataButtonToToggle = createToggle()
DefaultZoom = property.getNumber("Df zm") -- Comes after the Zoom multiplier and before Default waypoint mode
zoomTimeCounter, zoomCounter = createCounter(1), createCounter(DefaultZoom)
linePulse = createPulse()
lineSRLatch = createSRLatch()
clearSRLatch = createSRLatch()
leftRightCounter, upDownCounter = createCounter(0), createCounter(0)
storeX, storeY = createMemoryRegister(), createMemoryRegister()
changeModePulse = createPulse()
scrollSRLatch = createSRLatch()
scrollCounter = createCounter(0)


Coords = {}
OldTargetX = 0
Target = {}
WaypointTable = { { X = 0 , Y = 0} }
DrawLine = false
StoredX, StoredY = 0, 0
MapMovement = "G" -- "G", GPS/"T", Touchscreen
MapLimit = 128000

PointerTypes = { [1] = "S", [2] = "T" } -- Square/triangle
PointerType = PointerTypes[property.getNumber("Ptr")]
PropertyMultiplierX, PropertyMultiplierY = property.getNumber("X mp"), property.getNumber("Y mp")
ZoomMultiplier = property.getNumber("Zm mp")
WaypointModes = { [1] = "S", [2] = "M" } -- Single/multiple
WaypointMode = WaypointModes[property.getNumber("Df wp")]
WaypointClearingRange = property.getNumber("Clr")
SpeedThreshold = property.getNumber("SpdThr")
UIRGB, LineRGB, PointerRGB = {}, {}, {}
UIRGB, LineRGB, PointerRGB = propertyToColors("UIC"), propertyToColors("LnC"), propertyToColors("PtrC")

IsOverlayEnabled = property.getBool("ComOvrl")
ReferencePointer = property.getBool("RefPtr") -- "Square pointer during map movement"
InvertHeading = property.getBool("InvHdg")

-- Reminder: drawText function name does not get minimized, needs manual minimization
--[[ Size optimizations:
- Damn near everything is global (all functions, all helpers, most variables)
- TouchRectF includes isPressed
- All strings have been cut by a LOT
]]
function onTick()
	-- Physics sensor inputs
	GPSX, GPSY = input.getNumber(1), input.getNumber(3)
	directionalSpeed, Speed = input.getNumber(9), input.getNumber(13)
	CompassDegrees = (-input.getNumber(17) * 360 + 360) % 360
	-- Misc. composite inputs
	w, h = input.getNumber(18), input.getNumber(19)
	inputX, inputY = input.getNumber(20), input.getNumber(21)
	waypointX, waypointY = input.getNumber(22), input.getNumber(23)
	-- Radar target data inputs
	targetX, targetY = input.getNumber(24), input.getNumber(25)
	targetHorizontalDistance, targetBearing = input.getNumber(26), input.getNumber(27)
	targetWeight = input.getNumber(28)
	isPressed = input.getBool(1)	  -- This does NOT need old screen mode checking

	cx, cy = w / 2, h / 2
	Coords = getCoordinates() -- Coords stores static coordinates, scrolling is added in onDraw()

	-- Radar target table insertion
	if targetX ~= OldTargetX and targetX ~= 0 then
		table.insert(Target, {X = targetX, Y = targetY, Distance = targetHorizontalDistance, Bearing = targetBearing, Mass = targetWeight,
			Time = 1, Toggle = false, ToggleFunction = createToggle()})
	end
	OldTargetX=targetX
	-- Radar target table removal
	for k, v in pairs(Target) do
		v.Time = v.Time - 0.001
		if v.Time <= 0 then
			table.remove(Target, k)
		end
	end

	-- Waypoint table insertion
	WaypointSet = not (WaypointTable[1].X == 0 and WaypointTable[1].Y == 0)
	KeypadSet = not (waypointX == 0 and waypointY == 0)
	if WaypointMode == "S" then
		WaypointTable[1].X = waypointX
		WaypointTable[1].Y = waypointY
	elseif not patternMatch(waypointX, waypointY, WaypointTable) and WaypointMode == "M" then
		if not WaypointSet then
			WaypointTable[1].X = waypointX
			WaypointTable[1].Y = waypointY
		elseif #WaypointTable < 8 and KeypadSet then
			table.insert(WaypointTable, { X = waypointX, Y = waypointY })
		end
	end

	isSpeedNegative = speedSRLatch(directionalSpeed < -1, directionalSpeed > 1) and InvertHeading
	if isSpeedNegative then
		CompassDegrees = (CompassDegrees + 180) % 360
	end

	Distance, Estimate = 0, 0
	if WaypointSet then
		Distance, Estimate = waypointDistance(GPSX, GPSY, WaypointTable[1].X, WaypointTable[1].Y, Speed)
	end

	upPressed = touchRectF(isPressed, inputX, inputY, Coords.Up.X - 1, Coords.Up.Y - 1, Coords.Up.Width + 2, Coords.Up.Height + 2)
	downPressed = touchRectF(isPressed, inputX, inputY, Coords.Down.X - 1, Coords.Down.Y - 1, Coords.Down.Width + 2, Coords.Down.Height + 2)
	leftPressed = touchRectF(isPressed, inputX, inputY, Coords.Left.X - 1, Coords.Left.Y - 1, Coords.Left.Width + 2, Coords.Left.Height + 2)
	rightPressed = touchRectF(isPressed, inputX, inputY, Coords.Right.X - 1, Coords.Right.Y - 1, Coords.Right.Width + 2, Coords.Right.Height + 2)

	dataPressed = touchRectF(isPressed, inputX, inputY, Coords.Data.X-1, Coords.Data.Y-1, Coords.Data.Width + 2, Coords.Data.Height + 2)
	DataToggled = dataButtonToToggle(dataPressed)
	ScreenMode = (DataToggled) and "D" or "M" -- "Data" or "Map"

	if ScreenMode == "M" then
		ZoomDecrease = touchRectF(isPressed, inputX, inputY, Coords.Minus.X - 1, Coords.Minus.Y - 1, Coords.Minus.Width + 2, Coords.Minus.Height + 2)
		ZoomIncrease = touchRectF(isPressed, inputX, inputY, Coords.Plus.X - 1, Coords.Plus.Y - 1, Coords.Plus.Width + 2, Coords.Plus.Height + 2)
		zooming = ZoomDecrease or ZoomIncrease
		zoomTimeMultiplier = zoomTimeCounter(false, zooming, 0.1, 1, 3, not zooming)
		Zoom = zoomCounter(ZoomIncrease, ZoomDecrease, 0.03 * zoomTimeMultiplier * ZoomMultiplier, 0.1, 50, false)

		ResetMovement = touchRectF(isPressed, inputX, inputY, Coords.Reset.X - 1, Coords.Reset.Y - 1, Coords.Reset.Width + 2, Coords.Reset.Height + 2)

		LinePressed = touchRectF(isPressed, inputX, inputY, Coords.Line.X - 1, Coords.Line.Y - 1, Coords.Line.Width + 2, Coords.Line.Height + 2)
		linePressedPulse = linePulse(LinePressed)
		DrawLine = lineSRLatch(linePressedPulse, (not WaypointSet) or (DrawLine and linePressedPulse))

		clearPressed = touchRectF(isPressed, inputX, inputY, Coords.Clear.X - 1, Coords.Clear.Y - 1, Coords.Clear.Width + 2, Coords.Clear.Height + 2)
		ClearAll=clearSRLatch(clearPressed and WaypointMode == "M" and WaypointSet, not isPressed)
		-- Waypoint removal
		if ClearAll then
			clearWaypointTable(WaypointTable, waypointX, waypointY)
		elseif Distance * 1000 <= WaypointClearingRange then
			table.remove(WaypointTable, 1)
			if #WaypointTable == 0 then
				table.insert(WaypointTable,{X = waypointX, Y = waypointY})
			end
		end

		anyMovement = (upPressed or downPressed or leftPressed or rightPressed)
		noButtonPressed = not (dataPressed or ZoomDecrease or ZoomIncrease or ResetMovement or
			(LinePressed and WaypointSet) or ClearAll)
		-- Radar target buttons
		anyTargetsPressed = false
		for i = 1, #Target do
			buttonX, buttonY = map.mapToScreen(StoredX, StoredY, Zoom, w, h, Target[i].X, Target[i].Y)
			targetPressed = touchRectF(isPressed, inputX, inputY, round(buttonX)-1, round(buttonY)-1, 4, 4) and noButtonPressed
			Target[i].Toggle = Target[i].ToggleFunction(targetPressed)
			if targetPressed then
				anyTargetsPressed=true
			end
		end
		noButtonPressed = noButtonPressed and (not anyTargetsPressed)

		if MapMovement == "G" and anyMovement and noButtonPressed then
			MapMovement = "T"
		elseif ResetMovement then
			MapMovement = "G"
		end

		distanceToCenterX, distanceToCenterY = cx - inputX, cy - inputY
		movementMultiplierX = math.abs(distanceToCenterX) * Zoom * PropertyMultiplierX
		movementMultiplierY = math.abs(distanceToCenterY) * Zoom * PropertyMultiplierY
		movementX = leftRightCounter(leftPressed and noButtonPressed, rightPressed and noButtonPressed,
			0.5 * movementMultiplierX, -MapLimit - GPSX, MapLimit - GPSX, ResetMovement)
		movementY = upDownCounter(downPressed and noButtonPressed, upPressed and noButtonPressed,
			0.5 * movementMultiplierY, -MapLimit - GPSY, MapLimit - GPSY, ResetMovement)

		StoredX = storeX(GPSX, MapMovement == "G", ResetMovement, GPSX) + movementX
		StoredY = storeY(GPSY, MapMovement == "G", ResetMovement, GPSY) + movementY
		PointerX, PointerY = map.mapToScreen(StoredX, StoredY, Zoom, w, h, GPSX, GPSY)
	elseif ScreenMode == "D" then
		changeWaypointMode = touchRectF(isPressed, inputX, inputY, Coords.ChangeWaypointMode.X - 1, Coords.ChangeWaypointMode.Y - 1,
			Coords.ChangeWaypointMode.Width + 2, Coords.ChangeWaypointMode.Height + 2)
		changeWaypointModePulse = changeModePulse(changeWaypointMode)
		if changeWaypointModePulse and WaypointMode == "S" then
			WaypointMode = "M"
			clearWaypointTable(WaypointTable, waypointX, waypointY)
		elseif changeWaypointModePulse and WaypointMode == "M" then
			WaypointMode = "S"
			clearWaypointTable(WaypointTable, waypointX, waypointY)
		end

		noButtonsPressed = not (dataPressed or changeWaypointMode)
		-- Custom scrolling for the 1x1 and 1x2 screens
		if h == 32 then
			scrollDown = scrollSRLatch(downPressed and noButtonsPressed, (upPressed and noButtonsPressed) or (not WaypointSet))
			scrollUp = not scrollDown
			ScrollY = scrollCounter(scrollDown, scrollUp, 1, -21, 0, false)
		else
			ScrollY = 0
		end
	end
	-- Autopilot outputs
	output.setNumber(1, WaypointTable[1].X)
	output.setNumber(2, WaypointTable[1].Y)
end

function onDraw()
	if ScreenMode == "M" then
		screen.setMapColorOcean(0, 0, 0, 2)
		screen.setMapColorShallows(0, 0, 0, 40)
		screen.setMapColorLand(0, 0, 0, 100)
		screen.setMapColorGrass(0, 0, 0, 100)
		screen.setMapColorSand(0, 0, 0, 100)
		screen.setMapColorSnow(0, 0, 0, 200)
		screen.setMapColorRock(0, 0, 0, 60)
		screen.setMapColorGravel(0, 0, 0, 120)
		screen.drawMap(StoredX, StoredY, Zoom)

		for k, v in ipairs(Target) do
			drawTarget(v)
		end

		screenWaypointTable = {}
		for i = 1, #WaypointTable do
			screenX, screenY = map.mapToScreen(StoredX, StoredY, Zoom, w, h, WaypointTable[i].X, WaypointTable[i].Y)
			screenWaypointTable[i] = { X = screenX, Y = screenY }
		end

		if DrawLine then
			screen.setColor(LineRGB[1], LineRGB[2], LineRGB[3])
			screen.drawLine(PointerX, PointerY, screenWaypointTable[1].X, screenWaypointTable[1].Y)
			for i = 2, #screenWaypointTable do
				screen.drawLine(screenWaypointTable[i - 1].X, screenWaypointTable[i - 1].Y, screenWaypointTable[i].X, screenWaypointTable[i].Y)
			end
		end
		if WaypointSet then
			screen.setColor(255, 127, 0)
			for i = 1, #screenWaypointTable do
				screen.drawRectF(screenWaypointTable[i].X, screenWaypointTable[i].Y, 2, 2)
			end
		end

		for i = 1, 0, -1 do
			setArrayColor(PointerRGB, i)
			if PointerType == "T" then
				drawTrianglePointer(PointerX + i, PointerY, CompassDegrees)
			elseif PointerType == "S" then -- Square and reference pointers intentionally don't have shading
				if MapMovement == "G" then
					screen.drawRectF(cx - 1, cy - 1, 2, 2)
				else
					screen.drawRectF(PointerX, PointerY, 2, 2)
				end
			end
			if MapMovement == "T" and ReferencePointer then
				screen.drawRectF(cx - 1, cy - 1, 2, 2)
			end
		end
		for i = 1, 0, -1 do
			setArrayColor(UIRGB, i)
			drawCompassOverlay(CompassDegrees, i, IsOverlayEnabled)
			setHighlightColor(ZoomDecrease, i)
			drawMinus(Coords.Minus.X + i, Coords.Minus.Y)
			setHighlightColor(ZoomIncrease, i)
			drawPlus(Coords.Plus.X + i, Coords.Plus.Y)
			setHighlightColor(ResetMovement, i)
			drawText(Coords.Reset.X + i, Coords.Reset.Y, "R") -- Data button is at the end of onDraw()
			if WaypointSet then
				setHighlightColor(LinePressed, i)
				drawText(Coords.Line.X + i, Coords.Line.Y, "L")
				if WaypointMode == "M" then
					setHighlightColor(ClearAll and KeypadSet, i)
					drawText(Coords.Clear.X + i, Coords.Clear.Y, "C")
				end
			end
		end
	elseif ScreenMode == "D" then
		screen.setColor(20, 20, 20)
		screen.drawClear()

		hours, minutes = math.floor(Estimate / 3600), Estimate % 3600 / 60
		degreeDigits = string.len(string.format("%.0f", CompassDegrees))

		for i = 1, 0, -1 do
			setArrayColor(UIRGB, i)
			drawText(Coords.Xcoordinate.X + i, Coords.Xcoordinate.Y + ScrollY, string.format("%.0f", GPSX), 1, false, Coords.Xcoordinate.Width, 0)
			drawText(Coords.Ycoordinate.X + i, Coords.Ycoordinate.Y + ScrollY, string.format("%.0f", GPSY), 1, false, Coords.Ycoordinate.Width, 0)
			drawText(Coords.Heading.X + i, Coords.Heading.Y + ScrollY, string.format("%.0f", CompassDegrees), 1, false, Coords.Heading.Width, 0)
			screen.drawCircle((cx - 5) + round((11 - degreeDigits * 4) / 2) + (degreeDigits * 4 + 1) + i, Coords.Heading.Y + ScrollY, 1)
			if WaypointSet then
				drawText(Coords.DistanceEstimate.X + i, Coords.DistanceEstimate.Y + ScrollY,
					string.format("%." .. 3 - string.len(math.floor(Distance)) .. "f", Distance) .. " km", 1, false, Coords.DistanceEstimate.Width, 0)
				if Speed >= SpeedThreshold and hours > 0 then
					drawText(Coords.TimeEstimate.X + i, Coords.TimeEstimate.Y + ScrollY, string.format("%dh %.0fm", hours, minutes), 1, false, Coords.TimeEstimate.Width, 0)
				elseif Speed >= SpeedThreshold and round(minutes)>0 then
					drawText(Coords.TimeEstimate.X + i, Coords.TimeEstimate.Y + ScrollY, string.format("%.0fm", minutes), 1, false, Coords.TimeEstimate.Width, 0)
				end
			end
		end

		-- Invisible rectangles for scrolling
		if h == 32 then
			screen.setColor(20, 20, 20)
			screen.drawRectF(0, 0, w, 2)
			screen.drawRectF(0, 23, w, 9)
		end

		for i = 1, 0, -1 do
			setArrayColor(UIRGB, i)
			drawText(Coords.ChangeWaypointMode.X + i, Coords.ChangeWaypointMode.Y, WaypointMode:sub(1,1))
		end
		-- Background details
		screen.setColor(25, 25, 25)
		screen.drawRectF(0, 0, w, 1)
		screen.drawRectF(0, 0, 1, h)
		screen.drawRectF(0, h - 1, w, 1)
		screen.setColor(15, 15, 15)
		screen.drawRectF(w - 1, 0, 1, h)
	end
	-- Data button
	for i = 1, 0, -1 do
		setHighlightColor(DataToggled, i)
		drawText(Coords.Data.X + i, Coords.Data.Y, "D")
	end
end
