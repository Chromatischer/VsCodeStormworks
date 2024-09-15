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
            distance = input.getNumber(i * 3 + dataOffset)
            if input.getBool(i + boolOffset) and distance > 20 then
                --adds the contacts to the contacts table in the form of x, y, z coordinates
                table.insert(contacts,
                    radarToGlobalCoordinates(distance, input.getNumber(i * 3 + 1 + dataOffset), input.getNumber(i * 3 + 2 + dataOffset), gpsX, gpsY, gpsZ, compas, input.getNumber(13))
                )
            end
        end

        radarIsContinousRotation = property.getBool("Radar Mode: ")
        --Right now I will not do pre-target smoothing using the time since detected... I will use the plain position, but this will be an option in the future
        --This checks if either the radar has done a full rotation, or if the radar has changed direction, so has hit one of its limits and is now moving the other way
        if (not (lastRadarDelta > 0 and radarMovingPositive) and radarIsContinousRotation) then -- or ((lastRadarDelta > 0 and radarMovingPositive) or (lastRadarDelta < 0 and not radarMovingPositive) and (not radarIsContinousRotation)) then
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

--Its 23:50... I'm tired
--Today is yesterday's tomorrow
--I will finish this tomorrow
--I will finish this tomorrow

--DONE: Fix the speed and angle calculation FYI: the the ticks since update is working fine but either distance or calc is not working! Good luck!
--DONE: Maybe allow double track for very small distance? like < 10m

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    i = 0
    for _, track in ipairs(tracks) do
        track = track ---@type Track
        --screen.setColor(255, 255, 255, 20)
        --screen.drawText(2, 2 + i * 7, " X:" .. numToFormattedInt(track:getLatest().x, 4) .. " Y:" .. numToFormattedInt(track:getLatest().y, 4))
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
        screen.drawText(px, py - 4, track.speed)
        screen.drawText(px, py + 4, track.tSinceUpdate)
        screen.drawText(px - 8, py, track.updates)
        i = i + 1
    end

    if reachedLimit then
        screen.setColor(255, 0, 0, 50)
        screen.drawRect(0, 0, Swidth, Sheight)
        reachedLimit = false
    end
end
