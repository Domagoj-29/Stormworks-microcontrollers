-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

-- Credits: 
-- Radar Mapping System: https://steamcommunity.com/sharedfiles/filedetails/?id=2547757173

-- onDraw functions

local function getHighlightColor(isSelected)
	if isSelected then
		return 255,127,0
	else
		return UiR,UiG,UiB
	end
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
local function drawCompassOverlay(compassDegrees,shadingOffset,enabled)
	if enabled then
		if compassDegrees>340 or compassDegrees<20 then
			screen.drawText(w/2-2+shadingOffset,2,"N")
		elseif compassDegrees<70 then
			screen.drawText(w/2-5+shadingOffset,2,"N")
			screen.drawText(w/2+1+shadingOffset,2,"E")
		elseif compassDegrees<110 then
			screen.drawText(w/2-2+shadingOffset,2,"E")
		elseif compassDegrees<160 then
			screen.drawText(w/2-5+shadingOffset,2,"S")
			screen.drawText(w/2+1+shadingOffset,2,"E")
		elseif compassDegrees<200 then
			screen.drawText(w/2-2+shadingOffset,2,"S")
		elseif compassDegrees<250 then
			screen.drawText(w/2-5+shadingOffset,2,"S")
			screen.drawText(w/2+1+shadingOffset,2,"W")
		elseif compassDegrees<290 then
			screen.drawText(w/2-2+shadingOffset,2,"W")
		else
			screen.drawText(w/2-5+shadingOffset,2,"N")
			screen.drawText(w/2+1+shadingOffset,2,"W")
		end
	end
end
local function drawTarget(target) -- More creatures to be added: kraken
	if target.distance<=RadarRange then
		local targetX,targetY=map.mapToScreen(StoredX,StoredY,Zoom,w,h,target.x,target.y)
		local dx=target.x-GpsX
		local dy=target.y-GpsY
		local targetDistance=math.sqrt(dx^2+dy^2)/1000
		local targetBearing=(math.deg(math.atan(dx,dy))+360)%360

		local alpha=math.max(50,target.time*255)
		local alignX=(targetX<w/2) and 1 or -1
		local offsetY=(targetY<h/2) and -3 or 6
		local offsetY2=(targetY<h/2) and -10 or 13
		local textWidth=(string.len(string.format("%.0f",targetBearing)))*5
		if target.toggle then
			screen.setColor(0,0,0,alpha)
			screen.drawTextBox(targetX-11,targetY-offsetY,25,5,string.format("%.1f",targetDistance),alignX)
			screen.drawTextBox(targetX-11,targetY-offsetY2,25,5,string.format("%.0f",targetBearing),alignX)
			if alignX==-1 then
				screen.drawRectF(targetX-11+textWidth-1,targetY-offsetY2,1,1)
				screen.drawRectF(targetX-11+textWidth,targetY-offsetY2-1,1,1)
				screen.drawRectF(targetX-11+textWidth+1,targetY-offsetY2,1,1)
				screen.drawRectF(targetX-11+textWidth,targetY-offsetY2+1,1,1)
			else
				screen.drawRectF(targetX+14,targetY-offsetY2,1,1)
				screen.drawRectF(targetX+15,targetY-offsetY2-1,1,1)
				screen.drawRectF(targetX+16,targetY-offsetY2,1,1)
				screen.drawRectF(targetX+15,targetY-offsetY2+1,1,1)
			end
		end

		local roundedMass=math.floor(target.mass+0.5)
		if roundedMass==25 then -- player or NPC
			screen.setColor(255,170,0,alpha)
		elseif roundedMass==500 then -- shark
			screen.setColor(0,85,255,alpha)
		elseif roundedMass==2500 then -- whale
			screen.setColor(0,255,255,alpha)
		elseif roundedMass==60500 then -- megalodon
			screen.setColor(150,0,255,alpha)
		else
			screen.setColor(255,0,0,alpha)
		end

		if target.toggle then
			screen.drawTextBox(targetX-12,targetY-offsetY,25,5,string.format("%.1f",targetDistance),alignX)
			screen.drawTextBox(targetX-12,targetY-offsetY2,25,5,string.format("%.0f",targetBearing),alignX)
			if alignX==-1 then
				screen.drawRectF(targetX-12+textWidth-1,targetY-offsetY2,1,1)
				screen.drawRectF(targetX-12+textWidth,targetY-offsetY2-1,1,1)
				screen.drawRectF(targetX-12+textWidth+1,targetY-offsetY2,1,1)
				screen.drawRectF(targetX-12+textWidth,targetY-offsetY2+1,1,1)
			else
				screen.drawRectF(targetX+13,targetY-offsetY2,1,1)
				screen.drawRectF(targetX+14,targetY-offsetY2-1,1,1)
				screen.drawRectF(targetX+15,targetY-offsetY2,1,1)
				screen.drawRectF(targetX+14,targetY-offsetY2+1,1,1)
			end
		end
		screen.drawRectF(targetX,targetY,2,2)
	end
