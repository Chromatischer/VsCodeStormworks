-- Author: Chromatischer
-- GitHub: github.com/Chromatischer
-- Workshop: steamcommunity.com/profiles/76561199061545480/
--
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


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

rawRadarData = Vec3(0, 0, 0)
contacts = {}
zoom = 1
contactSymbol = "||"

ticks = 0
function onTick()
    ticks = ticks + 1
    --inputs: 1-3: Self GPS, 4: Self Angle, 6: Radar Rotation, 7: Distance, 8: Azimuth, 9: Elevation, 10: Time since detected
    --inputs: 1: target Detected

    gpsX = input.getNumber(1)
    gpsY = input.getNumber(2)
    gpsZ = input.getNumber(3)
    selfAngle = input.getNumber(4) * 360 + 180 --convert to degrees (-0.5 to 0.5 to 0 to 360)
    selfPitch = input.getNumber(5)
    radarRotation = input.getNumber(6) * 360 + 180
    contactDistance = input.getNumber(7)
    contactAzimuth = input.getNumber(8)
    contactElevation = input.getNumber(9)
    contactTSD = input.getNumber(10)
    targetDetected = input.getBool(1)

    screen.drawTextBox

    relPos = radarToRelativeVec3(contactDistance, contactAzimuth, contactElevation, selfAngle, selfPitch)
    if contactTSD ~= 0 then
        rawRadarData = scalarDivideVec3(addVec3(relPos, scaleVec3(rawRadarData, contactTSD - 1)), contactTSD) ---@type Vec3
    else
        if vec3length(rawRadarData) > 50 then
            table.insert(contacts, addField(addVec3(rawRadarData, Vec3(gpsX, gpsY, gpsZ)), "t", ticks))
            rawRadarData = Vec3(0, 0, 0)
        end
    end

    for i, contact in ipairs(contacts) do
        if ticks - contact.t > 3000 then --3000 ticks = 50 seconds at 60 ticks per second or almost a minute
            table.remove(contacts, i)
        end
    end
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    setMapColors(false)
    screen.drawMap(gpsX, gpsY, zoom)

    for _, contact in ipairs(contacts) do
        x, y = map.mapToScreen(gpsX, gpsY, zoom, Swidth, Sheight, contact.x, contact.y)
        alpha = math.clamp(1 - percent(ticks - contact.t, 0, 3000), 0, 1)
        screen.setColor(255, 255, 255, 255 * alpha)
        screen.drawText(x, y, contactSymbol)
    end

    screen.setColor(255, 255, 255)
    screen.drawText(5, 5, "C:" .. #contacts)

    --draw a radar rotation line
    screen.setColor(255, 255, 255)
    screen.drawLine(Swidth / 2, Sheight / 2, Swidth / 2 + 50 * math.cos(math.rad(radarRotation)), Sheight / 2 + 50 * math.sin(math.rad(radarRotation)))
end
