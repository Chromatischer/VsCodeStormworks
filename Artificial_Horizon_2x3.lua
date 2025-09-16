-- Author: Chromatischer
-- GitHub: https://github.com/Chromatischer
-- Workshop: https://shorturl.at/acefr

--Discord: @chromatischer--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA

--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
	---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
	simulator = simulator
	simulator:setScreen(1, "3x2")
	simulator:setProperty("ExampleNumberProperty", 123)

	-- Runs every tick just before onTick; allows you to simulate the inputs changing
	---@param simulator Simulator Use simulator:<function>() to set inputs etc.
	---@param ticks     number Number of ticks since simulator started
	function onLBSimulatorTick(simulator, ticks)
		-- touchscreen defaults
		local screenConnection = simulator:getTouchScreen(1)
		simulator:setInputNumber(1, (simulator:getSlider(1) * 0.5) - 0.25) -- pitch
		simulator:setInputNumber(2, (simulator:getSlider(2) * 0.5) - 0.25) -- roll
		simulator:setInputNumber(3, simulator:getSlider(3) * 1000) -- altitude
		simulator:setInputNumber(4, simulator:getSlider(4) * 100) -- speed
		simulator:setInputNumber(5, (simulator:getSlider(5) * 1) - 0.5) -- heading
		simulator:setInputNumber(6, (simulator:getSlider(5) * 0.5) - 0.25) -- direction
	end
end
---@endsection

require("Utils")
require("StringFormatUtils")
require("RoundToDecimalUtil")
require("Color_Lerp")
debug = false

ticks = 0
lastSpeed = 0
lastAltimeter = 0
maxSpeedDiff = 1
maxAltimeterDiff = 1
enableShadow = false
function onTick()
	ticks = ticks + 1
	pitch = input.getNumber(1) * 360
	--pitch = 0
	roll = input.getNumber(2) * 360
	altimeter = input.getNumber(3)
	speed = input.getNumber(4)
	heading = input.getNumber(5) * 360 + 180
	flightDirection = input.getNumber(6) * 360

	speedDiff = lastSpeed - speed
	altimeterDiff = lastAltimeter - altimeter
	lastSpeed = speed
	lastAltimeter = altimeter

	if debug then
		print(
			"pitch: [" .. pitch .. "] speed: [" .. speed .. "] altitude: [" .. altimeter .. "] roll: [" .. roll .. "]"
		)
	end
end

