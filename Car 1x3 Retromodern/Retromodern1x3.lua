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
    simulator:setScreen(1, "3x1")
    simulator:setProperty("Idle RPS", 6)
    simulator:setProperty("Max RPS", 25)
    simulator:setProperty("Max Indicated Speed", 100)
    simulator:setProperty("0", "000000001001001111110100001010000101111110")
    simulator:setProperty("1", "000000000110000110000110011001100000011000")
    simulator:setProperty("2", "000000001111000100111011110101111110111100")
    simulator:setProperty("3", "000000000011000000110011001100001100001100")
    simulator:setProperty("4", "000000011111100010000001011100101000000111")
    simulator:setProperty("5", "010000000000010")
    simulator:setProperty("6", "000000000111000001000000100011000110011100")

    simulator:setProperty("Engine Overheat Warning Temperature", 80)
    simulator:setProperty("Fuel Low Percent", 25)
    simulator:setProperty("Battery Low Percentage", 75)
    simulator:setProperty("Upshift RPS", 19)
    simulator:setProperty("Downshift RPS", 6)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)
        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputNumber(4, simulator:getSlider(2) * 30)
        simulator:setInputNumber(5, simulator:getSlider(3) * 25)
        simulator:setInputNumber(6, 4)
        simulator:setInputNumber(7, math.floor(simulator:getSlider(1) * 8.1))
        simulator:setInputNumber(10, simulator:getSlider(4) * 100)
        simulator:setInputNumber(11, simulator:getIsToggled(2) and 1 or 2)
        simulator:setInputNumber(14, simulator:getSlider(5))
        simulator:setInputNumber(15, simulator:getSlider(6))
        simulator:setInputNumber(16, simulator:getSlider(7))
        simulator:setInputNumber(17, simulator:getSlider(8))
        simulator:setInputBool(2, simulator:getIsClicked(3))
        simulator:setInputBool(3, simulator:getIsToggled(1))
        simulator:setInputNumber(1, ticks)
        simulator:setInputNumber(2, ticks)
        simulator:setInputNumber(3, ticks)
    end;
end
---@endsection

require("Utils.Utils")
require("Utils.draw_additions")
require("Utils.MatrixDrawer")
require("Utils.Color_Lerp")
require("Utils.Time.timeUtils")

gModestr = {"P", "R", "D", "M", "N"}
selScreen, lastX, lastY, lastZ, ticks, displayFuel, displayBattery, displayEndurance, displayRange, displayTSpeed, trackMeters = 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

gray = function ()
    screen.setColor(100, 100, 100)
end
red = function ()
    screen.setColor(255, 0, 0)
end
green = function ()
    screen.setColor(0, 255, 0)
end
yellow = function ()
    screen.setColor(155, 255, 0)
end

fuelDeltas = {0}
positionDeltas = {0}
updateRate = 5