end

-- onTick functions

local function isPointInRectangle(x,y,rectX,rectY,rectW,rectH)
	return x>rectX and y>rectY and x<rectX+rectW and y<rectY+rectH
end
local function round(value)
	value=math.floor(value+0.5)
	return value
end
local function clamp(value,min,max)
	value=math.max(min,math.min(value,max))
	return value
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
local function createPushToToggle()
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
local function createMemoryGate()
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
local function createUpDown(startValue)
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
local function waypointDistance(gpsX,gpsY,waypointX,waypointY,speed)
	local differenceX=waypointX-gpsX
	local differenceY=waypointY-gpsY
	local distance=clamp(math.sqrt(differenceX*differenceX+differenceY*differenceY)/1000,0,256)
	local estimate=clamp((distance/(speed*3.6))*60,0,999)
	return distance,estimate
end

local dataButtonPushToToggle=createPushToToggle()
local drawLinePushToToggle=createPushToToggle()
local zoomUpDown=createUpDown(1)
local zoomTimeMultiplierUpDown=createUpDown(1)
local upDownMovement=createUpDown(0)
local leftRightMovement=createUpDown(0)
local scrollUpDown=createUpDown(0)
local storeX=createMemoryGate()
local storeY=createMemoryGate()
local linePulse=createPulse()

TargetList={}

w=0
h=0
StoredX=0
StoredY=0
DrawLineToggle=false
MapMovement="GPS" -- GPS/Touchscreen

FOV=property.getNumber("FOV")
UiR=property.getNumber("UI R")
UiG=property.getNumber("UI G")
UiB=property.getNumber("UI B")
PointerR=property.getNumber("Pointer R")
PointerG=property.getNumber("Pointer G")
PointerB=property.getNumber("Pointer B")
LineR=property.getNumber("Line R")
LineG=property.getNumber("Line G")
LineB=property.getNumber("Line B")
PropertyMultiplierX=property.getNumber("X movement multiplier")
PropertyMultiplierY=property.getNumber("Y movement multiplier")
ZoomMultiplier=property.getNumber("Zoom multiplier") -- Zoom of 1 equals to 1km from center to edge of screen.
SpeedThreshold=property.getNumber("Minimum speed for time estimate (m/s)")

IsOverlayEnabled=property.getBool("Compass overlay")
PointerType=property.getBool("Pointer") -- off=square on=triangle
MapMovementSquarePointer=property.getBool("Square pointer during map movement")

