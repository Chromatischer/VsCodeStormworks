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

intExpoFactor = 0.01
inRadarData = {}
tempRadarData = {}
twsTracks = {}
twsBoxSize = 100
twsMaxUpdateTime = 300
twsMaxCoastTime = twsMaxUpdateTime * 5
twsActivationNumber = 2
deltaRotation = 0
lastRotation = 0
lastDeltaRotation = 0

ticks = 0
function onTick()
    ticks = ticks + 1
    gpsX = input.getNumber(20)
    gpsY = input.getNumber(22)
    gpsZ = input.getNumber(21)
    compas = input.getNumber(23)
    pitch = input.getNumber(24)
    radarRotation = input.getNumber(25)

    for i = 0, 4 do
        inRadDistance = input.getNumber(1 + i * 4) -- 1, 5, 9, 13, 17
        inRadAzimuth = input.getNumber(2 + i * 4) -- 2, 6, 10, 14, 18
        inRadElevation = input.getNumber(3 + i * 4) -- 3, 7, 11, 15, 19
        inRadPosition = convertToCoordinateObj(radarToGlobalCoordinates(inRadDistance, inRadAzimuth, inRadElevation, gpsX, gpsY, gpsZ, compas, pitch))

        -- if there is a contact detected then if the time since detection is 0 then 
        if input.getBool(i) then
            table.insert(inRadarData, inRadPosition)
        end
    end
    deltaRotation = radarRotation - lastRotation
    lastRotation = radarRotation
    --sign(x) will return -1 if x is negative, 0 if x is 0, and 1 if x is positive
    --that means that if the sign of the delta rotation is the same as the sign of the last delta rotation then we can assume that the radar is still rotating
    --if the sign of the delta rotation is different from the sign of the last delta rotation then we can assume that the radar has chaned direction
    --and we can flush to the tempRadarData and start processing the data
    --or if the rotation is 180 or 360 degrees if it is contiously rotating
    if (sign(deltaRotation) - sign(lastDeltaRotation) == 0) or (radarRotation % 180 == 0 and radarRotation ~= 0) then
        tempRadarData = {} --resetting the tempRadarData
        for i = 1, #inRadPosition do
            table.insert(tempRadarData, inRadPosition[i]) --moving all the data from the inRadarData to the tempRadarData
        end
        inRadarData = {} --resetting the inRadarData
    end
    lastDeltaRotation = deltaRotation --setting the last delta rotation to the current delta rotation

    --creating the empty hungarian matrix to fill afterwards with the distances between the tempRadarData and the twsTracks
    hungarianMatrix = {}
    for i = 1, #tempRadarData + 1 do
        hungarianMatrix[i] = vec(#twsTracks + 1, 0)
    end

    --filling the hungarian matrix with the distances between the tempRadarData and the twsTracks
    for tempDex, tempCoordinate in pairs(tempRadarData) do
        for trackDex, twsCoordinate in pairs(twsTracks) do
            hungarianMatrix[trackDex + 1][tempDex + 1] = math.abs(tempCoordinate:get3DDistanceTo(twsCoordinate))
        end
    end
    bestDistances = hungarianAlgorithm(hungarianMatrix)

    --#region update
    --updating the tracks and deleting the corresponding temp data
    for track, temp in pairs(bestDistances) do
        if hungarianMatrix[track][temp] < twsBoxSize then --if the distance to the coordinate is smaller then the box size
            tracks[track]:addCoordinate(tempRadarData[temp]) --adding the temp coordinate to the corresponding track
            tempRadarData[temp] = nil
        end
    end
    --#endregion

    for i = #twsTracks, 1, -1 do
        track = twsTracks[i]
        track:addUpdateTime()
        --#region delete
        if track:getState() == 1 then
            if track:getUpdateTime() > twsMaxCoastTime then
                track:coast()
            end
        else
            if track:getUpdateTime() > twsMaxUpdateTime then
                table.remove(twsTracks, i)
            end
        end
        --#endregion
        track:predict()
    end

    --#region adding new tracks
    for i = #tempRadarData, 1, -1 do
        temp = tempRadarData[i]
        if temp ~= nil then
            table.insert(twsTracks, newTrack(temp, twsBoxSize, twsMaxUpdateTime, twsMaxCoastTime, twsActivationNumber))
        end
        table.remove(tempRadarData, i)
    end
    --#endregion
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    --conversion to screen-space taking rotation into account

    for _, track in ipairs(twsTracks) do
        radPas = math.rad(compas)
        relX = gpsX - track:getX()
        relY = gpsY - track:getY()
        relZ = gpsZ - track:getZ()
        tempX = relX * Swidth --convert to screen space
        tempY = relY * Sheight
        --convert to on screen coordinate taking the orientation of the ship into account
        onScreenX = tempX * math.cos(radPas) - tempY * math.sin(radPas)
        onScreenY = tempY * math.cos(radPas) - tempX * math.sin(radPas)
    end
end

function exponentialMovingAverage(a, b, f)
    return a * f + b * (1 - f)
end