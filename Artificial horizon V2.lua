-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

-- Tables start at the lowest pitch line
PitchLineDistance={35,28,21,14,7,-7,-14,-21,-28,-35}
PitchLineHalfLength={6,5,4,3,2,2,3,4,5,6}

-- onDraw functions

function drawPitchLine(distance,halfLength,middleX,middleY,angle,perpendicularAngle,TopTilt)
	local adjustedX=middleX+distance*math.cos(perpendicularAngle)
	local adjustedY=middleY+distance*math.sin(perpendicularAngle)

	local pitchLineX1=adjustedX-halfLength*math.cos(angle)
	local pitchLineY1=adjustedY-halfLength*math.sin(angle)

	local pitchLineX2=adjustedX+halfLength*math.cos(angle)
	local pitchLineY2=adjustedY+halfLength*math.sin(angle)

	if TopTilt<0 then
		screen.drawLine(pitchLineX2,pitchLineY2,pitchLineX1,pitchLineY1)
	else
		screen.drawLine(pitchLineX1,pitchLineY1,pitchLineX2,pitchLineY2)
	end
end

function onTick()
	PitchDegrees=((input.getNumber(15)*4)*90)
	RollDegrees=((input.getNumber(16)*-4)*90)

	TopTilt=input.getNumber(18)
end
function onDraw()
	local w=screen.getWidth()
	local h=screen.getHeight()

	local pitchRadians=math.acos(PitchDegrees/180)
	local rollRadians=math.rad(90-RollDegrees)

	-- Roll applied to the top of the sky triangle and bottom of the ground triangle
	local topRoll=math.rad(0-RollDegrees)
	local bottomRoll=math.rad(180-RollDegrees)

	-- Swaps the sky and ground triangles depending on pitch from the top tilt sensor
	if TopTilt<0 then
		rollRadians=-rollRadians
	end

	local horizonRadius=w+h
	local centerX=w/2
	local centerY=h/2

	-- Coordinates of the center horizon line and sky/ground triangles
	local horizonLineX1=centerX+horizonRadius*math.cos(rollRadians+pitchRadians)
	local horizonLineY1=centerY+horizonRadius*math.sin(rollRadians+pitchRadians)

	local horizonLineX2=centerX+horizonRadius*math.cos(rollRadians-pitchRadians)
	local horizonLineY2=centerY+horizonRadius*math.sin(rollRadians-pitchRadians)

	-- Angle of horizon line, used to get a perpendicular angle
	local horizonLineMiddleX=(horizonLineX1+horizonLineX2)/2
	local horizonLineMiddleY=(horizonLineY1+horizonLineY2)/2

	local horizonAngle=math.atan(horizonLineY2-horizonLineY1,horizonLineX2-horizonLineX1)
	local horizonLinePerpendicularAngle=horizonAngle+math.pi/2

	-- Coordinates of the third point of sky/ground triangles that get inverted depending on TopTilt
	if TopTilt>=0 then
		SkyTriangleTopX=centerX+horizonRadius*math.cos(bottomRoll+pitchRadians)
		SkyTriangleTopY=centerY+horizonRadius*math.sin(bottomRoll+pitchRadians)
		GroundTriangleBottomX=centerX+horizonRadius*math.cos(topRoll+pitchRadians)
		GroundTriangleBottomY=centerY+horizonRadius*math.sin(topRoll+pitchRadians)
	else
		SkyTriangleTopX=centerX+horizonRadius*math.cos(-topRoll+pitchRadians)
		SkyTriangleTopY=centerY+horizonRadius*math.sin(-topRoll+pitchRadians)
		GroundTriangleBottomX=centerX+horizonRadius*math.cos(-bottomRoll+pitchRadians)
		GroundTriangleBottomY=centerY+horizonRadius*math.sin(-bottomRoll+pitchRadians)
	end

	-- Sky triangle
	screen.setColor(15,15,15)
	screen.drawTriangleF(horizonLineX1,horizonLineY1+1,horizonLineX2,horizonLineY2+1,SkyTriangleTopX,SkyTriangleTopY)
	-- Ground triangle
	screen.setColor(5,5,5)
	screen.drawTriangleF(horizonLineX1,horizonLineY1+1,horizonLineX2,horizonLineY2+1,GroundTriangleBottomX,GroundTriangleBottomY)

	-- Horizon line (adjusted by pitch and roll)
	screen.setColor(255,255,255)
	screen.drawLine(horizonLineX1,horizonLineY1,horizonLineX2,horizonLineY2)

	-- Pitch lines
	for i=1,10 do
		drawPitchLine(PitchLineDistance[i],PitchLineHalfLength[i],horizonLineMiddleX,horizonLineMiddleY,horizonAngle,horizonLinePerpendicularAngle,TopTilt)
	end

	-- Center line with a V notch (fixed position)
	screen.setColor(181,90,20,230)
	screen.drawLine(centerX-1,centerY+4,centerX-5,centerY) -- \
	screen.drawLine(centerX,centerY+4,centerX+4,centerY) -- /
	screen.drawLine(centerX-12,centerY,centerX-4,centerY) -- ---
	screen.drawLine(centerX+4,centerY,centerX+12,centerY) -- ---
end