function onTick()
	local radarDistance=input.getNumber(1)
	local radarSignalStrength=input.getNumber(2)

	GpsX=input.getNumber(3)
	GpsY=input.getNumber(4)
	local compass=input.getNumber(5)
	CompassDegrees=(-compass*360+360)%360
	Speed=input.getNumber(6)

	local inputX=input.getNumber(7)
	local inputY=input.getNumber(8)
	WaypointX=input.getNumber(9)
	WaypointY=input.getNumber(10)

	local radarYaw=input.getNumber(11)
	RadarRange=input.getNumber(12)
	local radarElevation=input.getNumber(13)

	local targetDetected=input.getBool(1)
	local isPressed=input.getBool(2)

	VerticalGap=clamp((h/32-1),0,2)*2

	local up=isPressed and isPointInRectangle(inputX,inputY,-1,-1,w+1,h/2-1)
	local down=isPressed and isPointInRectangle(inputX,inputY,-1,h/2+1,w+1,h/2-1)

	local anyTargetsPressed=false
	for i=1,#TargetList do
		local buttonX,buttonY=map.mapToScreen(StoredX,StoredY,Zoom,w,h,TargetList[i].x,TargetList[i].y)
		local buttonsPressed=(isPointInRectangle(inputX,inputY,w-7,h-8,8,9) or isPointInRectangle(inputX,inputY,w-14,h-8,8,9) or
							isPointInRectangle(inputX,inputY,w-20,h-8,7,9) or isPointInRectangle(inputX,inputY,w-26,h-8,7,9) or
							isPointInRectangle(inputX,inputY,w-32,h-8,7,9))
		local targetPressed=isPressed and isPointInRectangle(inputX,inputY,buttonX-2,buttonY-2,5,5) and not buttonsPressed
		TargetList[i].toggle=TargetList[i].toggleFunction(targetPressed)
		if targetPressed then
			anyTargetsPressed=true
		end
	end

	local dataMode=isPressed and isPointInRectangle(inputX,inputY,w-26,h-8,7,9)
	DataScreenToggle=dataButtonPushToToggle(dataMode)

	if not DataScreenToggle then
		local left=isPressed and isPointInRectangle(inputX,inputY,-1,-1,w/2-1,h+1)
		local right=isPressed and isPointInRectangle(inputX,inputY,w/2+1,-1,w+1,h+1)

		ZoomDecrease=isPressed and isPointInRectangle(inputX,inputY,w-7,h-8,8,9)
		ZoomIncrease=isPressed and isPointInRectangle(inputX,inputY,w-14,h-8,8,9)
		local zoomTimeMultiplier=zoomTimeMultiplierUpDown(false,ZoomDecrease or ZoomIncrease,0.1,1,3,not (ZoomDecrease or ZoomIncrease))
		Zoom=zoomUpDown(ZoomIncrease,ZoomDecrease,0.03*zoomTimeMultiplier*ZoomMultiplier,0.1,50,false)

		ResetMovement=isPressed and isPointInRectangle(inputX,inputY,w-20,h-8,7,9)

		local drawLine=isPressed and isPointInRectangle(inputX,inputY,w-32,h-8,7,9)
		local drawLinePulse=false
		if WaypointX==0 and WaypointY==0 then
			drawLine=false
			if DrawLineToggle then
				drawLinePulse=true
			end
		end
		DrawLineToggle=drawLinePushToToggle(drawLine or linePulse(drawLinePulse))

		local notAnyButton=not (dataMode or ResetMovement or drawLine or ZoomIncrease or ZoomDecrease or anyTargetsPressed)

		if (left or right or up or down) and notAnyButton then
			MapMovement="Touchscreen"
		end
		if ResetMovement then
			MapMovement="GPS"
		end

		local movementMultiplierX=math.abs((w/2-inputX)*Zoom*PropertyMultiplierX)
		local movementMultiplierY=math.abs((h/2-inputY)*Zoom*PropertyMultiplierY)

		local movementX=leftRightMovement(left and notAnyButton,right and notAnyButton,0.5*movementMultiplierX,-128000-GpsX,128000-GpsX,ResetMovement)
		local movementY=upDownMovement(down and notAnyButton,up and notAnyButton,0.5*movementMultiplierY,-128000-GpsY,128000-GpsY,ResetMovement)

		StoredX=storeX(GpsX,MapMovement=="GPS",ResetMovement,GpsX)+movementX
		StoredY=storeY(GpsY,MapMovement=="GPS",ResetMovement,GpsY)+movementY

		PointerX,PointerY=map.mapToScreen(StoredX,StoredY,Zoom,w,h,GpsX,GpsY)
		ScreenWaypointX,ScreenWaypointY=map.mapToScreen(StoredX,StoredY,Zoom,w,h,WaypointX,WaypointY)
	else
		Distance,Estimate=waypointDistance(GpsX,GpsY,WaypointX,WaypointY,Speed)
		if h<35 then
			ScrollY=scrollUpDown(down and not dataMode,up and not dataMode,1,-21,0,WaypointX==0 and WaypointY==0)
		else
			ScrollY=0
		end
	end

	for k,v in ipairs(TargetList) do
		v.time=v.time-0.001
		if v.time<=0 then
			table.remove(TargetList,k)
		end
	end
	if targetDetected then
		local horizontalDistance=radarDistance*math.cos(radarElevation*math.pi*2)
		local radarAzimuth=(radarYaw-FOV*0.5+0.5)%1-0.5 -- This is for a clockwise rotating radar. Change it if you change radar rotation.
		local angle=radarAzimuth*math.pi*2
		local radarX=GpsX+horizontalDistance*math.sin(angle)
		local radarY=GpsY+horizontalDistance*math.cos(angle)
		table.insert(TargetList,{distance=radarDistance,x=radarX,y=radarY,mass=radarDistance*radarSignalStrength,time=1,toggle=false,toggleFunction=createPushToToggle()})
	end
	output.setNumber(1,(radarYaw+compass+0.5)%1-0.5)
