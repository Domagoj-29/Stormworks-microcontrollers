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
local function setArrayColor(array, i)
	if i == 1 then
		screen.setColor(0, 0, 0)
	elseif i == 0 then
		screen.setColor(array[1], array[2], array[3])
	end
end

-- onTick functions

local function clamp(value, min, max)
	return math.max(min, math.min(value, max))
end
local function textWidth(chars)
	local gapCharW, charW = 4, 3
	return gapCharW * (chars - 1) + charW
end
local function getCoordinates()
	local charH = 5
	local symbolY = h - 6
	return
	{
		Minus = { X = w - 5, Y = symbolY, Width = 4, Height = charH },
		Plus = { X = w - 12, Y = symbolY, Width = 5, Height = charH },
		Data = { X = w - 22, Y = symbolY, Width = textWidth(1), Height = charH },
		ZoomLevel = { X = w - textWidth(4) - 1, Y = 1, Width = textWidth(4), Height = charH}
	}
end
local function touchRectF(inputX, inputY, x, y, rectW, rectH)
	return
		inputX >= x and inputY >= y and
		inputX <= x + rectW - 1 and inputY <= y + rectH - 1
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

local dataButtonToToggle = createToggle()
local zoomingCapacitor = createCapacitor()
DefaultZoom = property.getNumber("Default zoom") -- Comes after the Zoom multiplier and before Default waypoint mode
local zoomTimeCounter, zoomCounter = createCounter(1), createCounter(DefaultZoom)

w, h = 0, 0

ZoomMultiplier = property.getNumber("Zoom multiplier")
UIRGB = propertyToColors("UI color")

IsOverlayEnabled = property.getBool("Zoom level overlay")

-- Reminder: property values might have different names in the V10R
function onTick()
	-- Misc. composite inputs
	local inputX, inputY = input.getNumber(18), input.getNumber(19)
	local isPressed = input.getBool(1)

	cx, cy = w / 2, h / 2
	Coords = getCoordinates() -- Coords stores static coordinates

	local dataPressed = isPressed and touchRectF(inputX, inputY, Coords.Data.X-1, Coords.Data.Y-1, Coords.Data.Width + 2, Coords.Data.Height + 2)
	local dataToggled = dataButtonToToggle(dataPressed)
	ScreenMode = (dataToggled) and "Data" or "Map"

	if ScreenMode == "Map" then
		local zoomDecrease = isPressed and touchRectF(inputX, inputY, Coords.Minus.X - 1, Coords.Minus.Y - 1, Coords.Minus.Width + 2, Coords.Minus.Height + 2)
		local zoomIncrease = isPressed and touchRectF(inputX, inputY, Coords.Plus.X - 1, Coords.Plus.Y - 1, Coords.Plus.Width + 2, Coords.Plus.Height + 2)
		local zooming = zoomDecrease or zoomIncrease
		DrawZoomOverlay = zoomingCapacitor(zooming, 0, 60)
		local zoomTimeMultiplier = zoomTimeCounter(false, zooming, 0.1, 1, 3, not zooming)
		Zoom = zoomCounter(zoomIncrease, zoomDecrease, 0.03 * zoomTimeMultiplier * ZoomMultiplier, 0.1, 50, false)
	end
end

function onDraw()
	w, h = screen.getWidth(), screen.getHeight()

	if ScreenMode == "Map" and DrawZoomOverlay then
		local zoomLength = string.len(math.floor(Zoom))
		local decimalPlaces = (w == 32) and zoomLength or 3
		for i = 1, 0, -1 do
			setArrayColor(UIRGB, i)
			drawText(Coords.ZoomLevel.X + i, Coords.ZoomLevel.Y, string.format("%." .. decimalPlaces - zoomLength .. "f", Zoom), 1, false, Coords.ZoomLevel.Width, 1)
		end
	end
end
