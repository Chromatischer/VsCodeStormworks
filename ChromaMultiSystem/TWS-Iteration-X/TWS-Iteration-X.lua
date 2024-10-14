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
require("Utils.Color")
require("Utils.DrawAddons")
require("Utils.Vectors.vec2") --TODO: check for compilation mistakes in the compression, as the vec2 and vec3 have similar function names
require("Utils.Vectors.vec3")

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
contacts = {} ---@type table<Vec3> Contacts
rawRadarData = {{}, {}, {}} ---@type table< table<Vec3> > Raw Radar Data
SelfIsSelected = false
reachedLimit = false
screenCenterX = 0
screenCenterY = 0
gpsX, gpxY, gpsZ = 0, 0, 0
finalZoom = 1
debg = {0, 0, 0}
debg2 = {false, false, false}

trackMaxUpdateTicks = 600
trackMaxGroupDistance = 50

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
            radarData = rawRadarData[i + 1]
            distance = input.getNumber(i * 4 + dataOffset)
            targetDetected = input.getBool(i + boolOffset)
            debg2[i + 1] = targetDetected
            timeSinceDetected = input.getNumber(i * 4 + 3 + dataOffset)
            if targetDetected and distance > 20 then --Check if there is a target being detected and sensible for tracking
                debg[i + 1] = timeSinceDetected
                --Target data is always added to the temporary table to be evaluated later
                table.insert(rawRadarData[i + 1], radarToGlobalVec3(distance, input.getNumber(i * 4 + 1 + dataOffset), input.getNumber(i * 4 + 2 + dataOffset), gpsX, gpsY, gpsZ, compas, input.getNumber(13)))
            end

            --Ok, so the following is going to happen:
            --I: new target is detected, targetDetected is true and timeSinceDetected is 0, the data is added to the temporary table
            --II: the target stays inside the detection azimuth, time since detected is != 0, the data is added to the temporary table
            --III.1: the target is no longer detected so it is being flushed to the contacts table and the temporary table is emptied
            --III.2: the target is still detected but tsd is 0 (new target / new noise), the data is flushed to the contacts table and the temporary table is emptied
            if (not targetDetected) or (timeSinceDetected == 0 and targetDetected) then
                if #radarData > 0 then --Checks if there is data to be flushed
                    --Insets into the contacts table the average position of the recorded data
                    table.insert(contacts, scalarDivideVec3(sumTableVec3(Vec3(), radarData), #radarData))
                end
                rawRadarData[i + 1] = {}
            end
        end

        radarIsContinousRotation = property.getBool("Radar Mode: ")
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
            update(track)
        end
    end
end


function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    for _, track in ipairs(tracks) do
        track = track ---@type Track
        setSignalColor(CHDarkmode)
        px, py = map.mapToScreen(screenCenterX, screenCenterY, finalZoom, Swidth, Sheight, getLatest(track).x, getLatest(track).y)
        screen.drawLine(px - 2, py, px + 2, py)
        screen.drawLine(px - 2, py + 1, px - 2, py)
        screen.drawLine(px + 2, py + 1, px + 2, py)
        color = CHDarkmode and SIGNAL_DARK or SIGNAL_LIGHT
        screen.setColor(255, 0, 0)
        bigR = track.speed * 20
        mx, my = px + (bigR) * math.sin(track.angle), py + (bigR) * math.cos(track.angle)
        screen.drawLine(px, py, mx, my)
        --screen.drawText(px, py, numToFormattedInt(track.speed * 60, 2))
        --screen.drawText(px, py + 4, track.tSinceUpdate)
        estPos = calcEstimatePosition(track)
        seX, seY = map.mapToScreen(screenCenterX, screenCenterY, finalZoom, Swidth, Sheight, estPos.x, estPos.y)
        --setAsScreenColor(getWithModifiedValue(color, 0.5))
        screen.setColor(0, 255, 0, 100)
        screen.drawLine(px, py, seX, seY) --Draw a line to the estimated position of the target

        screen.setColor(255, 255, 255)
        screen.drawText(px, py, numToFormattedInt(distanceToVec3(Vec3(gpsX, gpsY, gpsZ), getLatest(track)), 3))
    end

    for _, contact in ipairs(contacts) do
        px, py = map.mapToScreen(screenCenterX, screenCenterY, finalZoom, Swidth, Sheight, contact.x, contact.y)
        screen.setColor(0, 255, 0)
        screen.drawRectF(px - 1, py - 1, 2, 2)
    end

    if reachedLimit then
        screen.setColor(255, 0, 0)
        screen.drawText(30, 30, "R")
        reachedLimit = false
    end
end
