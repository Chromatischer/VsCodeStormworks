-- Author: Chroma
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
--
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
    simulator:setScreen(1, "2x2")
    simulator:setScreen(2, "3x3")
    simulator:setScreen(3, "3x2")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.touchX)
        simulator:setInputNumber(2, screenConnection.touchY)
        simulator:setInputNumber(3,simulator:getSlider(1)*5000-2500)
        simulator:setInputNumber(4,simulator:getSlider(2)*5000-2500)
        simulator:setInputNumber(5,simulator:getSlider(3))
        simulator:setInputBool(2,simulator:getIsClicked(1))
        simulator:setInputBool(3,true)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

---TODO: [X] Add Desasters Be Gone Availability
---      [-] Switch to Coordinate class
---      [X] Test everything
---      [] Do the averaged part

require("Utils.Utils")
zooms = {0.1,0.2,0.5,1,2,5,10,15,20,25,30,40,50}
zoom = 4
pause_ticks_button = 0
ticks = 0
timeSinceLastPulse = 0
rangeToTransponder = 0
transponderPulsePositions = {}
approximations = {}
showTransponderLocation = true
buttons = {{x=2,y=2,string="+",funct = function ()
    zoom = zoom + 1 < #zooms and zoom + 1 or zoom
end}, {x=2,y=12,string="-",funct = function ()
    zoom = zoom - 1 > 0 and zoom -1 or zoom
end}, {x=2,y=23,string="T",funct = function ()
    showTransponderLocation = not showTransponderLocation
end}}
mapCenterX = 0
mapCenterY = 0
centerOnPlayer = true
changeTime = 50
function onTick()
    ticks = ticks + 1
    isPressed = input.getBool(1)
    transponderPulse = input.getBool(2)
    desasterActive = input.getBool(3)
    touchX = input.getNumber(1)
    touchY = input.getNumber(2)
    gpsX = input.getNumber(3)
    gpsY = input.getNumber(4)
    rotation = (input.getNumber(5) * 360) % 360
    desastersBGX = input.getNumber(6)
    desastersBGY = input.getNumber(7)

    if transponderPulse then
        -- always doing this calculation to save chars
        rangeToTransponder = math.clamp(timeSinceLastPulse * 50 - 250,250,110000) --clamped distance in meters between min 250 and max 110km
        --print(rangeToTransponder)
        timeSinceLastPulse = 0
        if #transponderPulsePositions > 1 then
            --distance from current to last greater then 100 meters
            if math.abs(math.sqrt((gpsX - transponderPulsePositions[#transponderPulsePositions-1].x)^2+(gpsY - transponderPulsePositions[#transponderPulsePositions-1].y)^2)) > 100 then
                transponderPulsePositions[#transponderPulsePositions+1] = {x=gpsX,y=gpsY,range=rangeToTransponder} --adding information on the current transponder pulse
                currentPosition = transponderPulsePositions[#transponderPulsePositions] --taking that information back
                latestPosition = transponderPulsePositions[#transponderPulsePositions-1] --last recorded information
                lastPosition = transponderPulsePositions[#transponderPulsePositions-2]

                intersectionCurrentLatest = circleIntersection(currentPosition.x,currentPosition.y,currentPosition.range,latestPosition.x,latestPosition.y,latestPosition.range)
                intersectionLatestLast = circleIntersection(latestPosition.x,latestPosition.y,latestPosition.range,lastPosition.x,lastPosition.y,lastPosition.range)
                bestCircleIntersection = nil

                --all the distances of the intersection points of the four two circle intersection results
                dist1 = math.abs(distanceBetweenPoints(intersectionCurrentLatest.x1,intersectionCurrentLatest.y1,intersectionLatestLast.x1,intersectionLatestLast.y1))
                dist2 = math.abs(distanceBetweenPoints(intersectionCurrentLatest.x1,intersectionCurrentLatest.y1,intersectionLatestLast.x2,intersectionLatestLast.y2))
                dist3 = math.abs(distanceBetweenPoints(intersectionCurrentLatest.x2,intersectionCurrentLatest.y2,intersectionLatestLast.x1,intersectionLatestLast.y1))
                dist4 = math.abs(distanceBetweenPoints(intersectionCurrentLatest.x2,intersectionCurrentLatest.y2,intersectionLatestLast.x2,intersectionLatestLast.y2))

                smallest = math.min(dist1,dist2,dist3,dist4)
                rx = 0
                ry = 0
                if smallest == dist1 or smallest == dist2 then
                    rx = intersectionCurrentLatest.x1
                    ry = intersectionCurrentLatest.y1
                else
                    rx = intersectionCurrentLatest.x2
                    ry = intersectionCurrentLatest.y2
                end
                approximations[#approximations+1] = {x = rx, y = ry, distance = distanceBetweenPoints(rx,ry,gpsX,gpsY)}
            end
        else --no last position thats why just adding it
            transponderPulsePositions[#transponderPulsePositions+1] = {x=gpsX,y=gpsY,range=rangeToTransponder}
        end
    end
    timeSinceLastPulse = timeSinceLastPulse + 1

    --#region minimum and maximum Error no more
    -- if approximations[#approximations] then
    --     minError = 0
    --     maxError = 10000
    --     for i = 2, #approximations, 1 do
    --         diviation = math.abs(math.sqrt((approximations[i].x-approximations[i-1].x)^2 + (approximations[i].y-approximations[i-1].y)^2)) --pythagoras for the distance between the two last approximations
    --         maxError = maxError < diviation and diviation or maxError --the maximum diviation from one to the next approximation
    --         minError = minError > diviation and diviation or minError --the minimum error from one to the next approximation
    --     end
    --     approximations[#approximations].minError = minError
    --     approximations[#approximations].maxError = maxError
    -- end
    --#endregion

    --#region averaging the approximations
    averagedApproximation = {x=0,y=0}
    for index, approximation in ipairs(approximations) do
        averagedApproximation.x = averagedApproximation.x + approximation.x
        averagedApproximation.y = averagedApproximation.y + approximation.y
    end
    averagedApproximation.x = averagedApproximation.x / #approximations
    averagedApproximation.y = averagedApproximation.y / #approximations
    --#endregion

    for index, button in ipairs(buttons) do
        if isPointInRectangle(button.x, button.y, button.w and button.w or 6, button.h and button.h or 7, touchX, touchY) and isPressed then
            if pause_ticks_button > 30 then
                button.funct()
                pause_ticks_button = 0
            end
            button.pressed = true
        else
            button.pressed = false
        end
    end
    pause_ticks_button = pause_ticks_button + 1
    if ticks <= 10 or centerOnPlayer then
        mapCenterX = gpsX
        mapCenterY = gpsY
    end
    currentOnScreenX,currentOnScreenY = map.mapToScreen(mapCenterX,mapCenterY,zooms[zoom],Swidth,Sheight,gpsX,gpsY)
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    --#region draw Map
    setMapColors()
    screen.drawMap(mapCenterX, mapCenterY, zooms[zoom])
    --#endregion

    --#region draw line indicator to approximate transponder location
    currentApproxPosition = approximations[#approximations]
    if currentApproxPosition and showTransponderLocation then
        approxOnMapX,approxOnMapY = map.mapToScreen(mapCenterX,mapCenterY,zooms[zoom],Swidth,Sheight,currentApproxPosition.x,currentApproxPosition.y)
        screen.setColor(240,115,10,125)
        screen.drawLine(currentOnScreenX,currentOnScreenY,approxOnMapX,approxOnMapY)
        screen.setColor(240,115,10)
        screen.drawText(2,Sheight-8,math.floor(transponderPulsePositions[#transponderPulsePositions].range) .. "M")
    end
    --#endregion

    --#region aditional UI for button status information
    if pause_ticks_button < 120 then
        screen.drawText(10,8,zooms[zoom] .. "KM")
    end
    --#endregion

    --#region desaster be gone UI
    if desasterActive then
        --screen outline
        screen.setColor(240,56,10)
        screen.drawRect(0,0,Swidth-1,Sheight-1)
        --covering up the small top area
        screen.setColor(0,0,0)
        screen.drawRectF(Swidth-8,-1,20,8)
        screen.setColor(240,56,10)
        screen.drawRect(Swidth-8,-1,20,8)
        screen.drawText(Swidth-7,1,(ticks/changeTime % 2 >= 0.5) and " !" or "! ")
        desasterOnScreenX, desasterOnScreenY = map.mapToScreen(mapCenterX,mapCenterY,zooms[zoom],Swidth,Sheight,desastersBGX,desastersBGY)
        screen.drawRectF(desasterOnScreenX,desasterOnScreenY,1,1)
        screen.drawCircle(desasterOnScreenX,desasterOnScreenY,20)
    end
    --#endregion

    --#region position direction indicator
    -- indicator on screen position mapping
    indicatorOnScreen = isPointInRectangle(10,10,Swidth-10,Sheight-10,currentOnScreenX,currentOnScreenY)
    currentOnScreenX = math.clamp(currentOnScreenX,10,Swidth-10)
    currentOnScreenY = math.clamp(currentOnScreenY,10,Sheight-10)

    compasAsRadians = math.rad(rotation) -- rotation as radians for easier math
    indicatorAngle = indicatorOnScreen and 0.65 or 0.3 -- in turns
    indicatorLineLengths = indicatorOnScreen and 7 or 10 -- pixel length of indicator
    -- Top Middle Point
    ownIndicatorTopX = 3 * math.sin(compasAsRadians) + currentOnScreenX
    ownIndicatorTopY = 3 * math.cos(compasAsRadians) + currentOnScreenY
    -- Bottom left Point
    ownIndicatorBottomLeftX = indicatorLineLengths * math.sin(compasAsRadians + indicatorAngle) + currentOnScreenX
    ownIndicatorBottomLeftY = indicatorLineLengths * math.cos(compasAsRadians + indicatorAngle) + currentOnScreenY
    -- Bottom Right Point
    ownIndicatorBottomRightX = indicatorLineLengths * math.sin(compasAsRadians - indicatorAngle) + currentOnScreenX
    ownIndicatorBottomRightY = indicatorLineLengths * math.cos(compasAsRadians - indicatorAngle) + currentOnScreenY
    -- Bottom Middle Point
    ownIndicatorBottomMiddleX = indicatorLineLengths * math.sin(compasAsRadians + math.pi) + currentOnScreenX
    ownIndicatorBottomMiddleY = indicatorLineLengths * math.cos(compasAsRadians + math.pi) + currentOnScreenY

    -- Drawing the position orientation indicator
    screen.setColor(240,115,10)
    if indicatorOnScreen then
        screen.drawLine(ownIndicatorTopX,ownIndicatorTopY,ownIndicatorBottomLeftX,ownIndicatorBottomLeftY) -- Top to Left
        screen.drawLine(ownIndicatorTopX,ownIndicatorTopY,ownIndicatorBottomRightX,ownIndicatorBottomRightY) -- Top to Right
        screen.drawLine(ownIndicatorBottomLeftX,ownIndicatorBottomLeftY,ownIndicatorBottomMiddleX,ownIndicatorBottomMiddleY) -- Left to Middle
        screen.drawLine(ownIndicatorBottomRightX,ownIndicatorBottomRightY,ownIndicatorBottomMiddleX,ownIndicatorBottomMiddleY) -- Right to Middle
    else
        screen.drawTriangleF(ownIndicatorTopX,ownIndicatorTopY,ownIndicatorBottomLeftX,ownIndicatorBottomLeftY,ownIndicatorBottomRightX,ownIndicatorBottomRightY)
    end
    --#endregion

    for index, button in ipairs(buttons) do
        drawButton(button.x,button.y,button.w,button.h,button.string,button.pressed)
    end
end
