-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

-- onDraw functions

local function propertyToColors(propertyName) -- Colors are stored as "255,255,255","0,0,0", etc.
	local colors=property.getText(propertyName)
	local tempTable={}
	for color in colors:gmatch("%d+") do
		table.insert(tempTable,tonumber(color))
	end
	return tempTable
end
local function drawMap()
	screen.setMapColorOcean(0,0,0,2)
	screen.setMapColorShallows(0,0,0,40)
	screen.setMapColorLand(0,0,0,100)
	screen.setMapColorGrass(0,0,0,100)
	screen.setMapColorSand(0,0,0,100)
	screen.setMapColorSnow(0,0,0,200)
	screen.setMapColorRock(0,0,0,60)
	screen.setMapColorGravel(0,0,0,120)
	screen.drawMap(StoredX,StoredY,Zoom)
end
FontString=property.getText("Font 1/3")..property.getText("Font 2/3")..property.getText("Font 3/3")
CharacterTable={}
for hexValue in FontString:gmatch("....") do
	table.insert(CharacterTable,tonumber(hexValue,16))
end
local function drawText(x,y,text,size,isUpsideDown,width,horizontalAlign)
	size,isUpsideDown,width,horizontalAlign=size or 1,isUpsideDown or false,width or 0,horizontalAlign or -1
	text=(isUpsideDown) and text:reverse() or text
	text=text:upper()
	local length=text:len()
	if horizontalAlign==0 then
		x=(x+width/2)-(length*4*size/2)
	elseif horizontalAlign==1 then
		x=(x+width)-(length*4*size)+1
	end
	for char in text:gmatch(".") do
		local key=char:byte()-31 -- Convert ASCII value into a key for the character table
		if key>=92 then -- For ASCIIs after the lowercase letters
			key=key-26
		end
		local charValue=CharacterTable[key] or 65534
		for i=14,0,-1 do
			local pixelX,pixelY=i%3*size,i//3*size
			if (charValue&2^(15-i))~=0 then
				if not isUpsideDown then
					screen.drawRectF(x+pixelX,y+pixelY,size,size)
				else
					screen.drawRectF(x+(2-pixelX),y+(4-pixelY),size,size)
				end
			end
		end
		x=x+4*size
	end
end
local function drawCompassOverlay(compassDegrees,shadingOffset,enabled)
	if enabled then
		if compassDegrees>337.5 or compassDegrees<22.5 then
			drawText(w/2-2+shadingOffset,1,"N")
		elseif compassDegrees<67.5 then
			drawText(w/2-4+shadingOffset,1,"NE")
		elseif compassDegrees<112.5 then
			drawText(w/2-2+shadingOffset,1,"E")
		elseif compassDegrees<157.5 then
			drawText(w/2-4+shadingOffset,1,"SE")
		elseif compassDegrees<202.5 then
			drawText(w/2-2+shadingOffset,1,"S")
		elseif compassDegrees<247.5 then
			drawText(w/2-4+shadingOffset,1,"SW")
		elseif compassDegrees<292.5 then
			drawText(w/2-2+shadingOffset,1,"W")
		else
			drawText(w/2-4+shadingOffset,1,"NW")
		end
	end
end
local function drawPlus(x,y)
	screen.drawRectF(x,y+2,5,1)
	screen.drawRectF(x+2,y,1,5)
end
local function drawMinus(x,y)
	screen.drawRectF(x,y+2,4,1)
end
local function rotatePoint(x,y,angle)
	return x*math.cos(angle)-y*math.sin(angle),x*math.sin(angle)+y*math.cos(angle)
end
local function drawTrianglePointer(x,y,heading)
	local angle=math.rad(heading)
	local tipX,tipY=rotatePoint(0,-5,angle)
	local bottomLeftX,bottomLeftY=rotatePoint(-3,3,angle)
	local bottomRightX,bottomRightY=rotatePoint(3,3,angle)
	screen.drawTriangleF(x+tipX,y+tipY,x+bottomLeftX,y+bottomLeftY,x+bottomRightX,y+bottomRightY)
