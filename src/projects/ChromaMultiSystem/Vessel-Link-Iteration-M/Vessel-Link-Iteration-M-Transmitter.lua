-- Author: Chromatischer
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x3")

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
    end;
end
---@endsection

require("Vectors.vec3")
require("Vectors.vec2")
require("Utils")
require("DataLink.DataLink")

ticks = 0
function onTick()
    ticks = ticks + 1
    gpsX = input.getNumber(1)
    gpsY = input.getNumber(2)
    gpsZ = input.getNumber(3)
    speed = input.getNumber(4)
    heading = (input.getNumber(5) * 360) + 180 --(-0.5 to 0.5) to 0 to 360
    ownID = input.getNumber(6)
    primaryRadioChannel = input.getNumber(7)
    secondaryRadioChannel = input.getNumber(8)
    currentWaypointX = input.getNumber(9)
    currentWaypointY = input.getNumber(10)
    currentWaypointZ = input.getNumber(11)
    currentWaypointID = input.getNumber(12)
    targetWaypointX = input.getNumber(13)
    targetWaypointY = input.getNumber(14)
    targetWaypointZ = input.getNumber(15)
    targetWaypointID = input.getNumber(16)
    soulsAboard = input.getNumber(17)
    fuelPercentage = input.getNumber(18)
    battery = input.getNumber(19)
    rainSensor = input.getNumber(20)
    fogSensor = input.getNumber(21)
    windSpeed = input.getNumber(22)
    vesselStatus = input.getNumber(23)
    missionStatus = input.getNumber(24)
    crewStatus = input.getNumber(25)
    commStatus = input.getNumber(26)

    hullDamage = input.getBool(1)
    flooding = input.getBool(2)
    radiosActive = input.getBool(3)

    crewStatus = soulsAboard == 0 and 6 or crewStatus
    commStatus = soulsAboard == 0 and 6 or commStatus
    commStatus = radiosActive and 5 or commStatus

    resourceStatus = 0
    if fuelPercentage < 0.75 then
        resourceStatus = 1
    end
    if fuelPercentage < 0.5 then
        resourceStatus = 2
    end
    if fuelPercentage < 0.25 then
        resourceStatus = 3
    end
    if fuelPercentage < 0.1 then
        resourceStatus = 4
    end

    if battLevel < 0.5 then
        resourceStatus = 8
    end
    if battLevel < 0.25 then
        resourceStatus = 9
    end

    environmentRating = 0
    environmentRating = environmentRating + rainSensor
    environmentRating = environmentRating + fogSensor
    environmentRating = environmentRating + (windSpeed / 30)

    environmentStatus = 1
    if environmentRating > 0.5 then
        environmentStatus = 2
    end
    if fogSensor > 0.3 then
        environmentStatus = 5
    end
    if fogSensor > 0.6 then
        environmentStatus = 6
    end
    if rainSensor > 0.6 then
        environmentStatus = 8
    end
    if windSpeed > 10 then
        environmentStatus = 3
    end
    if windSpeed > 20 then
        environmentStatus = 4
    end
    if windSpeed > 30 then
        environmentStatus = 7
    end
    if environmentRating > 0.8 then
        environmentStatus = 9
    end

    outputStatus = encodeStatus(vesselStatus, missionStatus, crewStatus, commStatus, resourceStatus, environmentStatus)

    obj1, obj2, obj3, obj4, obj5 = encodeVesselData(Vec3(gpsX, gpsY, gpsZ), vesselAngle, ownID, speed, vesselStatus, missionStatus, crewStatus, commStatus, resourceStatus, environmentStatus, primaryRadioChannel, secondaryRadioChannel, soulsAboard, Vec3(currentWaypointX, currentWaypointY, currentWaypointZ), currentWaypointID, Vec3(targetWaypointX, targetWaypointY, targetWaypointZ), targetWaypointID)
    if ownID > 0 and ownID < 199 then --check that neither 0 nor -1 are used as IDs
        outputEncodedAt(obj1, 1)
        outputEncodedAt(obj2, 3)
        outputEncodedAt(obj3, 5)
        outputEncodedAt(obj4, 7)
        outputEncodedAt(obj5, 9)
    end
end