function onDraw()
	Swidth = screen.getWidth()
	Sheight = screen.getHeight()
	screenCenterX = Swidth / 2
	screenCenterY = Sheight / 2

	--#region stupid line math I got from here: https://www.youtube.com/watch?v=n8yQDCTYuns dont ask!
	linePitch = math.acos(pitch / 180)
	lineRoll = math.rad(90 - roll)

	topRoll = math.rad(-roll)
	bottomRoll = math.rad(180 - roll)

	lineRadius = Swidth * 2

	x1 = screenCenterX + lineRadius * math.cos(lineRoll + linePitch)
	y1 = screenCenterY + lineRadius * math.sin(lineRoll + linePitch)
	x2 = screenCenterX + lineRadius * math.cos(lineRoll - linePitch)
	y2 = screenCenterY + lineRadius * math.sin(lineRoll - linePitch)

	x3 = screenCenterX + lineRadius * math.cos(topRoll - linePitch)
	y3 = screenCenterY + lineRadius * math.sin(topRoll - linePitch)

	x4 = screenCenterX + lineRadius * math.cos(bottomRoll - linePitch)
	y4 = screenCenterY + lineRadius * math.sin(bottomRoll - linePitch)
	--#endregion

	--#region drawing the artificaial moving horizon
	screen.setColor(40, 114, 151) -- Blue
	screen.drawTriangleF(x1, y1 + 1, x2, y2 + 1, x3, y3)

	screen.setColor(161, 70, 22) -- Orange
	screen.drawTriangleF(x1, y1 + 1, x2, y2 + 1, x4, y4)

	screen.setColor(150, 150, 150)
	screen.drawLine(x1, y1, x2, y2)
	--#endregion

	--#region steady Indicator
	if speed > 12 then
		steadyIndicatorWidth = 4
		steadyIndicatorHeight = 7
		steadyIndicatorLength = 15

		screen.setColor(255, 255, 255)
		screen.drawLine(
			screenCenterX + steadyIndicatorWidth,
			screenCenterY,
			screenCenterX,
			screenCenterY + steadyIndicatorHeight
		)
		screen.drawLine(
			screenCenterX - steadyIndicatorWidth,
			screenCenterY,
			screenCenterX,
			screenCenterY + steadyIndicatorHeight
		)
		screen.drawLine(
			screenCenterX - steadyIndicatorWidth,
			screenCenterY,
			screenCenterX - steadyIndicatorWidth - steadyIndicatorLength,
			screenCenterY
		)
		screen.drawLine(
			screenCenterX + steadyIndicatorWidth,
			screenCenterY,
			screenCenterX + steadyIndicatorWidth + steadyIndicatorLength,
			screenCenterY
		)
	else
		relativeFlightDirection = flightDirection - heading
		speedY = speed * math.cos(math.rad(relativeFlightDirection))
		speedX = speed * math.sin(math.rad(relativeFlightDirection))
		dirIndicatorLength = 32
		dirIndicatorMinLength = 5
		maxSpeed = 12
		maxVSpeed = 1
		lineAngleGap = 50
		isFullHovering = math.abs(speedX) < 0.1 * maxSpeed
			and math.abs(speedY) < 0.1 * maxSpeed
			and math.abs(-altimeterDiff) < 0.1 * maxVSpeed

		lineLengthX =
			math.clamp((math.abs(speedX) / maxSpeed) * dirIndicatorLength, dirIndicatorMinLength, dirIndicatorLength)
		lineLengthX = speedX < 0 and -lineLengthX or lineLengthX
		lineLengthY =
			math.clamp((math.abs(speedY) / maxSpeed) * dirIndicatorLength, dirIndicatorMinLength, dirIndicatorLength)
		lineLengthY = speedY < 0 and -lineLengthY or lineLengthY
		lineLengthZ = math.clamp(
			(math.abs(-altimeterDiff) / maxVSpeed) * dirIndicatorLength,
			dirIndicatorMinLength,
			dirIndicatorLength
		)
		lineLengthZ = -altimeterDiff < 0 and lineLengthZ or -lineLengthZ

		screen.setColor(230, 88, 27) -- Red
		x1 = lineLengthX * math.sin(math.rad(lineAngleGap))
		y1 = lineLengthX * math.cos(math.rad(lineAngleGap))
		screen.drawLine(screenCenterX, screenCenterY, screenCenterX + x1, screenCenterY + y1)
		offsetPositionX = speedX > 0 and 1 or -4
		offsetPositionY = speedX > 0 and 1 or -6
		if not isFullHovering then
			screen.drawText(screenCenterX + x1 + offsetPositionX, screenCenterY + y1 + offsetPositionY, "F")
		end

		screen.setColor(18, 232, 98) -- Green
		screen.drawLine(screenCenterX, screenCenterY, screenCenterX, screenCenterY + lineLengthZ)
		offsetZPositionX = -altimeterDiff > 0 and -1 or -1
		offsetZPositionY = -altimeterDiff > 0 and -6 or 1
		if not isFullHovering then
			screen.drawText(screenCenterX + offsetZPositionX, screenCenterY + lineLengthZ + offsetZPositionY, "H")
		end

		screen.setColor(18, 187, 232) -- Blue
		x2 = lineLengthY * math.sin(math.rad(360 - lineAngleGap))
		y2 = lineLengthY * math.cos(math.rad(360 - lineAngleGap))
		screen.drawLine(screenCenterX, screenCenterY, screenCenterX + x2, screenCenterY + y2)
		offsetYPositionX = speedY > 0 and -5 or 1
		offsetYPositionY = speedY > 0 and 1 or -6
		if not isFullHovering then
			screen.drawText(screenCenterX + x2 + offsetYPositionX, screenCenterY + y2 + offsetYPositionY, "S")
		end

		if isFullHovering then
			screen.setColor(230, 107, 21) -- Yellow
			screen.drawCircle(screenCenterX, screenCenterY, dirIndicatorMinLength)
			screen.drawText(screenCenterX + 6, screenCenterY + 6, "HVR")
			screen.drawLine(screenCenterX - 7, screenCenterY + 7, screenCenterX + 7, screenCenterY - 7)
		end
	end
	--#endregion

	--#region speedIndicator
	screen.setColor(0, 0, 0, 100)
	screen.drawRectF(-1, screenCenterY - 17, 19, 35)

	screen.setColor(0, 0, 0)
	screen.drawRectF(0, screenCenterY - 4, 17, 8)

	screen.setColor(255, 255, 255)
	screen.drawRect(0, screenCenterY - 4, 17, 8)
	screen.drawText(-3, screenCenterY - 2, string.formatNumberAsInteger(speed * 3.6, 3, " "))
	screen.setColor(200, 200, 200)
	screen.drawText(
		-3,
		screenCenterY - 10,
		string.formatNumberAsInteger(math.roundToDecimal(speed * 3.6 + 10, -1), 3, " ")
	)
	screen.drawText(
		-3,
		screenCenterY - 16,
		string.formatNumberAsInteger(math.roundToDecimal(speed * 3.6 + 20, -1), 3, " ")
	)
	if speed * 3.6 > 20 then
		screen.drawText(
			-3,
			screenCenterY + 6,
			string.formatNumberAsInteger(math.roundToDecimal(speed * 3.6 - 10, -1), 3, " ")
		)
		screen.drawText(
			-3,
			screenCenterY + 12,
			string.formatNumberAsInteger(math.roundToDecimal(speed * 3.6 - 20, -1), 3, " ")
		)
	end

	drawThingIndicator(14, screenCenterY, 20, math.clamp(speedDiff / maxSpeedDiff, -1, 1), false, enableShadow)
	--#endregion

	--#region altitudeIndicator
	screen.setColor(0, 0, 0, 100)
	screen.drawRectF(Swidth - 23, screenCenterY - 17, 23, 35)

	screen.setColor(0, 0, 0)
	screen.drawRectF(Swidth - 23, screenCenterY - 4, 22, 8)

	screen.setColor(255, 255, 255)
	screen.drawRect(Swidth - 23, screenCenterY - 4, 22, 8)
	screen.drawText(Swidth - 21, screenCenterY - 2, string.formatNumberAsInteger(altimeter, 4, "0"))
	screen.setColor(200, 200, 200)
	screen.drawText(
		Swidth - 21,
		screenCenterY - 10,
		string.formatNumberAsInteger(math.roundToDecimal(altimeter + 100, -2), 4, "0")
	)
	screen.drawText(
		Swidth - 21,
		screenCenterY - 16,
		string.formatNumberAsInteger(math.roundToDecimal(altimeter + 200, -2), 4, "0")
	)
	if altimeter > 200 then
		screen.drawText(
			Swidth - 21,
			screenCenterY + 6,
			string.formatNumberAsInteger(math.roundToDecimal(altimeter - 100, -2), 4, "0")
		)
		screen.drawText(
			Swidth - 21,
			screenCenterY + 12,
			string.formatNumberAsInteger(math.roundToDecimal(altimeter - 200, -2), 4, "0")
		)
	end

	drawThingIndicator(
		14,
		screenCenterY,
		Swidth - 26,
		math.clamp(altimeterDiff / maxAltimeterDiff, -1, 1),
		true,
		enableShadow,
		math.abs(altimeterDiff) < 0.1 * maxAltimeterDiff
	)
	--#endregion

	--#region headingIndicator
	screen.setColor(0, 0, 0, 100)
	screen.drawRectF(0, 0, Swidth, 9)
	screen.setColor(0, 0, 0)
	screen.drawRectF(screenCenterX - 9, 0, 17, 8)
	screen.setColor(255, 255, 255)
	screen.drawRect(screenCenterX - 9, 0, 17, 8)
	screen.drawText(screenCenterX - 7, 2, string.formatNumberAsInteger(heading, 3, "0"))
	--#endregion

	--#region Pitchrose or something

	fullCircle = 270
	circleOffset = 270 + (360 - fullCircle) / 4
	roseCenterX = screenCenterX
	roseCenterY = screenCenterY + 15
	outerCircleRadius = 15

	--#region small Lines
	screen.setColor(255, 255, 255)
	smallLines = 6
	for i = 0, smallLines, 1 do
		innerCircleRadius = 12

		roseAngle = circleOffset + i * (fullCircle / (smallLines * 2))
		x1 = roseCenterX + innerCircleRadius * math.sin(math.rad(roseAngle))
		y1 = roseCenterY + innerCircleRadius * math.cos(math.rad(roseAngle))
		x2 = roseCenterX + outerCircleRadius * math.sin(math.rad(roseAngle))
		y2 = roseCenterY + outerCircleRadius * math.cos(math.rad(roseAngle))
		screen.drawLine(x1, y1, x2, y2)
	end
	--#endregion

	--#region large Lines
	screen.setColor(255, 255, 255)
	largeLines = 2
	for i = 0, largeLines, 1 do
		innerCircleRadius = 10

		roseAngle = circleOffset + i * (fullCircle / (largeLines * 2))
		x1 = roseCenterX + innerCircleRadius * math.sin(math.rad(roseAngle))
		y1 = roseCenterY + innerCircleRadius * math.cos(math.rad(roseAngle))
		x2 = roseCenterX + outerCircleRadius * math.sin(math.rad(roseAngle))
		y2 = roseCenterY + outerCircleRadius * math.cos(math.rad(roseAngle))
		screen.drawLine(x1, y1, x2, y2)
	end
	--#endregion

	--#region indicator I think
	screen.setColor(255, 44, 32)
	roseIndicatorSize = 10
	roseOffsetAngle = 0.65
	x1 = roseCenterX + 4 * math.sin(math.rad(-roll) + roseOffsetAngle)
	y1 = roseCenterY + 4 * math.cos(math.rad(-roll) + roseOffsetAngle)
	x2 = roseCenterX + 4 * math.sin(math.rad(-roll) - roseOffsetAngle)
	y2 = roseCenterY + 4 * math.cos(math.rad(-roll) - roseOffsetAngle)
	x3 = roseCenterX + roseIndicatorSize * math.sin(math.rad(-roll))
	y3 = roseCenterY + roseIndicatorSize * math.cos(math.rad(-roll))
	screen.drawTriangleF(x3, y3, x1, y1, x2, y2)
	--#endregion
	--#endregion