end
local function getHighlightColor(isHighlighted)
	if isHighlighted then
		return 255,127,0
	else
		return UIRGB[1],UIRGB[2],UIRGB[3]
	end
end
local function drawMapUI()
	if DrawLine then
		screen.setColor(LineRGB[1],LineRGB[2],LineRGB[3])
		screen.drawLine(PointerX,PointerY,ScreenWaypointX,ScreenWaypointY)
	end
	if WaypointSet then
		screen.setColor(255,127,0)
		screen.drawRectF(ScreenWaypointX,ScreenWaypointY,2,2)
	end

	screen.setColor(PointerRGB[1],PointerRGB[2],PointerRGB[3])
	if PointerType=="Triangle" then
		drawTrianglePointer(PointerX,PointerY,CompassDegrees)
	elseif PointerType=="Square" then
		if MapMovement=="GPS" then
			screen.drawRectF(w/2-1,h/2-1,2,2)
		else
			screen.drawRectF(PointerX,PointerY,2,2)
		end
	end
	if MapMovement=="Touchscreen" and ReferencePointer then
		screen.drawRectF(w/2-1,h/2-1,2,2)
	end

	screen.setColor(0,0,0)
	drawCompassOverlay(CompassDegrees,1,IsOverlayEnabled)
	drawMinus(CoordinateTableX.minus+1,ButtonY+1)
	drawPlus(CoordinateTableX.plus+1,ButtonY+1)
	drawText(CoordinateTableX.reset+1,ButtonY+1,"R") -- Data button drawn in a separate function
	if WaypointSet then
		drawText(CoordinateTableX.line+1,ButtonY+1,"L")
	end

	screen.setColor(UIRGB[1],UIRGB[2],UIRGB[3])
	drawCompassOverlay(CompassDegrees,0,IsOverlayEnabled)
	screen.setColor(getHighlightColor(HighlightTable.zoomDec))
	drawMinus(CoordinateTableX.minus,ButtonY+1)
	screen.setColor(getHighlightColor(HighlightTable.zoomInc))
	drawPlus(CoordinateTableX.plus,ButtonY+1)
	screen.setColor(getHighlightColor(HighlightTable.reset))
	drawText(CoordinateTableX.reset,ButtonY+1,"R")
	if WaypointSet then
		screen.setColor(getHighlightColor(HighlightTable.line))
		drawText(CoordinateTableX.line,ButtonY+1,"L")
	end
end
local function drawBackground()
	screen.setColor(20,20,20)
	screen.drawClear()
end
local function clamp(value,min,max)
	return math.max(min,math.min(value,max))
end
local function round(value)
	return math.floor(value+0.5)
