function linearInterpolation(x,x1,x2,y1,y2)
	return y1+((x-x1)*(y2-y1)/(x2-x1))
end
function clamp(value,min,max)
	value=math.max(min,math.min(value,max))
	return value
end
function round(value)
	value=math.floor(value+0.5)
	return value
end
function timer()
	local counter=0
	return function(reset)
		if reset then
			counter=0
		else
			counter=counter+1
		end
		return counter
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
function gravityUpDown()
	local counter=0
	return function(jump,reset)
		counter=counter+0.125
		counter=counter-jump
		if reset then
			counter=0
		end
		counter=clamp(counter,-14,16)
		return counter
	end
end
function obstacleLeftRight()
	local counter=33
	return function(reset)
		local resetPulse=false
		counter=counter-0.25
		if counter==-3 or reset then
			resetPulse=true
			counter=33
		end
		return counter,resetPulse
	end
end
function pseudoRandomTable()
	local counter=1
	local pseudoRandomY={}
	pseudoRandomY[1]=15
	pseudoRandomY[2]=5
	pseudoRandomY[3]=3
	pseudoRandomY[4]=7
	pseudoRandomY[5]=17
	pseudoRandomY[6]=20
	pseudoRandomY[7]=16
	pseudoRandomY[8]=10
	pseudoRandomY[9]=9
	pseudoRandomY[10]=12
	return function(increment)
		if increment then
			counter=counter+1
			if counter==10 then
				counter=1
			end
		end
		return pseudoRandomY[counter]
	end
end
function detectionHelper(aX1,aX2,aY1,aY2,bX1,bX2,bY1,bY2)
	local overlap=not(aX1>bX2 or aX2<bX1 or aY2<bY1 or aY1>bY2)
	return overlap
end
function collisionDetection(playerX,playerY,bothObstacleX,upperObstacleLowerY,lowerObstacleUpperY)
	local playerLeft=playerX
	local playerRight=playerX+2
	local playerUp=playerY
	local playerDown=playerY+2

	local upperObstacleLeft=bothObstacleX
	local upperObstacleRight=bothObstacleX+2
	local upperObstacleTop=0
	local upperObstacleBottom=upperObstacleLowerY

	local lowerObstacleLeft=bothObstacleX
	local lowerObstacleRight=bothObstacleX+2
	local lowerObstacleTop=lowerObstacleUpperY
	local lowerObstacleBottom=lowerObstacleUpperY+28

	local upperObstacleCollision=detectionHelper(playerLeft,playerRight,playerUp,playerDown,upperObstacleLeft,upperObstacleRight,upperObstacleTop,upperObstacleBottom)
	local lowerObstacleCollision=detectionHelper(playerLeft,playerRight,playerUp,playerDown,lowerObstacleLeft,lowerObstacleRight,lowerObstacleTop,lowerObstacleBottom)
	local collision=upperObstacleCollision or lowerObstacleCollision
	return collision
end
scoreTimer=timer()
isPressedPulse=createPulse()
gravityY=gravityUpDown()
obstacleX=obstacleLeftRight()
obstacleY=pseudoRandomTable()

gameMode="Start" -- "Start" "Game"

function onTick()
	local isPressed=input.getBool(1)
	touchButtonPulse=isPressedPulse(isPressed)

	if gameMode=="Start" then
		if touchButtonPulse then
			gameMode="Game"
		end
	end
	if gameMode=="Game" then
		if (playerY==30 or score==1000 or collision) then
			gameMode="Start"
		end

		local jump=(touchButtonPulse and 4) or 0
		playerY=clamp(14+gravityY(jump,gameMode~="Game"),0,30)

		score=scoreTimer(gameMode~="Game")
		score=round(score/60)

		rectangleX,rectanglePositionReset=obstacleX(gameMode~="Game")
		rectangleY=obstacleY(rectanglePositionReset)
		gap=round(linearInterpolation(score,0,999,10,8))

		collision=collisionDetection(1,round(playerY),round(rectangleX),rectangleY,rectangleY+gap)
	end
end
function onDraw()
	screen.setColor(15,15,15)
	screen.drawClear()
	if gameMode=="Start" then
		screen.setColor(0,0,0)
		screen.drawTextBox(1,6,32,10,"Press to start",0)
		screen.setColor(255,255,255)
		screen.drawTextBox(0,6,32,10,"Press to start",0)
	end
	if gameMode=="Game" then
		screen.setColor(5,5,5)
		screen.drawRectF(rectangleX,0,3,rectangleY)
		screen.drawRectF(rectangleX,rectangleY+gap,3,28)
		screen.setColor(0,0,0)
		screen.drawText(17,1,string.format("%03d",score))
		screen.setColor(255,255,255)
		screen.drawRectF(1,playerY,3,3)
		screen.drawText(16,1,string.format("%03d",score))
	end

end