function onTick()
    ticks = ticks + 1
    gpsX = input.getNumber(1)
    gpsY = input.getNumber(3)
    gpsZ = input.getNumber(2)
    speed = input.getNumber(4) * 3.6
    eRps = input.getNumber(5)
    gMode = input.getNumber(6)
    gGear = math.round(input.getNumber(7))
    eTemp = input.getNumber(8)
    bdir = input.getNumber(9)
    fuelCapacity = input.getNumber(10)
    fuelLevel = input.getNumber(11)
    battLevel = input.getNumber(12)
    tcVal = input.getNumber(13)
    throttle = input.getNumber(14)
    breaks = input.getNumber(15)
    torque = input.getNumber(16)
    wRps = input.getNumber(17)

    dModeSwitch = input.getBool(1)
    bActive = input.getBool(2)

    minRps = property.getNumber("Idle RPS")
    maxRps = property.getNumber("Max RPS")
    maxSpd = property.getNumber("Max Indicated Speed")
    batteryIconMatrixStr = property.getText("0")
    leftIndicatorMatrixStr = property.getText("1")
    fuelIconMatrixStr = property.getText("2")
    rightIndicatorMatrixStr = property.getText("3")
    tractionIndicatorMatrixStr = property.getText("4")
    colonMatrixStr = property.getText("5")
    overheatMaxtrixStr = property.getText("6")
    tempWarn = property.getNumber("Engine Overheat Warning Temperature")
    fuelWarn = property.getNumber("Fuel Low Percent")
    battWarn = property.getNumber("Battery Low Percentage")
    gShiftUp = property.getNumber("Upshift RPS")
    gShiftDown = property.getNumber("Downshift RPS")

    --setting new defaults on spawning
    if ticks < 10 then
        lastX, lastY, lastZ = gpsX, gpsY, gpsZ
    end

    if dModeSwitch then
        selScreen = selScreen < 5 and selScreen + 1 or 1
    end

    --#region Fuel calculations
    if #fuelDeltas > 50 then
        table.remove(fuelDeltas)
    end

    if #positionDeltas > 50 then
        table.remove(positionDeltas)
    end

    --every 5 seconds @60 tps
    if ticks % (updateRate * 60) == 0 then
        table.insert(fuelDeltas, 1, fuelDeltas[1] - fuelLevel)
        table.insert(positionDeltas, 1, math.sqrt((gpsX - lastX) ^ 2 + (gpsY - lastY) ^ 2 + (gpsZ - lastZ) ^ 2))
        trackMeters = trackMeters + positionDeltas[1]
        lastX = gpsX
        lastY = gpsY
        lastZ = gpsZ
    end

    tSpeed = math.clamp(math.abs(positionDeltas[1]) / updateRate, 0, 9e9)
    endurance = math.clamp(fuelLevel / (fuelDeltas[1] / updateRate), 0, 9e9)
    endurance = endurance == endurance and endurance or 0
    tSpeed = tSpeed == tSpeed and tSpeed or 0
    range = tSpeed * endurance
    --#endregion

    speedPercent = math.clamp(math.abs(speed) / maxSpd, 0, 1)
    erpsPercent = math.clamp(percent(eRps, minRps, maxRps), 0, 1)
    fuelPercentage = math.clamp(percent(fuelLevel, 0, fuelCapacity), 0, 1)
    fuelPercentage = fuelPercentage == fuelPercentage and fuelPercentage or 0
    shiftPercentage = math.clamp(percent(eRps, gShiftDown, gShiftUp), 0, 1)
    thbrPercentage = (throttle / 2 - breaks / 2) + 0.5
    whp = torque * wRps / 9.5488

    displayFuel = exponentialMovingAverage(fuelPercentage, displayFuel, 0.05)
    displayBattery = exponentialMovingAverage(battLevel, displayBattery, 0.05)
    displayEndurance = exponentialMovingAverage(endurance, displayEndurance, 0.05)
    displayRange = exponentialMovingAverage(range, displayRange, 0.05)
    displayTSpeed = exponentialMovingAverage(tSpeed, displayTSpeed, 0.05)
end

