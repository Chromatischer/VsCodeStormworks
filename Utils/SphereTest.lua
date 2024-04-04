-- Author: Chromatischer
-- GitHub: https://github.com/Chromatischer
-- Workshop: https://shorturl.at/acefr

--Discord: @chromatischer--
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
require("Utils.sphereUtils")


ticks = 0
function onTick()
    ticks = ticks + 1
end

--function onDraw()
    --drawEllipseWithAngle(0, 0, 60, 60, 0, 0)
    --drawEllipse(0, 0, 30, 60, math.pi / 2)
    --screen.setColor(255, 0, 0)
    --drawEllipse(0, 20, 60, 20)
    --screen.setColor(0, 255, 0)
    --drawEllipse(25, 0, 10, 60)
    --screen.setColor(0, 0, 255)
    --drawEllipse(0, 0, 60, 60)

    --drawSphere(32, 32, 20)
    --drawSphere2(32,32,32,math.pi / 2)
    --drawGlobe(32, 32, 32)
    --lineLength = 32
    --lineCenterX = 48
    --lineCenterY = 48
    --drawSphere(lineCenterX, lineCenterY, lineLength, true, {r = 255, g = 255, b = 255}, true)
    --screen.setColor(230, 88, 27) -- Red
    --screen.drawLine(lineCenterX, lineCenterY, lineCenterX + lineLength, lineCenterY)
    --screen.setColor(18, 232, 98) -- Green
    --screen.drawLine(lineCenterX, lineCenterY, lineCenterX, lineCenterY - lineLength)
    --screen.setColor(18, 187, 232) -- Blue
    --thisLength = 7
    --x1 = lineCenterX + thisLength * math.sin(math.rad(360 - 45))
    --y1 = lineCenterY + thisLength * math.cos(math.rad(360 - 45))
    --screen.drawLine(lineCenterX, lineCenterY, x1, y1)
    --angle = math.rad(90)
    --screen.setColor(230, 88, 27) -- Red
    --x1 = lineCenterX + lineLength * math.sin(angle)
    --y1 = lineCenterY + lineLength * math.cos(angle)
    --screen.drawLine(lineCenterX, lineCenterY, x1, y1)
    --screen.setColor(18, 232, 98) -- Green
    --x2 = lineCenterX + lineLength * math.sin(angle - math.rad(120))
    --y2 = lineCenterY + lineLength * math.cos(angle - math.rad(120))
    --screen.drawLine(lineCenterX, lineCenterY, x2, y2)
    --screen.setColor(18, 187, 232) -- Blue
    --screen.drawLine(lineCenterX, lineCenterY, lineCenterX, lineCenterY - lineLength)

--end
function onDraw()
    point = {0, 0, 0}
    point2 = {0, 5, 0}
    point3 = {5, 0, 0}
    point4 = {0, 0, 5}
    camera = {10, 0, 10}
    cameraRotation = {-90, 45, 90}
    fov = 50
    projected = projectPoint(point, camera, cameraRotation, 64, 64, fov)
    projected2 = projectPoint(point2, camera, cameraRotation, 64, 64, fov)
    projected3 = projectPoint(point3, camera, cameraRotation, 64, 64, fov)
    projected4 = projectPoint(point4, camera, cameraRotation, 64, 64, fov)
    screen.setColor(255, 0, 0)
    screen.drawRectF(projected[1], projected[2], 2, 2)
    screen.setColor(0, 255, 0)
    screen.drawRectF(projected2[1], projected2[2], 2, 2)
    screen.setColor(0, 0, 255)
    screen.drawRectF(projected3[1], projected3[2], 2, 2)
    screen.setColor(255, 255, 0)
    screen.drawRectF(projected4[1], projected4[2], 2, 2)
    print("p1 " .. projected[1] .. " " .. projected[2])
    print("p2 " .. projected2[1] .. " " .. projected2[2])
    print("p3 " .. projected3[1] .. " " .. projected3[2])
    print("p4 " .. projected4[1] .. " " .. projected4[2])
end