end

function drawThingIndicator(
	speedGainIndicatorLength,
	speedGainIndicatorCenterY,
	speedGainIndicatorCenterX,
	speedDiffFactor,
	shadowToLeft,
	enableShadow,
	isGrayScale
)
	speedGainIndicatorColorOutside = isGrayScale and { r = 60, g = 60, b = 60 } or { r = 255, g = 0, b = 0 }
	speedGainIndicatorColorInside = isGrayScale and { r = 20, g = 20, b = 20 } or { r = 0, g = 255, b = 0 }

	if enableShadow then
		screen.setColor(0, 0, 0, 100)
		if not shadowToLeft then
			screen.drawRectF(
				speedGainIndicatorCenterX,
				speedGainIndicatorCenterY - speedGainIndicatorLength + 1,
				2,
				2 * speedGainIndicatorLength
			)
		else
			screen.drawRectF(
				speedGainIndicatorCenterX - 1,
				speedGainIndicatorCenterY - speedGainIndicatorLength + 1,
				2,
				2 * speedGainIndicatorLength
			)
		end
	end
	for o = 0, 1, 1 do
		for i = 0, speedGainIndicatorLength - 1, 1 do
			currFactor = i / (speedGainIndicatorLength - 1)
			lerpedColor = colorLerp(speedGainIndicatorColorInside, speedGainIndicatorColorOutside, currFactor)
			screen.setColor(lerpedColor.r, lerpedColor.g, lerpedColor.b)
			screen.drawRectF(speedGainIndicatorCenterX, speedGainIndicatorCenterY + i * (o == 0 and -1 or 1), 1, 1)
		end
	end

	speedDiffColor = colorLerp(speedGainIndicatorColorInside, speedGainIndicatorColorOutside, math.abs(speedDiffFactor))
	screen.setColor(speedDiffColor.r, speedDiffColor.g, speedDiffColor.b)
	screen.drawRectF(
		speedGainIndicatorCenterX - 1,
		speedGainIndicatorCenterY + speedDiffFactor * speedGainIndicatorLength,
		3,
		1
	)
end
