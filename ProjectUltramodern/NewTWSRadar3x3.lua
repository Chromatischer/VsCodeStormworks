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
    simulator:setScreen(1, "3x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(2, screenConnection.touchX)
        simulator:setInputNumber(3, screenConnection.touchY)
    end;
end
---@endsection


require("Utils.Utils")
require("Utils.Coordinate.Coordinate")
require("Utils.Coordinate.Coordinate_Utils")
require("Utils.TrackWhileScanUtils")


internalRadarData = {}
internalEMAFactor = 0.01

tempRadarData = {}
twsContacts = {}
twsBoxSize = 100
twsMaxUpdateTime = 300
twsMaxCoastTime = twsMaxUpdateTime * 5

ticks = 0
function onTick()
    ticks = ticks + 1
    --inputs
    gpsX = input.getNumber(17)
    gpsY = input.getNumber(19)
    gpsZ = input.getNumber(18)
    compas = input.getNumber(20)
    currentRadarRotation = input.getNumber(21)

    --NOTE: that everything that is iterated over needs to be iterated over back to front!
    --TODO: testing of all the systems as well as the intermediate averaging and the tws itself
    --NOTE: the tws should be working in theory so that should be alright!

    for i = 0, 3 do -- calculating tempRadarData to use for the tws system
        radarDistance = input.getNumber(i * 4)
        radarAzimuth = input.getNumber(1 + i * 4) * 360
        radarElevation = input.getNumber(2 + i * 4) * 360
        radarTimeSinceDetected = input.getNumber(3 + i * 4)
        isRadarContact = input.getBool(i * 4)

        if isRadarContact and radarDistance > 90 then
            radarRelativeCoordinate = newCoordinate(radarDistance * math.sin(math.rad(radarAzimuth)), radarDistance * math.cos(math.rad(radarAzimuth)), radarDistance * math.tan(math.rad(radarElevation)))
            -- in theory: take the radar data and average it out as long as the TSD is not 0 if it is 0 then flush it into the tempRadarData
            -- this is done using an EMA and applying it to the XY and Z component of the coordinate
            if radarTimeSinceDetected ~= 0 then
                lastCoordinate = internalRadarData[i]
                -- use EMA to average over the tempRadarData when time since detected is 0
                --todo test if lineBreak works xD
                internalRadarData[i] = lastCoordinate and newCoordinate(exponentialMovingAverage(radarRelativeCoordinate:getX(), lastCoordinate:getX(), internalEMAFactor),
                exponentialMovingAverage(radarRelativeCoordinate:getY(), lastCoordinate:getY(), internalEMAFactor),
                exponentialMovingAverage(radarRelativeCoordinate:getZ(), lastCoordinate:getZ(), internalEMAFactor))
                or radarRelativeCoordinate
            else
                tempRadarData[i] = internalRadarData[i] --flushing to the array to use in my pre-made script
            end
        end
    end

    for index = #twsContacts, 1, -1 do
        twsContact = twsContacts[index]
        if twsContact then
            twsContact:addUpdateTime()
            for tempRadarIndex = #tempRadarData, 1, -1 do --Match every track to every temp contact check for box and then add to track and remove from temp storage
                tempRadarContact = tempRadarData[tempRadarIndex]
                twsLatestPosition = twsContact:getLatestHistoryPosition()
                if tempRadarContact:get3DDistanceTo(twsLatestPosition) < twsContact:getBoxSize() then
                    twsContact:addCoordinate(tempRadarContact)
                    table.remove(tempRadarData, tempRadarIndex)
                end
            end

            --if it is coasted use coast time if it is active or inactive then use update time
            if twsContact:getState() == 0 then
                if twsContact:getUpdateTime() > twsMaxUpdateTime then
                    twsContact:coast() --first coast
                end
            --Ok so in theory: only state 1 and 2 can get here! 1 is coasted so its checked against maxCoastTime 2 is inactive so its checked against maxUpdateTime!
            elseif (twsContact:getState() == 1 and twsContact:getUpdateTime() > twsMaxCoastTime) or (twsContact:getState() == 2  and twsContact:getUpdateTime() > twsMaxUpdateTime) then --should work :D
                    table.remove(twsContacts, index) --then delete
            end

            twsContact:predict()
        end
    end

    --add the new data if it is still left in the temp storage and deleting afterwards
    for tempRadarIndex = #tempRadarData, 1, -1 do
        tempContact = tempRadarData[tempRadarIndex]
        table.insert(twsContacts, newTrack(tempContact, twsBoxSize, twsMaxUpdateTime, twsMaxCoastTime, 3))
        table.remove(tempRadarData, tempRadarIndex)
    end
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    screen.setColor(100, 92, 88) -- background gray (light)
    screen.drawRectF(0, 0, Swidth, Sheight)
    screen.setColor(50, 46, 44) -- text more gray! (dark)
    --tetradic colors
    screen.setColor(248, 104, 031) -- orange
    screen.setColor(066, 248, 031) -- green
    screen.setColor(031, 175, 248) -- blue
    screen.setColor(213, 031, 248) -- purple

    --maybe use
    --(248, 212, 31) --yellow
    --(175, 248, 31) --green (light)
    --(31, 248, 213) --blue (light)

    --TODO: convert world space into screen space
     -- take the rotation into account!

    --TODO: draw contacts to screen

    --TODO: draw trails to screen (only like 3-4 or something)

    --TODO: draw current radar rotation to screen

    --TODO: draw simple UI (scale and not much more!)

end

function exponentialMovingAverage(a, b, f)
    return a * f + b * (1 - f)
end