end
local function drawDataUI()
	local verticalGap=clamp((h/32-1),0,2)*2
	local degreeDigits=string.len(string.format("%.0f",CompassDegrees))
	local hours,minutes=math.floor(Estimate/3600),Estimate%3600/60

	screen.setColor(0,0,0)
	drawText(w/2-13,(h/2-13)+ScrollY-verticalGap*4,string.format("%.0f",GPSX),1,false,27,0)
	drawText(w/2-13,(h/2-6)+ScrollY-verticalGap*3,string.format("%.0f",GPSY),1,false,27,0)
	drawText(w/2-5,(h/2+1)+ScrollY-verticalGap*2,string.format("%.0f",CompassDegrees),1,false,11,0)
	screen.drawCircle((w/2-5)+round((11-degreeDigits*4)/2)+(degreeDigits*4+1),(h/2+1)+ScrollY-verticalGap*2,1)
	if WaypointSet then
		drawText(w/2-13,(h/2+8)+ScrollY-verticalGap,string.format("%.".. 4-string.len(math.floor(Distance)) .."f",Distance).."km",1,false,27,0)
		if Speed>SpeedThreshold then
			if hours>0 then
				drawText(w/2-13,(h/2+15)+ScrollY,string.format("%dh %.0fm",hours,minutes),1,false,27,0)
			else
				drawText(w/2-13,(h/2+15)+ScrollY,string.format("%.0fm",minutes),1,false,27,0)
			end
		end
	end

	screen.setColor(UIRGB[1],UIRGB[2],UIRGB[3])
	drawText(w/2-14,(h/2-13)+ScrollY-verticalGap*4,string.format("%.0f",GPSX),1,false,27,0)
	drawText(w/2-14,(h/2-6)+ScrollY-verticalGap*3,string.format("%.0f",GPSY),1,false,27,0)
	drawText(w/2-6,(h/2+1)+ScrollY-verticalGap*2,string.format("%.0f",CompassDegrees),1,false,11,0)
	screen.drawCircle((w/2-6)+round((11-degreeDigits*4)/2)+(degreeDigits*4+1),(h/2+1)+ScrollY-verticalGap*2,1)
	if WaypointSet then
		drawText(w/2-14,(h/2+8)+ScrollY-verticalGap,string.format("%.".. 4-string.len(math.floor(Distance)) .."f",Distance).."km",1,false,27,0)
		if Speed>SpeedThreshold then
			if hours>0 then
				drawText(w/2-14,(h/2+15)+ScrollY,string.format("%dh %.0fm",hours,minutes),1,false,27,0)
			else
				drawText(w/2-14,(h/2+15)+ScrollY,string.format("%.0fm",minutes),1,false,27,0)
			end
		end
	end

	-- Invisible rectangles for scrolling
	if h==32 then
		screen.setColor(20,20,20)
		screen.drawRectF(0,0,32,2)
		screen.drawRectF(0,23,32,9)
	end
end
local function drawBackgroundDetails() -- Unfortunately the details need to be drawn separate to support the scrolling
	screen.setColor(25,25,25)
	screen.drawRectF(0,0,w,1)
	screen.drawRectF(0,0,1,h)
	screen.drawRectF(0,h-1,w,1)
	screen.setColor(15,15,15)
	screen.drawRectF(w-1,0,1,h)
end
local function drawDataButton()
	screen.setColor(0,0,0)
	drawText(CoordinateTableX.data+1,ButtonY+1,"D")
	screen.setColor(getHighlightColor(DataToggled))
	drawText(CoordinateTableX.data,ButtonY+1,"D")
end

-- onTick functions

local function createSRLatch()
	local output=false
	return function(set,reset)
		if set and reset then
			output=false
		elseif set then
			output=true
		elseif reset then
			output=false
		end
		return output
	end
end
local function getButtonCoordinates()
	local minusW,plusW,letterW=4,5,3
	local buttonY=h-7

	local minusX,plusX=w-5,w-12
	local resetX,dataX,lineX=w-17,w-22,w-27

	local coordinateX=
	{
		minus=minusX,
		plus=plusX,
		reset=resetX,
		data=dataX,
		line=lineX
	}
	local width=
	{
		minus=minusW,
		plus=plusW,
		letter=letterW
	}

	return coordinateX,width,buttonY
end
local function touchRectF(inputX,inputY,x,y,rectW,rectH)
	return
	inputX>=x and inputY>=y and
	inputX<=x+rectW-1 and inputY<=y+rectH-1
end
local function createToggle()
	local oldVariable=false
	local toggleVariable=false
	return function(variable)
		if variable and not oldVariable then
			toggleVariable=not toggleVariable
		end
		oldVariable=variable
		return toggleVariable
	end
end
local function createCounter(startValue)
	local counter=startValue
	return function(down,up,increment,min,max,reset)
		if down then
			counter=counter-increment
		end
		if up then
			counter=counter+increment
		end
		if reset then
			counter=0
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
local function createMemoryRegister()
	local storedValue=0
	return function(valueToStore,set,reset,resetValue)
		if set then
			storedValue=valueToStore
		end
		if reset then
			storedValue=resetValue
		end
		return storedValue
	end
