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
require("Utils.Vectors.vec2")
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
contacts = {} ---@type table<Vec3> Contacts in world space
rawRadarData = {Vec3(0, 0, 0), Vec3(0, 0, 0), Vec3(0, 0, 0)} ---@type table<Vec3> Raw Radar Data in relative space
SelfIsSelected = false
reachedLimit = false ---@type boolean True if the radar has reached the limit of the rotation and contacts are being flushed
screenCenterX = 0
screenCenterY = 0
gpsX, gpxY, gpsZ = 0, 0, 0
finalZoom = 1

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
        --#region Contact generation and averaging
        for i = 0, 2 do
            distance = input.getNumber(i * 4 + dataOffset)
            targetDetected = input.getBool(i + boolOffset)
            timeSinceDetected = input.getNumber(i * 4 + 3 + dataOffset)
            relPos = radarToRelativeVec3(distance, input.getNumber(i * 4 + 1 + dataOffset), input.getNumber(i * 4 + 2 + dataOffset), compas, input.getNumber(13))
            if timeSinceDetected ~= 0 then
                --#region doc stuff
                    --see: https://discord.com/channels/357480372084408322/578586360336875520/1295276857482281020 (message by smithy3141)

                    --this is sithy's low pass filter formula
                    --low pass filter formula (filters out noise gradually)
                    --$$new = old + \frac{value - old}{n}$$
                    --rawRadarData[i + 1] = addVec3(radarData, scalarDivideVec3(subtractVec3(relPos, radarData), timeSinceDetected)) ---@type Vec3
                    --from my understanding, this is better because it actually filters out the noise and not just smooths it out
                --#endregion

                --this is using the recursive average formula
                --$$new = \frac{(n-1) * old + value}{n} $$
                rawRadarData[i + 1] = scalarDivideVec3(addVec3(relPos, scaleVec3(rawRadarData[i + 1], timeSinceDetected - 1)), timeSinceDetected) ---@type Vec3
            elseif vec3length(relPos) > 50 then
                --Convert the relative position to a global position and add it to the contacts table
                table.insert(contacts, addVec3(relPos, Vec3(gpsX, gpsY, gpsZ)))
                rawRadarData[i + 1] = Vec3(0, 0, 0) --Is this right? Because then it will take the 0, 0, 0 into account for the average, which is bad?
            end
        end
        --#endregion
        
        --Ok, so what I have done now is remove the check for having reached the limit because it seems pointless in theory
        --The target tracking works the same way with and without it the difference being that it now updates instantly
        --This could have caused issues if I had single assignment as a relationship of 1:1 between contacts and tracks
        --But since I have multi-assignment, it should work fine and the exact same way as before but with less delay

        --TODO: check if this is the problem for not being able to track at 0 degrees

        --Delete dead tracks
        for i = #tracks, 1, -1 do
            if tracks[i].tSinceUpdate > trackMaxUpdateTicks then
                table.remove(tracks, i)
            end
        end

        --Update existing tracks
        tracks, contacts = bestTrackDoubleAssignements(contacts, tracks, trackMaxGroupDistance)

        --Create new tracks from remaining contacts
        for i = #contacts, 1, -1 do
            table.insert(tracks, Track(contacts[i]))
            table.remove(contacts, i) --Remove the contact from the contacts table
        end

        tracks = updateTrackT(tracks) --Use my own build function you stupid...
    end
end


function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    for _, track in ipairs(tracks) do
        --to draw is a triangle that points in the direction of the target with a line at the top in the direction of travel and the length being the estimated position at the current time!
        track = track ---@type Track
        setAsScreenColor(Color2(0, 0.8, 0.45, false))
        --Draw a circle, witht the radius being 5 and add a line from the cricles circumference to the estimated position of the target
        radius = 3
        trackPos = toMapSpace(vec3ToVec2(getLatest(track)), screenCenterX, screenCenterY, finalZoom, Swidth, Sheight)
        screen.drawText(trackPos.x - 3, trackPos.y - 2, "()")
        startPoint = transformScalar(trackPos, track.angle, radius)
        toPoint = transformScalar(trackPos, track.angle, radius + track.speed * 30)
        screen.drawLine(startPoint.x, startPoint.y, toPoint.x, toPoint.y)
    end
end
