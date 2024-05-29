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
        simulator:setInputNumber(1, 0)
        simulator:setInputNumber(2, 0)
        simulator:setInputNumber(3, 0)
        simulator:setInputNumber(4, 0)
        simulator:setInputNumber(5, 0)
        simulator:setInputNumber(8, 25)
        simulator:setInputNumber(9, 0)
        simulator:setInputNumber(10, 0)
        simulator:setInputBool(2, true)
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

twsBoxSize = 100 -- basically a resolution of the box size (how many meters in each direction a new contact will still be added to the track)
twsMaxUpdateTime = 10 * 60 -- seconds -> ticks
twsMaxCoastTime = twsMaxUpdateTime * 5
twsActivationNumber = 1
mapZooms = { 0.1, 0.2, 0.5, 1, 2, 5, 7, 9, 11, 13, 15, 17, 20, 25, 30, 35, 40, 45, 50 }
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
            if radarDistance > 20 then
                tempRadarData[#tempRadarData + 1] = convertToCoordinateObj(radarToGlobalCoordinates(radarDistance, radarAzimuth, radarElevation, gpsX, gpsY, gpsZ, compas, pitch)) --safe in a tempData Array
            end
        end
    end

    for index = #tracks, 1, -1 do
        track = tracks[index] -- I want to fucking kill myself... THIS WAS THE PROBLEM!!!
        if track then
            track:addUpdateTime() -- adding time

            --#region adding contacts to track from temp data array
            for tardex = #tempRadarData, 1, -1 do
                target = tempRadarData[tardex]
                boxLocation = track:getLatestHistoryPosition()
                boxSize = track:getBoxSize()
                if math.abs(boxLocation:get3DDistanceTo(target)) < boxSize then -- target is inside the tracking box
                    track:addCoordinate(target)                       -- adding target to track
                    table.remove(tempRadarData, tardex)               -- removing target from temp storage
                end
            end
            --#endregion

            --#region coasting and deleting
            if track:getState() == 0 and track:getUpdateTime() > track:getMaxUpdateTime() then
                track:coast()
            else
                if (track:getState() == 2 and track:getUpdateTime() > track:getMaxUpdateTime()) or (track:getState() == 1 and track:getUpdateTime() > track:getMaxCoastTime()) then
                    table.remove(tracks, index) -- deleting from array if coasted or if inactive and no more data is available
                    if selectedTrack == index then -- if the selected track is deleted, deselect it
                        selectedTrack = nil
                    end
                end
            end
            --#endregion

            track:predict()
        end
    end

    --#region spawning new tracks
    for tardex = #tempRadarData, 1, -1 do
        target = tempRadarData[tardex]
        if target then
            table.insert(tracks, newTrack(target, twsBoxSize, twsMaxUpdateTime, twsMaxCoastTime, twsActivationNumber))
            table.remove(tempRadarData, tardex)
        end
    end
    --#endregion

    monitorTouchCoord = newCoordinate(monitorTouchX, monitorTouchY)
    for index, position in ipairs(trackOnScreenPositions) do
        if monitorIsTouched and position:get2DDistanceTo(monitorTouchCoord) < 3 then
            selectedTrack = index
        end
    end
    if not tracks[selectedTrack] then
        selectedTrack = nil
    end
end

function onDraw()
    Swidth = screen.getWidth()
    Sheight = screen.getHeight()

    screen.drawMap(gpsX, gpsY, mapZooms[mapZoom])
    screen.setMapColorGrass()
    screen.setMapColorLand()
    screen.setMapColorOcean(0, 0, 0)
    screen.setMapColorSand()
    screen.setMapColorShallows(0, 0, 0)
    screen.setMapColorSnow()
    for index, track in ipairs(tracks) do
        if selectedTrack == nil then
            trackOnScreenPosition = newCoordinate(map.mapToScreen(gpsX, gpsY, mapZooms[mapZoom], Swidth, Sheight, track:getLatestHistoryPosition():getX(), track:getLatestHistoryPosition():getY()))
            trackOnScreenPositions[index] = trackOnScreenPosition

            --rectangle with 90 deg offset
            --TODO: change the way its drawn! less tokens means better. Cutting features if necessary
            tospX = trackOnScreenPosition:getX()
            tospY = trackOnScreenPosition:getY()
            rad90 = math.rad(90)
            rad180 = math.rad(180)
            tang = track:getAngle()
            p1x = tospX + 3 * math.sin(tang + rad90)
            p1y = tospY + 3 * math.cos(tang + rad90)
            p2x = tospX + 3 * math.sin(tang - rad90)
            p2y = tospY + 3 * math.cos(tang - rad90)
            p4x = tospX + 3 * math.sin(tang + rad180)
            p4y = tospY + 3 * math.cos(tang + rad180)
            p3x = tospX + 3 * math.sin(tang)
            p3y = tospY + 3 * math.cos(tang)
            p5 = newCoordinate(tospX + track:getSpeed() * math.sin(tang), trackOnScreenPosition:getY() + track:getSpeed() * math.cos(tang)) -- speed vector end
            if track:getState() == 0 then
                screen.setColor(255, 0, 0)
                if track:getHistoryLength() < 60 then
                    ---triangle for tracks with less than 60 history points
                    screen.drawLine(p1x, p1y, p3x, p3y)
                    screen.drawLine(p3x, p3y, p2x, p2y)
                else
                    ---rectangle for tracks with more than 60 history points
                    screen.drawLine(p1x, p1y, p3x, p3y)
                    screen.drawLine(p3x, p3y, p2x, p2y)
                    screen.drawLine(p2x, p2y, p4x, p4y)
                    screen.drawLine(p4x, p4y, p1x, p1y)
                end
                ---line for speed vector
                screen.drawLine(p3x, p3y, p5:getX(), p5:getY())
            elseif track:getState() == 1 then
                --cross shape for coasted tracks
                --TODO: reduce number of tokens used
                rad45 = math.rad(45)
                rad135 = math.rad(135)
                p6x = tospX + 3 * math.sin(tang + rad45)
                p6y = tospY + 3 * math.cos(tang + rad45)
                p7x = tospX + 3 * math.sin(tang - rad45)
                p7y = tospY + 3 * math.cos(tang - rad45)
                p8x = tospX + 3 * math.sin(tang + rad135)
                p8y = tospY + 3 * math.cos(tang + rad135)
                p9x = tospX + 3 * math.sin(tang - rad135)
                p9y = tospY + 3 * math.cos(tang - rad135)
                screen.drawLine(p6x, p6y, p8x, p8y) -- drawing the cross
                screen.drawLine(p7x, p7y, p9x, p9y)
                screen.drawLine(trackOnScreenPosition:getX(), trackOnScreenPosition:getY(), p5:getX(), p5:getY()) --adding speed vector with origin at the coasted track
                onScreenPredicted = newCoordinate(map.mapToScreen(gpsX, gpsY, mapZooms[mapZoom], Swidth, Sheight, track:getPrediction():getX(), track:getPrediction():getY()))
                screen.drawLine(trackOnScreenPosition:getX(), trackOnScreenPosition:getY(), onScreenPredicted:getX(), onScreenPredicted:getY()) -- drawing line to the prediction

                --#region drawing the history of the coasted track
                local tempT = 0
                local i = #track:getHistory() - 1
                while tempT < 600 and i > 1 do -- 10 seconds worth of data or until the end of the history
                    tempT = tempT + track:getUpdateTimes()[i] -- adding the update time of that step to the total time
                    -- retrieving the current and next point to draw a line between
                    currentDrawPosition = newCoordinate(map.mapToScreen(gpsX, gpsY, mapZooms[mapZoom], Swidth, Sheight, track:getHistory()[i]:getX(), track:getHistory()[i]:getY()))
                    nextDrawPosition = newCoordinate(map.mapToScreen(gpsX, gpsY, mapZooms[mapZoom], Swidth, Sheight, track:getHistory()[i - 1]:getX(), track:getHistory()[i - 1]:getY()))
                    screen.drawLine(currentDrawPosition:getX(), currentDrawPosition:getY(), nextDrawPosition:getX(), nextDrawPosition:getY())
                    i = i - 1 -- because we are iterating backwards through the data
                end
                --#endregion
            end
        else
            if selectedTrack == index then
                for i = 0, track:getHistoryLength() - 1 do --drawing the entire history of the selected track as a red line to the map
                    position = track:getHistory()[i]
                    nextPosition = track:getHistory()[i + 1]
                    historyOnScreenPosition = newCoordinate(map.mapToScreen(gpsX, gpsY, mapZooms[mapZoom], Swidth, Sheight, position:getX(), position:getY()))
                    nextOnScreenPosition = newCoordinate(map.mapToScreen(gpsX, gpsY, mapZooms[mapZoom], Swidth, Sheight, nextPosition:getX(), nextPosition:getY()))
                    screen.setColor(255, 0, 0, 50)
                    screen.drawLine(historyOnScreenPosition:getX(), historyOnScreenPosition:getY(), nextOnScreenPosition:getX(), nextOnScreenPosition:getY())
                end
            end
        end
    end
    screen.setColor(255, 255, 255)
    --TODO: draw the radar cone
    --screen.drawText(0, 0, "#" .. #tracks)
    screen.drawText(0, 6, string.format("%02d", math.abs(math.floor(radarRotation * 360))))
end