end
local function waypointDistance(gpsX,gpsY,waypointX,waypointY,speed)
	local differenceX=waypointX-gpsX
	local differenceY=waypointY-gpsY
	local distance=clamp(math.sqrt(differenceX*differenceX+differenceY*differenceY)/1000,0,256)
	local estimate=clamp((distance/(speed*3.6))*3600,0,359999)
	return distance,estimate
end

local speedSRLatch=createSRLatch()
local dataButtonToToggle=createToggle()
DefaultZoom=property.getNumber("Default zoom")
local zoomTimeCounter,zoomCounter=createCounter(1),createCounter(DefaultZoom)
local linePulse=createPulse()
local lineSRLatch=createSRLatch()
CapacitorTable={}
for i=1,4 do
	CapacitorTable[i]=createCapacitor()
end
local leftRightCounter,upDownCounter=createCounter(0),createCounter(0)
local storeX,storeY=createMemoryRegister(),createMemoryRegister()
local scrollSRLatch=createSRLatch()
local scrollCounter=createCounter(0)

w,h=0,0
DataLine=false
MapMovement="GPS" -- GPS/Touchscreen

PointerTypes={[1]="Square",[2]="Triangle"}
PointerType=PointerTypes[property.getNumber("Pointer type")]
PropertyMultiplierX,PropertyMultiplierY=property.getNumber("X movement multiplier"),property.getNumber("Y movement multiplier")
ZoomMultiplier=property.getNumber("Zoom multiplier")
SpeedThreshold=property.getNumber("Minimum speed for time estimate (m/s)")
UIRGB,LineRGB,PointerRGB={},{},{}
UIRGB,LineRGB,PointerRGB=propertyToColors("UI color"),propertyToColors("Waypoint line color"),propertyToColors("Pointer color")

IsOverlayEnabled=property.getBool("Compass overlay")
ReferencePointer=property.getBool("Map movement reference pointer") -- "Square pointer during map movement"
InvertBearing=property.getBool("Invert bearing when reversing")

