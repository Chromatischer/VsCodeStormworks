-- Author: Chromatischer
-- GitHub: https://github.com/Chromatischer
-- Workshop: https://shorturl.at/acefr

--Discord: @chromatischer--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

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
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection

require("Utils.Utils")
require("Utils.TrackWhileScanUtils")
require("Utils.Coordinate.radarToGlobalCoordinates")
require("Utils.Coordinate.Coordinate")

tempRadarData = {}
tracks = {}
trackOnScreenPositions = {}
selectedTrack = nil
lastRadarRotation = 0

twsBoxSize = 100
twsMaxUpdateTime = 1200
twsMaxCoastTime = twsMaxUpdateTime * 5
twsActivationNumber = 3
mapZooms = {0.1, 0.2, 0.5, 1, 2, 5, 7, 9, 11, 13, 15, 17, 20, 25, 30, 35, 40, 45, 50}
mapZoom = 6
ticks = 0
function onTick()
    ticks = ticks + 1
    gpsX = input.getNumber(1)
    gpsZ = input.getNumber(2)
    gpsY = input.getNumber(3)
    pitch = input.getNumber(4)
    compas = input.getNumber(5)
    monitorTouchX = input.getNumber(6)
    monitorTouchY = input.getNumber(7)
    radarRotation = input.getNumber(20)
    for i = 0, 3 do
        if input.getBool(2 + i) then --if there is a contact detected calculate the global coordinates of it
            radarDistance = 8 + i * 3
            radarAzimuth = 9 + i * 3
            radarElevation = 10 + i * 3
            tempRadarData[i] = convertToCoordinateObj(radarToGlobalCoordinates(radarDistance, radarAzimuth, radarElevation, gpsX, gpsY, gpsZ, compas, pitch)) --safe in a tempData Array
        end
    end

    for index, track in ipairs(tracks) do --every tick executed for every track
        track:addUpdateTime() -- adding time

        --#region adding to track
        for tardex, target in ipairs(tempRadarData) do --cross matching with every target
            boxLocation, boxSize = track:getBoxInfo()
            if boxLocation:get3DDistanceTo(target) < boxSize then -- target is inside the tracking box
                track:addCoordinate(target) -- adding target to track
                table.remove(tempRadarData, tardex) -- removing target from temp storage
                break --exiting the loop because we dont want double targets in one iteration
            end
        end
        --#endregion

        --#region coasting and deleting
        if track:getUpdateTime() > track:getMaxUpdateTime() then -- coasting and deleting
            if track:getState() == 0 then
                track:coast()
            else
                if track:getState() == 2 or (track:getState() == 1 and track:getUpdateTime() > track:getMaxCoastTime()) then
                    table.remove(tracks, index) -- deleting from array if coasted or if inactive and no more data is available
                end
            end
        end
        --#endregion

        track:predict()
    end

    --#region spawning new tracks
    for index, target in ipairs(tempRadarData) do
        tracks[#tracks+1] = newTrack(target, twsBoxSize, twsMaxUpdateTime, twsMaxCoastTime, twsActivationNumber)
    end
    --#endregion

    monitorTouchCoord = newCoordinate(monitorTouchX, monitorTouchY)
    for index, position in ipairs(trackOnScreenPositions) do
        if monitorIsTouched and position:get2DDistanceTo(monitorTouchCoord) < 3 then
            selectedTrack = index
        end
    end
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    screen.drawMap(gpsX, gpsY, mapZooms[mapZoom])
    for index, track in ipairs(tracks) do
        trackOnScreenPositions[index] = newCoordinate(map.mapToScreen(gpsX, gpsY, mapZooms[mapZoom], Swidth, Sheight, track:getLastPosition():getX(), track:getLastPosition():getY()))
        if selectedTrack == nil then
            if track:getState() == 0 then
                screen.setColor(255, 0, 0)
                screen.drawRectF()
            end
        else
        end
    end
end
