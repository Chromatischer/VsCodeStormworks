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
    simulator:setScreen(2, "2x2")
    simulator:setScreen(3, "3x3")

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(4, screenConnection.touchX)
        simulator:setInputNumber(5, screenConnection.touchY)
    end;
end
---@endsection

--#region Input Layout
-- Number Inputs:
-- 1: X
-- 2: Y
-- 3: Z
-- 4: Touch X
-- 5: Touch Y
-- 6: Distance

-- Bool Inputs:
-- 1: Active
-- 2: Pulse
-- 3: Touch
--#endregion

pulsePoints = {} -- table structure: {x, y, z, distance}
wasActive = false
intersections = {} -- table structure: {x, y}
bestIntersection = {x = 0, y = 0} -- coordinate (x, y)
lastRecordPosition = {x = 0, y = 0}
bestIntersectionArray = {}
bestDistance = 0
numCalculations = 0
intersectionNum = 25
pulseX = 0
pulseY = 0

-- Idea1: Pick at random two pulsePoints and calculate the intersection of their circles, save the intersection points in intersections table and go from there
--Pro: Less resource intensive then Idea3, Con: Uses older data with less accuracy, More difficult to implement
-- Idea2: Use only the latest two pulsePoints and calculate the intersection of their circles
--Pro: Less resource intensive then Idea3, Simple to implement, Uses the latest data with the highest accuracy
-- Idea3: Use all pulsePoints and calculate the intersection of all circles every tick
--Pro: Uses all data with the highest accuracy, Con: Most resource intensive

require("Utils.CircleIntersectionUtils")

ticks = 0
function onTick()
    ticks = ticks + 1

    gpsX = input.getNumber(1)
    gpsY = input.getNumber(2)
    gpsZ = input.getNumber(3)

    touchX = input.getNumber(4)
    touchY = input.getNumber(5)

    tDistanceAnalog = input.getNumber(6)

    isActive = input.getBool(1)
    pulse = input.getBool(2)
    isDepressed = input.getBool(3)

    pInt = property.getNumber("Number of Calculations for Intersection")
    pInt = math.sqrt(pInt) - pInt
    intersectionNum = pInt ~= 0 and pInt or 25

    if isActive and not wasActive then
        pulsePoints = {}
    end
    wasActive = isActive

    if pulse then
        pulseX = gpsX
        pulseY = gpsY
    end

    if isActive and pulse and (tDistanceAnalog > 200) then --only record a new pulsePoint if the active input is true and the pulse input is true and the distance is greater than 300 because 250 is the minimum resolution of the trnasponder
        if math.abs(math.sqrt((lastRecordPosition.x - gpsX) ^ 2 + (lastRecordPosition.y - gpsY) ^ 2)) > 10 then --only record a new pulsePoint if the distance between the last recorded position and the new position is greater than 10 meters to avoid recording the same position multiple times
            table.insert(pulsePoints, {x = pulseX, y = pulseY, r = tDistanceAnalog})
            lastRecordPosition = {x = gpsX, y = gpsY}
            if #pulsePoints > 1 then --only calculate the intersection points if there are at least two pulsePoints
                intersectionPoints = circleIntersection(pulsePoints[#pulsePoints], pulsePoints[#pulsePoints - 1])
                if intersectionPoints then
                    table.insert(intersections, {x = intersectionPoints[1], y = intersectionPoints[2]})
                    table.insert(intersections, {x = intersectionPoints[3], y = intersectionPoints[4]})
                end
                --only calculate the best intersection point for the latest 50 pulsePoints because of the resource intensity
                if #intersections > 0 then
                    table.insert(bestIntersectionArray, intersections[#intersections])
                    if # bestIntersectionArray > intersectionNum then
                        table.remove(bestIntersectionArray, 1)
                    end
                    bestIntersection, bestDistance, numCalculations = findBestIntersectionPoint(bestIntersectionArray)
                end
            end
        end
    end
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    screen.setColor(255, 255, 255)
    --screen.drawText(3, 1, "#P" .. #pulsePoints)
    --screen.drawText(3, 8, "BIP" .. math.floor(bestIntersection.x) .. "|" .. math.floor(bestIntersection.y))
    --screen.drawText(3, 15, "#I" .. #intersections)
    screen.drawText(3, 1, "D" .. math.floor(bestDistance))
    --screen.drawText(3, 29, "C" .. numCalculations)
    screen.drawMap(bestIntersection.x, bestIntersection.y, 2.5)
    for _, int in ipairs(intersections) do
        px, py = map.mapToScreen(bestIntersection.x, bestIntersection.y, 2.5, Swidth, Sheight, int.x, int.y)
        screen.setColor(255, 0, 0)
        screen.drawCircle(px, py, 2)
    end
    screen.setColor(0, 255, 0)
    for _, int in ipairs(bestIntersectionArray) do
        px, py = map.mapToScreen(bestIntersection.x, bestIntersection.y, 2.5, Swidth, Sheight, int.x, int.y)
        screen.drawCircle(px, py, 2)
    end
    screen.setColor(0, 0, 255)
    if #pulsePoints > 10 then
        for i = #pulsePoints - 10, #pulsePoints do
            int = pulsePoints[i]
            px, py = map.mapToScreen(bestIntersection.x, bestIntersection.y, 2.5, Swidth, Sheight, int.x, int.y)
            screen.drawCircle(px, py, (int.r / 1000) / 2.5 * Swidth)
        end
    end
end