function onTick()
	-- Physics sensor inputs
	GPSX,GPSY=input.getNumber(1),input.getNumber(3)
	local directionalSpeed
	directionalSpeed,Speed=input.getNumber(9),input.getNumber(13)
	CompassDegrees=(-input.getNumber(17)*360+360)%360
	-- Misc. composite inputs
	local inputX,inputY=input.getNumber(18),input.getNumber(19)
	local waypointX,waypointY=input.getNumber(20),input.getNumber(21)
	local isPressed=input.getBool(1) -- This does NOT need old screen mode checking

	WaypointSet=not(waypointX==0 and waypointY==0)

	local isSpeedNegative=speedSRLatch(directionalSpeed<-1,directionalSpeed>1) and InvertBearing
	if isSpeedNegative then
		CompassDegrees=(CompassDegrees+180)%360
	end

	local widthTable,buttonH=nil,7
	CoordinateTableX,widthTable,ButtonY=getButtonCoordinates() -- Coordinate and width tables are for button symbols, not the buttons themselves, that's why they are offset by -1 and 2.
	local dataPressed=isPressed and touchRectF(inputX,inputY,CoordinateTableX.data-1,ButtonY,widthTable.letter+2,buttonH)
	DataToggled=dataButtonToToggle(dataPressed)
	ScreenMode=(DataToggled) and "Data" or "Map"

	local upPressed=isPressed and touchRectF(inputX,inputY,0,0,w,h/2-1)
	local downPressed=isPressed and touchRectF(inputX,inputY,0,h/2+2,w,h/2-2)
	local leftPressed=isPressed and touchRectF(inputX,inputY,0,0,w/2-1,h)
	local rightPressed=isPressed and touchRectF(inputX,inputY,w/2+2,0,w/2-2,h)

	if ScreenMode=="Map" then
		local zoomDecrease=isPressed and touchRectF(inputX,inputY,CoordinateTableX.minus-1,ButtonY,widthTable.minus+2,buttonH)
		local zoomIncrease=isPressed and touchRectF(inputX,inputY,CoordinateTableX.plus-1,ButtonY,widthTable.plus+2,buttonH)
		local zooming=zoomDecrease or zoomIncrease
		local zoomTimeMultiplier=zoomTimeCounter(false,zooming,0.1,1,3,not zooming)
		Zoom=zoomCounter(zoomIncrease,zoomDecrease,0.03*zoomTimeMultiplier*ZoomMultiplier,0.1,50,false)

		local resetMovement=isPressed and touchRectF(inputX,inputY,CoordinateTableX.reset-1,ButtonY,widthTable.letter+2,buttonH)

		local linePressed=isPressed and touchRectF(inputX,inputY,CoordinateTableX.line-1,ButtonY,widthTable.letter+2,buttonH)
		local linePressedPulse=linePulse(linePressed)
		DrawLine=lineSRLatch(linePressedPulse,(not WaypointSet) or (DrawLine and linePressedPulse))

		HighlightTable={zoomDec=zoomDecrease,zoomInc=zoomIncrease,reset=resetMovement,line=linePressed} -- Data does not need a capacitor
		local j=0
		for k,v in pairs(HighlightTable) do
			j=j+1
			HighlightTable[k]=CapacitorTable[j](v,0,10)
		end

		local anyMovement=(upPressed or downPressed or leftPressed or rightPressed)
		local noButtonPressed=not(dataPressed or zoomDecrease or zoomIncrease or resetMovement or (linePressed and WaypointSet))
		if MapMovement=="GPS" and anyMovement and noButtonPressed then
			MapMovement="Touchscreen"
		end
		if resetMovement then
			MapMovement="GPS"
		end

		local centerDistanceX,centerDistanceY=(w/2)-inputX,(h/2)-inputY
		local movementMultiplierX=math.abs(centerDistanceX)*Zoom*PropertyMultiplierX
		local movementMultiplierY=math.abs(centerDistanceY)*Zoom*PropertyMultiplierY
		local movementX=leftRightCounter(leftPressed and noButtonPressed,rightPressed and noButtonPressed,0.5*movementMultiplierX,-128000-GPSX,128000-GPSX,resetMovement)
		local movementY=upDownCounter(downPressed and noButtonPressed,upPressed and noButtonPressed,0.5*movementMultiplierY,-128000-GPSY,128000-GPSY,resetMovement)

		StoredX=storeX(GPSX,MapMovement=="GPS",resetMovement,GPSX)+movementX
		StoredY=storeY(GPSY,MapMovement=="GPS",resetMovement,GPSY)+movementY
		PointerX,PointerY=map.mapToScreen(StoredX,StoredY,Zoom,w,h,GPSX,GPSY)
		ScreenWaypointX,ScreenWaypointY=map.mapToScreen(StoredX,StoredY,Zoom,w,h,waypointX,waypointY)
	elseif ScreenMode=="Data" then
		Distance,Estimate=waypointDistance(GPSX,GPSY,waypointX,waypointY,Speed)

		if h==32 then -- Custom scrolling for the 1x1 screen
			local scrollDown=scrollSRLatch(downPressed and not dataPressed,(upPressed and not dataPressed) or (not WaypointSet))
			local scrollUp=not scrollDown
			ScrollY=scrollCounter(scrollDown,scrollUp,1,-21,0,false)
		else
			ScrollY=0
		end
	end
end
function onDraw()
	w,h=screen.getWidth(),screen.getHeight()

	if ScreenMode=="Map" then
		drawMap()
		drawMapUI()
	elseif ScreenMode=="Data" then
		drawBackground()
		drawDataUI()
		drawBackgroundDetails()
	end
	drawDataButton()
end