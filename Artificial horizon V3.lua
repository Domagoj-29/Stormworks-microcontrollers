-- Author: Domagoj29
-- GitHub: https://github.com/Domagoj-29
-- Workshop: https://steamcommunity.com/profiles/76561198935577915/myworkshopfiles/

-- Credits:
-- 1x1 Artificial Horizon v2: https://steamcommunity.com/sharedfiles/filedetails/?id=2312093019

-- Tables start at the lowest pitch line
PitchLineOffset={-90,-72,-54,-36,-18,0,18,36,54,72,90}
PitchLineHalfLength={6,5,4,3,2,20,2,3,4,5,6} -- "20" is the half length of the main pitch line, change it on higher resolutions

-- onDraw functions

local function drawHorizon(roll,pitch,centerX,centerY,w,h)
	local rollSin=math.sin(roll)
	local rollCos=math.cos(roll)
	local monitorDiagonal=math.sqrt(w^2+h^2)
	local inverseTangentFOV=h/math.tan(0.5)
	local maxDrawnPitchAngle=math.atan(monitorDiagonal/inverseTangentFOV)

	-- Pitch lines
	local function pitchLineEndpoints(halfLength,pitchAngle)
		local verticalShift=math.tan(pitchAngle)*inverseTangentFOV/2
		return centerX + halfLength*rollCos + verticalShift*rollSin, centerY + halfLength*rollSin - verticalShift*rollCos,
		centerX - halfLength*rollCos + verticalShift*rollSin,centerY - halfLength*rollSin - verticalShift*rollCos
	end
	local function drawPitchLine(offset,halfLength)
		offset=offset*math.pi/180+pitch
		if offset>-maxDrawnPitchAngle and offset<maxDrawnPitchAngle then
			screen.drawLine(pitchLineEndpoints(halfLength,offset))
		end
	end

	-- Ground
	screen.setColor(5,5,5)
	if pitch>=maxDrawnPitchAngle then
		screen.drawRectF(0,0,w,h)
	elseif pitch>-maxDrawnPitchAngle then
		local x1,y1,x2,y2=pitchLineEndpoints(monitorDiagonal,pitch)
		local x3,y3,x4,y4=pitchLineEndpoints(monitorDiagonal,-maxDrawnPitchAngle)
		screen.drawTriangleF(x1,y1+0.5,x2,y2+0.5,x3,y3+0.5)
		screen.drawTriangleF(x3,y3+0.5,x2,y2+0.5,x4,y4+0.5)
	end

	-- Drawing the pitch lines
	screen.setColor(255,255,255)
    for i=1,11 do
		drawPitchLine(PitchLineOffset[i],PitchLineHalfLength[i])
	end
end

function onTick()
	local tiltFront=input.getNumber(15)
	local tiltRight=input.getNumber(16)
	TiltUp=input.getNumber(18)

	Roll=math.atan(math.sin(tiltRight*math.pi*2),math.sin(TiltUp*math.pi*2))
	Pitch=tiltFront*math.pi*2
end
function onDraw()
	local w=screen.getWidth()
	local h=screen.getHeight()

	-- Sky
	screen.setColor(15,15,15)
	screen.drawRectF(0,0,w,h)

	if TiltUp<0 then
		drawHorizon(Roll,-Pitch,w/2,h/2,w,h)
	else
		drawHorizon(Roll,-Pitch,w/2-1,h/2-1,w,h)
	end

	-- Center line with a V notch (fixed position)
	screen.setColor(181,90,20,230)
	screen.drawLine(w/2-1,h/2+4,w/2-5,h/2) -- \
	screen.drawLine(w/2,h/2+4,w/2+4,h/2) -- /
	screen.drawLine(w/2-12,h/2,w/2-4,h/2) -- ---
	screen.drawLine(w/2+4,h/2,w/2+12,h/2) -- ---
end