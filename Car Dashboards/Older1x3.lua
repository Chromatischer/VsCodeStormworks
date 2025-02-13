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
    simulator:setScreen(1, "3x1")
    simulator:setProperty("STLOGO", "000000000010111111111010000100100011001010000001011000011100100000")

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.touchX)
        simulator:setInputNumber(2, screenConnection.touchY)
    end;
end
---@endsection

require("Utils")
require("Color")
require("DrawAddons")
require("Vectors.vec2")
require("MatrixDrawer")

ticks = 0
function onTick()
    ticks = ticks + 1
    tx = input.getNumber(1)
    ty = input.getNumber(2)
    speed = input.getNumber(3)
    engineRPM = input.getNumber(4)
    engineTemp = input.getNumber(5)
    fuelLevel = input.getNumber(6)
    battLevel = input.getNumber(7)

    fuelCapacity = property.getNumber("Fuel Capacity")
    logoST = property.getText("STLOGO")

    isTouch = input.getBool(1)

    if isTouch then
        print("Touch at: " .. tx .. ", " .. ty)
    end
end

function onDraw()
    Swidth, Sheight = screen.getWidth(), screen.getHeight()
    mainColor = Color(255, 0, 0)
    lightGray = Color(150, 150, 150)

    --I want three circles, two on the left, right as well as low
    --One at the middle a little higher
    --Left is for the fuel and temperature
    --Middle is the RPM
    --Right is the speed
    --Icons to both sides of the middle circle for warnings

    amount = math.pi * 6 / 4
    start = math.pi / 4
    numberOfLines = 10

    --#region Left
    setAsScreenColor(lightGray)
    screen.drawCircle(13, 32 - 13, 12)

    --#endregion

    --#region Middle
    setAsScreenColor(lightGray)
    screen.drawCircle(48, 15, 14)
    center = Vec2(48, 15)
    setAsScreenColor(mainColor)
    for i = 0, numberOfLines do
        angle = amount / numberOfLines * i + start

        px1 = transformScalar(center, angle, 14)
        px2 = transformScalar(center, angle, 10)

        screen.drawLine(px1.x, px1.y, px2.x, px2.y)
    end
    drawMatrixFromString(logoST, 6, 11, 42, 10)
    print(#logoST)
    --#endregion

    --#region Right
    setAsScreenColor(lightGray)
    screen.drawCircle(83, 32 - 13, 12)

    --#endregion

    --#region Bottom Box
    setAsScreenColor(lightGray)
    screen.drawLine(26, 24, 38, 24)
    screen.drawLine(58, 24, 70, 24)
    screen.drawLine(25, 25, 25, 32)
    screen.drawLine(70, 25, 70, 32)

    --#endregion

    --#region Other Lines
    setAsScreenColor(lightGray)
    screen.drawLine(24, 14, 35, 8)
    screen.drawLine(60, 8, 71, 14)

    --#endregion
end


--ST Matrix graphic
--0 0 0 0 0 0 0 0 0 0 #
--0 # # # # # # # # # 0
--# 0 0 0 0 # 0 0 # 0 0
--0 # # 0 0 # 0 # 0 0 0
--0 0 0 # 0 # # 0 0 0 0
--# # # 0 0 # 0 0 0 0 0

--as string 