function onDraw()
    screen.setColor(16, 13, 13, 50)
    screen.drawRectF(0, 0, 96, 32)

    for i = - 8, 32 do
        screen.setColor(3, 3, 3, 100)
        intern = i * 4
        screen.drawLine(intern, 0, intern + 32, 32)
        screen.setColor(1, 1, 1, 100)
        intern = i * 4 + 1
        screen.drawLine(intern, 0, intern + 32, 32)
    end


    gray()
    screen.drawLine(23, 25, 73, 25)
    screen.drawLine(23, 25, 16, 32)
    screen.drawLine(73, 25, 80, 32)

    --#region Dial indicators
    pi3 = math.pi * 1.3
    screen.setColor(255, 10, 10)
    currThbrPos = pi3 * thbrPercentage + 1.5 * math.pi
    screen.drawLine(80 + 10 * math.sin(currThbrPos), 16 - 10 * math.cos(currThbrPos), 80 + 15 * math.sin(currThbrPos), 16 - 15 * math.cos(currThbrPos))

    gray()
    drawCircle(16, 16, 15, 16, 0 * math.pi, pi3)
    drawCircle(80, 16, 15, 16, -0.3 * math.pi, pi3)
    screen.setColor(150, 5, 5)
    drawCircle(80, 16, 15, 16, 1.7 * math.pi, 0.3 * math.pi)

    red()
    currPosSpd = pi3 * speedPercent + 1.2 * math.pi
    screen.drawLine(16, 16, 16 + 14 * math.sin(currPosSpd), 16 - 14 * math.cos(currPosSpd))

    currPosRps = pi3 * erpsPercent + 1.5 * math.pi
    screen.drawLine(80, 16, 80 + 14 * math.sin(currPosRps), 16 - 14 * math.cos(currPosRps))

    gray()
    screen.drawLine(15, 16, 18, 16)
    screen.drawLine(16, 15, 16, 18)
    screen.drawLine(79, 16, 82, 16)
    screen.drawLine(80, 15, 80, 18)
    SPDText = speed > 1 and formatThree(speed) or "SPD"
    RPSText = eRps > minRps and formatThree(eRps) or "RPS"
    screen.drawText(15, 19, SPDText)
    screen.drawText(67, 19, RPSText)
    --#endregion

    --#region bottom Indicators
    if gMode == 1 then
        gray()
    elseif gMode == 2 then
        red()
    elseif gMode < 5 then
        green()
    elseif gMode == 5 then
        yellow()
    end
    gBool = gMode == 3 or gMode == 4
    screen.drawText(gBool and 44 or 46, 27, gModestr[gMode] .. (gBool and gGear or ""))


    iconDrawer(eTemp > tempWarn, red, overheatMaxtrixStr, 20, 25)
    iconDrawer((bActive and bdir == 1) and ticks % 70 < 35, yellow, leftIndicatorMatrixStr, 36, 25)
    iconDrawer((bActive and bdir == 2) and ticks % 70 < 35, yellow, rightIndicatorMatrixStr, 52, 25)
    iconDrawer(fuelPercentage * 100 < fuelWarn, red, fuelIconMatrixStr, 59, 25)
    iconDrawer(battLevel * 100 < battWarn, red, batteryIconMatrixStr, 67, 25)
    iconDrawer(tcVal > 0 and ticks % 20 < 10, red, tractionIndicatorMatrixStr, 28, 25)
    --#endregion

    --#region Up/Downshift indicator Top
    gray()
    screen.drawLine(26, 1, 70, 1)
    for i = 1, 22 * shiftPercentage do
        cLerp = colorLerp({r = 255, g = 0, b = 0}, {r = 0, g = 255, b = 0}, shiftPercentage)
        screen.setColor(cLerp.r, cLerp.g, cLerp.b)
        if shiftPercentage < 0.9 or ticks % 20 < 10 then
            screen.drawLine(47 + i, 1, 48 + i, 1)
            screen.drawLine(48 - i, 1, 49 - i, 1)
        end
    end
    --#endregion

    --#region Screen Selector Bars
    for i = 0, 4 do
        currScreen = i + 1
        if currScreen ~= selScreen then
            screen.setColor(60, 60, 60)
        else
            screen.setColor(200, 200, 200)
        end
        screen.drawLine((29 + i) + i * 7, 4, (35 + i) + i * 7, 4)
    end
    --#endregion

    --#region Screen Drawing
    if selScreen == 1 then
        --drawDataInfoTextBox("F", formatThree(displayFuel * 100), "", "")
        drawDataInfoTextBox("F", formatThree(displayFuel * 100), "B", formatThree(displayBattery * 100))
    end

    if selScreen == 2 then
        drawDataInfoTextBox("R", formatThree(displayRange / 1000) .. "K")
    end

    if selScreen == 3 then
        drawDataInfoTextBox("C",formatThree(eTemp))
        screen.drawText(36, 13, "CHRMA")
    end

    if selScreen == 4 then
        drawDataInfoTextBox("T",formatThree(trackMeters / 1000) .. "K", "M", formatThree(fractionOfHoursToHoursAndMinutes(displayEndurance / 3600).m))
    end

    if selScreen == 5 then
        drawDataInfoTextBox("S", formatThree(displayTSpeed * 3.6), "H", formatThree(whp))
    end
    --#endregion
