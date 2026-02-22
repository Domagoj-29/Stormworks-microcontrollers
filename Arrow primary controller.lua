function getHighlightColor(isSelected)
	if isSelected then
		return 120,0,0
	else
		return 8,255,8
	end
end
function createDelta()
	local oldVariable=0
	return function(variable)
		local delta=variable-oldVariable
		oldVariable=variable
		return delta
	end
end
function createTimer()
	local timerTime=0
	return function(enablePulse,duration,reset)
		if reset then
			timerTime=0
			return false,0
		end
		if enablePulse then
			timerTime=1
		end
		if timerTime>0 and timerTime<=duration then
			timerTime=timerTime+1
		end
		local timingComplete=(timerTime==duration)
		return timingComplete,timerTime
	end
end
function createPulse()
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
function linearInterpolation(x,x1,x2,y1,y2)
	return y1+((x-x1)*(y2-y1)/(x2-x1))
end
cycleZoomLevelsPulse=createPulse()
manualFirePulse=createPulse()
radarFirePulse=createPulse()
manualAimTimer=createTimer() -- Manual 10 seconds, radar 5 seconds
radarAimTimer=createTimer()
timerDelta=createDelta()
counter=0
squareSize=15
aimMode="Manual"
function onTick()
	local targetDistance=input.getNumber(1) -- in meters
	local azimuth=input.getNumber(2) -- in turns
	local elevation=input.getNumber(3) -- in turns
	local systemPower=input.getBool(1)
	local cycleZoomLevels=input.getBool(2)
	local radar=input.getBool(3)
	local manualFire=input.getBool(4)
	local targetDetected=input.getBool(5)

	local defaultZoom=0.6
	local maxZoom=0.85

	if not systemPower then
		aimMode="Off"
	elseif radar and systemPower then
		aimMode="Radar"
	else
		aimMode="Manual"
	end

	if aimMode=="Manual" then
		if cycleZoomLevelsPulse(cycleZoomLevels) then
			counter=counter+1
		end
		if counter>1 then
			counter=0
		end
		if counter==0 then
			zoom=defaultZoom
		else
			zoom=maxZoom
		end
		Fire,Timer=manualAimTimer(manualFirePulse(manualFire),600,not manualFire)
		Timer=(10-Timer/60) -- convert timer to seconds and counts from 10 to 0
	elseif aimMode=="Radar" then
		radarFire=radar and targetDetected
		Fire,Timer=radarAimTimer(radarFirePulse(radarFire),300,not radarFire)
		Timer=(5-Timer/60)

		-- Camera pivots
		cameraX=0
		cameraY=0
		-- Radar tests go here
		if radarFire then
			squareSize=squareSize-0.055
		else
			squareSize=15
		end
		squareSize=math.max(5,math.min(squareSize,15))
		zoom=linearInterpolation(squareSize,15,5,defaultZoom,maxZoom)

		local degreeFOV=((135-1.43)*(1-zoom))+1.43
		local degreeAzimuth=(azimuth*360)
		local degreeElevation=(elevation*360)
		targetX=(degreeAzimuth/degreeFOV)*32
		targetY=(degreeElevation/degreeFOV)*32
	end
	-- Outputs
	output.setNumber(1,cameraX)
	output.setNumber(2,cameraY)
	output.setNumber(3,zoom)
	output.setNumber(4,Timer)
	output.setBool(1,systemPower)
	output.setBool(2,Fire)
	output.setBool(3,radar)
	output.setBool(4,targetDetected)
end
function onDraw()
	local timerR,timerG,timerB=getHighlightColor(Timer<=2)
	screen.setColor(timerR,timerG,timerB,200)
	if aimMode=="Manual" then
		-- Semi transparent crosshair
		screen.drawRectF(15,15,2,2)
	end

	screen.setColor(timerR,timerG,timerB)
	-- Target Rectangle
	if aimMode=="Radar" and radarFire then
		screen.drawRect((15+targetX)-squareSize/2,(14-targetY)-squareSize/2,squareSize+2,squareSize+2)
	end
	-- Screen border
	screen.drawRect(0,0,31,31)
	if (timerDelta(Timer)<0 and not (Timer==5 or Timer==10)) then
		-- Timer text shading
		screen.setColor(0,0,0)
		screen.drawText(3,2,string.format("%.2f",Timer))
		-- Timer text
		screen.setColor(timerR,timerG,timerB)
		screen.drawText(2,2,string.format("%.2f",Timer))
	end
end