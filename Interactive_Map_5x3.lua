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
    simulator:setScreen(1, "5x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputBool(2, simulator:getIsClicked(2))
        simulator:setInputNumber(1, screenConnection.touchX)
        simulator:setInputNumber(2, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(3, 1000)
        simulator:setInputNumber(4, 1000)
        simulator:setInputNumber(5, simulator:getSlider(1))
        simulator:setInputNumber(6, ticks/360)
        simulator:setInputNumber(7, simulator:getSlider(3))
        simulator:setInputNumber(8, 9)
        simulator:setInputNumber(9, 100)
        simulator:setInputNumber(10, 0)
        simulator:setInputNumber(11, 5000)
        simulator:setInputNumber(12, 0.25)
        simulator:setInputNumber(13, ticks/360)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!
require("Utils.Utils")
--#region setup
zooms = {0.1,0.2,0.5,1,2,5,10,15,20,25,30,40,50}
zoom = 4
ticks = 0
mapCenterX = 0
mapCenterY = 0
autoCenterMap = true
moveMapToTouch = false
pause_ticks_button = 0
moveMapTicks = 0
waypoints = {{x=0,y=0}}
waypoint = 1
autoStepWaypoint = true
showWaypoints = true
notMapMoveTouchX = 0
notMapMoveTouchY = 0
radarTargets = {}
showRadarTargets = true
buttons = {{x=2,y=2,string="+",funct = function ()
    zoom = zoom + 1 < #zooms and zoom + 1 or zoom
end}, {x=2,y=12,string="-",funct = function ()
    zoom = zoom - 1 > 0 and zoom -1 or zoom
end}, {x=2,y=22,string="C",funct = function ()
    autoCenterMap = not autoCenterMap
end}, {x=2,y=32,string="M",funct = function ()
    moveMapToTouch = not moveMapToTouch
    autoCenterMap = moveMapToTouch and autoCenterMap or false --if you dont touch to move the map wont auto center
end}, {x=153,y=88,string="N",funct = function ()
    selectedMapPointX,selectedMapPointY = map.screenToMap(mapCenterX,mapCenterY,zooms[zoom],Swidth,Sheight,notMapMoveTouchX,notMapMoveTouchY)
    waypoints[#waypoints+1] = {x=selectedMapPointX,y=selectedMapPointY} --adding the new waypoint on top of the array
end}, {x=153,y=78,string="D",funct = function ()
    if #waypoints > 1 then
        waypoints[#waypoints] = nil --removes the last element from the array if the length is above one
    end
    waypoint = waypoint > #waypoints and #waypoints or waypoint --if the selected waypoint does not exist any more move it to the last existing one
    buttons[7].string = waypoint --update the waypoint indicator
end}, {x=153,y=68,string=waypoint,funct = function ()
    waypoint = (waypoint < #waypoints) and (autoStepWaypoint and waypoint or waypoint + 1) or 1 -- step the waypoint if its not the last and not in auto step mode
    buttons[7].string = waypoint
end}, {x=153,y=58,string="A",funct = function ()
    autoStepWaypoint = not autoStepWaypoint
end}, {x=153,y=47,string="R",funct = function ()
    showRadarTargets = not showRadarTargets
end}}
--#endregion
function onTick()
    ticks = ticks + 1
    --#region inputs
    touchX = input.getNumber(1)
    touchY = input.getNumber(2)
    gpsX = input.getNumber(3)
    gpsY = input.getNumber(4)
    gpsZ = input.getNumber(8)
    rotation = (input.getNumber(5) * 360) %360
    radarAzimuth = input.getNumber(6)
    radarElevation = input.getNumber(7)
    radarDistance = input.getNumber(9)
    tiltPitch = input.getNumber(10)
    maxRadarRange = input.getNumber(11) --in meters please
    maxRadarAzimuth = input.getNumber(12) --0-1 turns
    radarRotationDegrees = (input.getNumber(13) * -360) % 360 --also turns I think
    isPressed = input.getBool(1)
    contactDetected = input.getBool(2)
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
    if ticks <= 10 or autoCenterMap then
        mapCenterX = gpsX
        mapCenterY = gpsY
        moveMapToTouch = false
    end
    if not autoCenterMap and moveMapToTouch and isPressed and moveMapTicks > 30 and pause_ticks_button > 60 then
        mapCenterX, mapCenterY = map.screenToMap(mapCenterX,mapCenterY,zooms[zoom],Swidth,Sheight,touchX,touchY)
        moveMapTicks = 0
    else
        notMapMoveTouchX = touchX
        notMapMoveTouchY = touchY
    end
    moveMapTicks = moveMapTicks + 1
    if autoStepWaypoint and math.abs(math.sqrt((gpsX - waypoints[waypoint].x)^2 + (gpsY - waypoints[waypoint].y)^2)) < 100 then
        waypoint = waypoint < #waypoints and waypoint + 1 or waypoint --if distance from current position to waypoint is less then 100 meters select next as target waypoint
    end
    waypoints[1].x, waypoints[1].y = gpsX, gpsY
    currentScreenX, currentScreenY = map.mapToScreen(mapCenterX, mapCenterY, zooms[zoom], Swidth, Sheight, gpsX, gpsY)
    --#region radar contact entering and removing
    radarAzimuthAsDegrees = (radarAzimuth * 360) % 360
    if contactDetected then
        --new cotact entering into the array
        radarTargets[radarAzimuthAsDegrees] = radarToGlobalCoordinates(radarDistance,radarAzimuth,radarElevation,gpsX,gpsY,gpsZ,rotation/360,tiltPitch)
    elseif radarTargets[radarAzimuthAsDegrees] then
        --reduce age if no longer detected deleting on 0
        if radarTargets[radarAzimuthAsDegrees].age <= 0 then
            radarTargets[radarAzimuthAsDegrees] = nil
        else
            radarTargets[radarAzimuthAsDegrees].age = radarTargets[radarAzimuthAsDegrees].age -10
        end
    end
    --#endregion
    output.setNumber(1,waypoints[waypoint].x)
    output.setNumber(2,waypoints[waypoint].y)
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()
    setMapColors()
    screen.drawMap(mapCenterX, mapCenterY, zooms[zoom])
    screen.setColor(240,115,10)
    if pause_ticks_button < 120 then
        screen.drawText(10,7,zooms[zoom] .. "KM")
        screen.drawText(10,23,autoCenterMap and "AC" or "NAC")
        screen.drawText(10,33,moveMapToTouch and "MM" or "NM")
        screen.drawText(136,59,autoStepWaypoint and "ATO" or "MAN")
        screen.drawText(136,79,"DEL")
        screen.drawText(136,89,"NEW")
        screen.drawText(136,48,showRadarTargets and "SHW" or "HDE")
    end
    if moveMapTicks < 120 then
        screen.setColor(0,0,0)
        screen.drawRectF(-1,Sheight-20,38,20)
        screen.setColor(100,100,100)
        screen.drawRect(-1,Sheight-20,38,20)
        screen.setColor(240,115,10)
        screen.drawText(2,Sheight-18,firstLine.format("X:%05d", math.floor(mapCenterX)))
        screen.drawText(2,Sheight-10,firstLine.format("Y:%05d", math.floor(mapCenterY)))
    end
    if not moveMapToTouch then
        screen.drawRect(touchX-1,touchY-1,3,3)
    end
    screen.setColor(240,115,10)
    if showWaypoints then
        for index, waypoint in ipairs(waypoints) do
            waypointScreenX, waypointScreenY = map.mapToScreen(mapCenterX,mapCenterY,zooms[zoom],Swidth,Sheight,waypoint.x,waypoint.y) -- Waypoints Screen Coordinate
            if index ~= 1 then --because 1 is always your own position
                ---@diagnostic disable-next-line: param-type-mismatch
                screen.drawText(waypointScreenX+2,waypointScreenY+2,index)
                screen.drawRect(waypointScreenX,waypointScreenY,1,1)
            end
            screen.setColor(240,115,10,125)
            if index < #waypoints then --last waypoint check
                nextWaypointScreenX, nextWaypointScreenY = map.mapToScreen(mapCenterX,mapCenterY,zooms[zoom],Swidth,Sheight,waypoints[index+1].x,waypoints[index+1].y)
                screen.drawLine(waypointScreenX,waypointScreenY,nextWaypointScreenX,nextWaypointScreenY)
            end
        end
    end
    --#region onscreen position and rotation indicator

    -- indicator on screen position mapping
    indicatorOnScreen = isPointInRectangle(10,10,Swidth-10,Sheight-10,currentScreenX,currentScreenY)
    currentScreenX = math.clamp(currentScreenX,10,Swidth-10)
    currentScreenY = math.clamp(currentScreenY,10,Sheight-10)

    compasAsRadians = math.rad(rotation) -- rotation as radians for easier math
    indicatorAngle = indicatorOnScreen and 0.65 or 0.3 -- in turns
    indicatorLineLengths = indicatorOnScreen and 7 or 10 -- pixel length of indicator
    -- Top Middle Point
    ownIndicatorTopX = 3 * math.sin(compasAsRadians) + currentScreenX
    ownIndicatorTopY = 3 * math.cos(compasAsRadians) + currentScreenY
    -- Bottom left Point
    ownIndicatorBottomLeftX = indicatorLineLengths * math.sin(compasAsRadians + indicatorAngle) + currentScreenX
    ownIndicatorBottomLeftY = indicatorLineLengths * math.cos(compasAsRadians + indicatorAngle) + currentScreenY
    -- Bottom Right Point
    ownIndicatorBottomRightX = indicatorLineLengths * math.sin(compasAsRadians - indicatorAngle) + currentScreenX
    ownIndicatorBottomRightY = indicatorLineLengths * math.cos(compasAsRadians - indicatorAngle) + currentScreenY
    -- Bottom Middle Point
    ownIndicatorBottomMiddleX = indicatorLineLengths * math.sin(compasAsRadians + math.pi) + currentScreenX
    ownIndicatorBottomMiddleY = indicatorLineLengths * math.cos(compasAsRadians + math.pi) + currentScreenY

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
    if showRadarTargets then
        for targetAzimuth, target in pairs(radarTargets) do
            screen.setColor(240,115,10,(target.age/100)*255)
            targetScreenX, targetScreenY = map.mapToScreen(mapCenterX,mapCenterY,zooms[zoom],Swidth,Sheight,target.x,target.y)
            screen.drawTriangleF(targetScreenX-2,targetScreenY-2,targetScreenX+2,targetScreenY-2,targetScreenX,targetScreenY + (target.z > 50 and 4 or 2))
        end
        radarAzimuthAsRadians = math.rad(radarRotationDegrees + rotation + 180)
        radarDistanceOnScreen = (maxRadarRange / zooms[zoom] / 1000) * Sheight --idk how that works but it does sont question it!
        radarLeftLineX = radarDistanceOnScreen * math.sin(radarAzimuthAsRadians + maxRadarAzimuth) + currentScreenX
        radarLeftLineY = radarDistanceOnScreen * math.cos(radarAzimuthAsRadians + maxRadarAzimuth) + currentScreenY
        radarRightLineX = radarDistanceOnScreen * math.sin(radarAzimuthAsRadians - maxRadarAzimuth) + currentScreenX
        radarRightLineY = radarDistanceOnScreen * math.cos(radarAzimuthAsRadians - maxRadarAzimuth) + currentScreenY
        screen.setColor(240,115,10)
        screen.drawLine(currentScreenX,currentScreenY,radarLeftLineX,radarLeftLineY)
        screen.drawLine(currentScreenX,currentScreenY,radarRightLineX,radarRightLineY)
        drawCircle(currentScreenX,currentScreenY,radarDistanceOnScreen,16,radarAzimuthAsRadians - maxRadarAzimuth-math.pi/2,2*maxRadarAzimuth)
    end

    for index, button in ipairs(buttons) do
        drawButton(button.x,button.y,button.w,button.h,button.string,button.pressed)
    end
end