end

function drawDataInfoTextBox(prefix1, value1, prefix2, value2)
    --screen.drawRect(32, 6, 31, 5)
    --len: 32
    --#prefix1 + #value1 = 6
    xoffset1 = (32 - (#value1 + 1) * 5.3) / 2
    gray()
    screen.drawText(32 + xoffset1, 7, prefix1)
    drawMatrixFromString(colonMatrixStr, 6, 3, 35 + xoffset1, 7)
    screen.drawText(40 + xoffset1, 7, string.sub(value1, 0, 100))

    if prefix2 then
        xoffset2 = (32 - (#value2 + 1) * 5.3) / 2
        screen.drawText(32 + xoffset2, 13, prefix2)
        drawMatrixFromString(colonMatrixStr, 6, 3, 35 + xoffset2, 13)
        screen.drawText(40 + xoffset2, 13, string.sub(value2, 0, 100))
    end
end

function formatThree(number)
    return string.format("%03d", math.round(math.clamp(number, 0, 999)))
end

function iconDrawer(condition, color, matrixStr, x, y)
    if condition then
        color()
    else
        screen.setColor(50, 50, 50)
    end
    drawMatrixFromString(matrixStr, 7, 7, x, y)
end

--#region TempGraphic
--0 0 0 0 0 0 0
--0 # # # # # 0
--0 0 0 # 0 0 0
--0 0 0 # 0 0 0
--# # 0 # 0 # #
--0 0 # # # 0 0

--temp: 001110000010000001000000100011000110011100
--#endregion

--#region IndicatorRight
--0 0 0 0 0 0 0
--0 0 0 # # 0 0
--0 0 0 0 # # 0
--0 # # 0 0 # #
--0 0 0 0 # # 0
--0 0 0 # # 0 0

--indicatorRight: 000000000011000000110011001100001100001100
--#endregion

--#region IndicatorLeft
--0 0 0 0 0 0 0
--0 0 # # 0 0 0
--0 # # 0 0 0 0
--# # 0 0 # # 0
--0 # # 0 0 0 0
--0 0 # # 0 0 0

--indicatorLeft: 000000000110000110000110011001100000011000
--#endregion

--#region FuelIcon
--0 0 0 0 0 0 0
--0 # # # # 0 0
--0 # 0 0 # # #
--0 # # # # 0 #
--0 # # # # # #
--0 # # # # 0 0

--FuelIcon: 000000001111000100111011110101111110111100
--#endregion

--#region BatteryIcon
--0 0 0 0 0 0 0
--0 # 0 0 # 0 0
--# # # # # # 0
--# 0 0 0 0 # 0
--# 0 0 0 0 # 0
--# # # # # # 0

--BatteryIcon: 000000001001001111110100001010000101111110
--#endregion

--#region Traction Control Icon

--0 0 0 0 0 0 0
--# # # # # # 0
--0 0 # 0 0 0 0
--0 0 # 0 # # #
--0 0 # 0 # 0 0
--0 0 0 0 # # #

--Traction Control Icon: 000000011111100010000001011100101000000111
--#endregion

--#region Screens
--1. Fuel Percentage, Battery Percentage
--2. Milage, Range
--3. Temperature
--4. Track Kilometers
--5. 
--#endregion

--#region Colon
--0 # 0
--0 0 0
--0 0 0
--0 0 0
--0 # 0

--Colon: 010000000000010
--#endregion
