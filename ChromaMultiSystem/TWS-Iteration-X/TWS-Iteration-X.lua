-- Author: Chromatischer
-- GitHub: https://github.com/Chromatischer
-- Workshop: https://shorturl.at/acefr

--Discord: @chromatischer--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

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
    end;
end
---@endsection

require("Utils.Utils")
require("Utils.Radar.BestTrackAlgorithm")
require("Utils.Radar.radarToGlobalCoordinates")
require("Utils.DrawAddons")

--Will use 3 simultaneous contacts for now... so that means: 3 azimuths, 3 elevations, 3 distances, 3 contact statuses

--#region CH Layout
-- CH1: Global Scale
-- CH2: GPS X
-- CH3: GPS Y
-- CH4: GPS Z
-- CH5: Vessel Angle
-- CH6: Screen Select I
-- CH7: Screen Select II
-- CH8: Touch X I
-- CH9: Touch Y I
-- CH10: Touch X II
-- CH11: Touch Y II

-- CHB1: Global Darkmode
-- CHB2: Touch I
-- CHB3: Touch II
--#endregion

lastRadarRotation = 0
lastRadarDelta = 0
radarMovingPositive = true
tracks = {} ---@type table<Track> Tracks
contacts = {} ---@type table<x, y, z> Contacts
rawRadarData = {{}, {}, {}} ---@type table<table<table<x, y, z>>> Raw Radar Data
SelfIsSelected = false
reachedLimit = false
screenCenterX = 0
screenCenterY = 0
gpsX, gpxY, gpsZ = 0, 0, 0
finalZoom = 1

trackMaxUpdateTicks = 600
trackMaxGroupDistance = 100

ticks = 0
function onTick()
    ticks = ticks + 1
    gpsX = input.getNumber(1)
    gpsY = input.getNumber(2)
    gpsZ = input.getNumber(3)
    vesselAngle = input.getNumber(4)
    compas = (vesselAngle - 180) / 360 --This is fucking stupid and I go to hell for this... just wildly inefficient (reverse conversion :D)
    finalZoom = input.getNumber(5)
    screenCenterX = input.getNumber(6)
    screenCenterY = input.getNumber(7)
    touchX = input.getNumber(8)
    touchY = input.getNumber(9)

    radarRotation = input.getNumber(10)

    isDepressed = input.getBool(1)
    CHDarkmode = input.getBool(2)
    SelfIsSelected = input.getBool(3)

    --Read the raw data into the Raw tables
    if SelfIsSelected then
        dataOffset = 11
        boolOffset = 4
        for i = 0, 2 do
            distance = input.getNumber(i * 4 + dataOffset)
            if input.getBool(i + boolOffset) and distance > 20 then
                --DONE: add pre evaluation smoothing using TimeSinceDetected
                --This works good! The data is being smoothed really nicely
                --TODO: find out, why there are ghost targets apearing betweeen the actual target and the radar itself
                --These ghost targets are in one line with the radar and the actual target
                --They are mirroring the speed, as well as angle of the actual target, though the speed is half of that of the actual target
                --I can imagine this phenomenon is caused by the averaging, though I am unsure of how I can fix this!
                if input.getNumber(i * 4 + 3 + dataOffset) ~= 0 then --while Time Since Detected is not 0 the coordinates are added to a temporary table
                    table.insert(rawRadarData[i + 1], radarToGlobalCoordinates(distance, input.getNumber(i * 4 + 1 + dataOffset), input.getNumber(i * 4 + 2 + dataOffset), gpsX, gpsY, gpsZ, compas, input.getNumber(13)))
                else --If Time Since Detected is 0, the values are averaged and added to the contacts table
                    sumX, sumY, sumZ = 0, 0, 0
                    for _, raw in ipairs(rawRadarData[i + 1]) do
                        sumX = sumX + raw.x
                        sumY = sumY + raw.y
                        sumZ = sumZ + raw.z
                    end

                    table.insert(contacts, {x = sumX / #rawRadarData[i + 1], y = sumY / #rawRadarData[i + 1], z = sumZ / #rawRadarData[i + 1]})
                    rawRadarData[i + 1] = {}
                end
            end
        end

        radarIsContinousRotation = property.getBool("Radar Mode: ")
        --Right now I will not do pre-target smoothing using the time since detected... I will use the plain position, but this will be an option in the future
        --This checks if either the radar has done a full rotation, or if the radar has changed direction, so has hit one of its limits and is now moving the other way
        --TODO: When updating, the data gets messed up when on the edge of the detection
        if (radarRotation % 180 < 3 and radarIsContinousRotation) then -- or ((lastRadarDelta > 0 and radarMovingPositive) or (lastRadarDelta < 0 and not radarMovingPositive) and (not radarIsContinousRotation)) then
            reachedLimit = true
            for i = #tracks, 1, -1 do                                                           --Step I: delete dead tracks
                if tracks[i].tSinceUpdate > trackMaxUpdateTicks then
                    table.remove(tracks, i)
                end
            end

            tracks, contacts = bestTrackDoubleAssignements(contacts, tracks, trackMaxGroupDistance) --Step II: update tracks

            for i = #contacts, 1, -1 do                                                    --Step III: make new tracks from remaining contacts and remove them from the contacts table
                table.insert(tracks, Track(contacts[i]))
                table.remove(contacts, i)
            end
        end

        --#region Radar movement direction
        lastRadarDelta = radarRotation - lastRadarRotation
        lastRadarRotation = radarRotation
        radarMovingPositive = lastRadarDelta > 0
        --#endregion

        for _, track in ipairs(tracks) do
            track:update()
        end
    end
end


function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    i = 0
    for _, track in ipairs(tracks) do
        track = track ---@type Track
        setSignalColor(CHDarkmode)
        px, py = map.mapToScreen(screenCenterX, screenCenterY, finalZoom, Swidth, Sheight, track:getLatest().x, track:getLatest().y)
        screen.drawLine(px - 2, py, px + 2, py)
        screen.drawLine(px - 2, py + 1, px - 2, py)
        screen.drawLine(px + 2, py + 1, px + 2, py)
        setSignalColor(CHDarkmode)
        screen.setColor(255, 255, 255)
        bigR = track.speed * 20
        mx, my = px + (bigR) * math.sin(track.angle), py + (bigR) * math.cos(track.angle)
        screen.drawLine(px, py, mx, my)
        -- The speed was broken because somehow the same track was updated twice, which set the tSinceUpdate to 0 and the speed to infinity
        screen.drawText(px, py, numToFormattedInt(track.speed * 60, 2))
        --screen.drawText(px, py + 4, track.tSinceUpdate)
        estPos = track:calcEstimatePosition()
        seX, seY = map.mapToScreen(screenCenterX, screenCenterY, finalZoom, Swidth, Sheight, estPos.x, estPos.y)
        screen.setColor(0, 255, 0)
        screen.drawRectF(seX, seY, 2, 2)
        i = i + 1
    end

    if reachedLimit then
        screen.setColor(255, 0, 0, 50)
        screen.drawRect(0, 0, Swidth, Sheight)
        reachedLimit = false
    end
end