end
function onDraw()
	w=screen.getWidth()
	h=screen.getHeight()

	screen.setColor(15,15,15)
	screen.drawClear()

	local waypointSet=not (WaypointX==0 and WaypointY==0)

	if not DataScreenToggle then
		screen.setMapColorOcean(0,0,0,2)
		screen.setMapColorShallows(0,0,0,40)
		screen.setMapColorLand(0,0,0,100)
		screen.setMapColorGrass(0,0,0,100)
		screen.setMapColorSand(0,0,0,100)
		screen.setMapColorSnow(0,0,0,200)
		screen.setMapColorRock(0,0,0,60)
		screen.setMapColorGravel(0,0,0,120)
		screen.drawMap(StoredX,StoredY,Zoom)

		for k,v in ipairs(TargetList) do
			drawTarget(v)
		end

		if DrawLineToggle then
			screen.setColor(LineR,LineG,LineB)
			screen.drawLine(PointerX,PointerY,ScreenWaypointX,ScreenWaypointY)
		end
		if waypointSet then
			screen.setColor(255,127,0)
			screen.drawRectF(ScreenWaypointX,ScreenWaypointY,2,2)
		end

		screen.setColor(0,0,0)
		drawCompassOverlay(CompassDegrees,1,IsOverlayEnabled)
		if waypointSet then
			screen.drawText(w-29,h-6,"L")
		end
		screen.drawText(w-17,h-6,"R")
		screen.drawLine(w-11,h-4,w-6,h-4)
		screen.drawLine(w-9,h-6,w-9,h-1)
		screen.drawLine(w-4,h-4,w,h-4)

		screen.setColor(UiR,UiG,UiB)
		drawCompassOverlay(CompassDegrees,0,IsOverlayEnabled)


		if waypointSet then
			screen.setColor(getHighlightColor(DrawLineToggle))
			screen.drawText(w-30,h-6,"L")
		end

		screen.setColor(getHighlightColor(ResetMovement))
		screen.drawText(w-18,h-6,"R")

		screen.setColor(getHighlightColor(ZoomIncrease))
		screen.drawLine(w-12,h-4,w-7,h-4)
		screen.drawLine(w-10,h-6,w-10,h-1)

		screen.setColor(getHighlightColor(ZoomDecrease))
		screen.drawLine(w-5,h-4,w-1,h-4)

		screen.setColor(PointerR,PointerG,PointerB)
		if PointerType then
			drawTrianglePointer(PointerX,PointerY,CompassDegrees)
		else
			if MapMovement=="GPS" then
				screen.drawRectF(w/2-1,h/2-1,2,2)
			else
				screen.drawRectF(PointerX,PointerY,2,2)
			end
		end
		if MapMovement=="Touchscreen" and MapMovementSquarePointer==true then
			screen.drawRectF(w/2-1,h/2-1,2,2)
		end
	else
		local digitCount=string.len(string.format("%.0f",CompassDegrees))
		screen.setColor(0,0,0)
		screen.drawTextBox(w/2-17,2+ScrollY,35,5,string.format("%.0f",GpsX),0)
		screen.drawTextBox(w/2-17,9+ScrollY+VerticalGap,35,5,string.format("%.0f",GpsY),0)
		screen.drawTextBox(w/2-7,16+ScrollY+VerticalGap*2,15,5,string.format("%.0f",CompassDegrees),0)
		screen.drawCircle((w/2-7)+round((15-digitCount*5)/2)+(digitCount*5+1),16+ScrollY+VerticalGap*2,1)-- Formula for textBox center alignment, alignedX=textBoxX+(textBoxWidth-textWidth)/2
		if waypointSet then
			screen.drawTextBox(w/2-14,23+ScrollY+VerticalGap*3,30,5,string.format("%.".. 3-string.len(math.floor(Distance)) .."f",Distance).."km",0) -- Depending on digit count the number will have more or less decimal places
			if Speed>SpeedThreshold then
				screen.drawTextBox(w/2-9,30+ScrollY+VerticalGap*4,20,5,string.format("%.0f",Estimate).."m",0)
			end
		end

		screen.setColor(UiR,UiG,UiB)
		screen.drawTextBox(w/2-18,2+ScrollY,35,5,string.format("%.0f",GpsX),0)
		screen.drawTextBox(w/2-18,9+ScrollY+VerticalGap,35,5,string.format("%.0f",GpsY),0)
		screen.drawTextBox(w/2-8,16+ScrollY+VerticalGap*2,15,5,string.format("%.0f",CompassDegrees),0)
		screen.drawCircle((w/2-8)+round((15-digitCount*5)/2)+(digitCount*5+1),16+ScrollY+VerticalGap*2,1)
		if waypointSet then
			screen.drawTextBox(w/2-15,23+ScrollY+VerticalGap*3,30,5,string.format("%.".. 3-string.len(math.floor(Distance)) .."f",Distance).."km",0)
			if Speed>SpeedThreshold then
				screen.drawTextBox(w/2-10,30+ScrollY+VerticalGap*4,20,5,string.format("%.0f",Estimate).."m",0)
			end
		end

		-- Invisible rectangles
		screen.setColor(15,15,15)
		screen.drawRectF(0,0,32,2)
		screen.drawRectF(0,h-9,32,9)
	end
	screen.setColor(0,0,0)
	screen.drawText(w-23,h-6,"D")
	screen.setColor(getHighlightColor(DataScreenToggle))
	screen.drawText(w-24,h-6,"D")
end