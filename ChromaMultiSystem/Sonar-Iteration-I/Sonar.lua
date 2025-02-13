-- Author: Chromatischer
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
--
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

require("Color")
require("DrawAddons")
require("Utils")
require("Sonar.SonarHelper")
require("Vectors.vec2")
require("Vectors.vec3")

screenCenterX, screenCenterY = 0, 0
maxSonarRange = 0
lastPulse = 0
pulseEvery = 0
sonarContacts = {} ---@type table<SonarContact> Sonar contacts
sendPing = false

ticks = 0
function onTick()
    ticks = ticks + 1
    gpsX = input.getNumber(1)
    gpsY = input.getNumber(2)
    gpsZ = input.getNumber(3)
    vesselAngle = input.getNumber(4)
    zoom = input.getNumber(5)
    screenCenterX = input.getNumber(6)
    screenCenterY = input.getNumber(7)
    touchX = input.getNumber(8)
    touchY = input.getNumber(9)
    maxSonarRange = input.getNumber(10)
    vesselPitch = input.getNumber(11) * 360

    isDepressed = input.getBool(1)
    CHDarkmode = input.getBool(2)
    SelfIsSelected = input.getBool(3)
    SonarActive = input.getBool(4)

    pulseEvery = math.ceil(secondsToTicks(timeToWait(maxSonarRange)))
    --Read sonar data for 8 contacts, save the time since the last ping and therefore the distance to the object
    --Data input structure: pivot1, pitch1, pivot2, pitch2
    for i = 1, 8 do
        num = i - 1
        numOffset = 12
        boolOffset = 5
        if input.getBool(num + boolOffset) then
            table.insert(sonarContacts, SonarContact(input.getNumber(numOffset + num * 2) * 360, input.getNumber(numOffset + num * 2 + 1) * 360, ticks - lastPulse, vesselAngle, vesselPitch, gpsX, gpsY, gpsZ))
        end
    end

    for i = #sonarContacts, 1, -1 do
        contact = sonarContacts[i] ---@type SonarContact
        updateSonarContact(contact)
        if contactDeprecated(contact) then
            table.remove(sonarContacts, i)
        end
    end

    --In theory, this should keep the ping signal high for every tick except when it is time to send a new ping where it is set to low for one tick and then back to high
    output.setBool(1, not sendPing)
    sendPing = false
    --calc 100m maxRange -> time between pings of 100/700=0.142857 seconds -> 0.1428 * 60 = 8.568 ticks -> 9 ticks because of ceil => 9 ticks between pings for 100m range

    if ticks - lastPulse > pulseEvery and SonarActive then --check if it is time to send a new ping
        lastPulse = ticks
        sendPing = true
    end
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    mapX, mapY = map.mapToScreen(screenCenterX, screenCenterY, zoom, Swidth, Sheight, gpsX, gpsY)
    for _, contact in ipairs(sonarContacts) do
        position = contact.globalPosition ---@type Vec3
        px, py = map.mapToScreen(screenCenterX, screenCenterY, zoom, Swidth, Sheight, position.x, position.y)

        setSignalColor(CHDarkmode)
        screen.drawText(px, py, "[]")
    end

    --draw current sonar ping
    currentDistance = distanceFromTime(ticksToSeconds(ticks - lastPulse))
    onScreenRadius = currentDistance / zoom * 1000 * Swidth
    onScreenMax = maxSonarRange / zoom * 1000 * Swidth
    setSignalColor(CHDarkmode)
    screen.drawCircle(mapX, mapY, onScreenRadius)

    setColorGrey(0.4, CHDarkmode)
    screen.drawCircle(mapX, mapY, onScreenMax)
end
