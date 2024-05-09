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
require("Utils.Coordinate.Coordinate_Utils")

tempRadarData = {}
tracks = {}
trackOnScreenPositions = {}
selectedTrack = nil
lastRadarRotation = 0

twsBoxSize = 100
twsMaxUpdateTime = 60 * 60 -- seconds -> ticks
twsMaxCoastTime = twsMaxUpdateTime * 5
twsActivationNumber = 3
mapZooms = {0.1, 0.2, 0.5, 1, 2, 5, 7, 9, 11, 13, 15, 17, 20, 25, 30, 35, 40, 45, 50}
mapZoom = 3
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
    monitorIsTouch = input.getBool(1)
    for i = 0, 3 do
        if input.getBool(2 + i) then
            radarDistance = input.getNumber(8 + i * 3) --this was THE most stupid bug EVER!
            radarAzimuth = input.getNumber(9 + i * 3)
            radarElevation = input.getNumber(10 + i * 3)
            if isInf(radarDistance) or isNan(radarDistance) or isInf(radarAzimuth) or isNan(radarAzimuth) or isInf(radarElevation) or isNan(radarElevation) then
                print("Im fucked!")
            end
            if isInf(gpsX) or isNan(gpsX) or isInf(gpsY) or isNan(gpsY) or isInf(gpsZ) or isNan(gpsZ) then
                print("eqtjez")
            end
            if radarDistance > 20 then
                globalCoordinate = convertToCoordinateObj(radarToGlobalCoordinates(radarDistance, radarAzimuth, radarElevation, gpsX, gpsY, gpsZ, compas, pitch))
                if not globalCoordinate:getX() or not globalCoordinate:getY() or not globalCoordinate:getZ() or isInf(globalCoordinate:getX()) or isNan(globalCoordinate:getX()) or isInf(globalCoordinate:getY()) or isNan(globalCoordinate:getY()) or isInf(globalCoordinate:getZ()) or isNan(globalCoordinate:getZ()) then
                    print("im scared!")
                end
                tempRadarData[#tempRadarData+1] = globalCoordinate --safe in a tempData Array
            end
        end
    end

    for index = #tracks, 1, -1 do
        track = tracks[index]
        track:addUpdateTime() -- adding time

        --#region adding to track
        for tardex = #tempRadarData, 1, -1 do
            target = tempRadarData[tardex]
            boxLocation, boxSize = track:getBoxInfo()
            checkForWrong(boxLocation)
            if boxLocation:get3DDistanceTo(target) < boxSize then -- target is inside the tracking box
                track:addCoordinate(target) -- adding target to track
                table.remove(tempRadarData, tardex) -- removing target from temp storage
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
        trackOnScreenPosition = newCoordinate(map.mapToScreen(gpsX, gpsY, mapZooms[mapZoom], Swidth, Sheight, track:getLatestHistoryPosition():getX(), track:getLatestHistoryPosition():getY()))
        trackOnScreenPositions[index] = trackOnScreenPosition
        screen.setColor(0, 0, 255, 50)
        screen.drawText(trackOnScreenPosition:getX(), trackOnScreenPosition:getY(), track:getUpdateTime())
        if selectedTrack == nil then
            if track:getState() == 0 then
                screen.setColor(255, 0, 0)
                p1 = newCoordinate(trackOnScreenPosition:getX() + 3 * math.sin(track:getAngle() + 90), trackOnScreenPosition:getY() + 3 * math.cos(track:getAngle() + 90))
                p2 = newCoordinate(trackOnScreenPosition:getX() + 3 * math.sin(track:getAngle() - 90), trackOnScreenPosition:getY() + 3 * math.cos(track:getAngle() - 90))
                screen.drawLine(p1:getX(), p1:getY(), p2:getX(), p2:getY())
                if track:getHistoryLength() < 10 then
                    --#region for recently activated active targets
                else
                end
            end
        else
        end
    end
    screen.setColor(255, 255, 255)
    screen.drawText(0, 0, "#" .. #tracks)
    screen.drawText(0, 6, string.format("%02d", math.abs(math.floor(radarRotation * 360))))
    if tempRadarData[0] then
        screen.drawText(0, 12, tempRadarData[0]:getX() .. " " .. tempRadarData[0]:getY() .. " " .. tempRadarData[0]:getZ())
    end
end

function checkForWrong(check)
    if not check or isInf(check:getX()) or isNan(check:getX()) or isInf(check:getY()) or isNan(check:getY()) or isInf(check:getZ()) or isNan(check:getZ()) then
        print("fiynd")
    end
end