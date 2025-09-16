-- Author: Chromatischer
-- GitHub: https://github.com/Chromatischer
-- Workshop: https://shorturl.at/acefr

--Discord: @chromatischer--

---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "1x1")
    simulator:setProperty("Module 1:", "RDR")
    simulator:setProperty("Module 2:", "FISH")
    simulator:setProperty("Module 3:", "TTL")
    simulator:setProperty("Module 4:", "ENG")
    simulator:setProperty("Module 5:", "MAP")

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(5, screenConnection.touchX)
        simulator:setInputNumber(6, screenConnection.touchY)
    end;
end
---@endsection

require("Utils")

CHDarkmode = false
CHSel1 = 1
CHSel2 = 2
VScroll = 0
MaxVScroll = 22
lastPressed = 0

globalScales = {0.1, 0.2, 0.5, 1, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 15, 20, 25, 30, 40, 50}
globalScale = 4

ticks = 0
function onTick()
    ticks = ticks + 1
    output.setBool(1, CHDarkmode)
    output.setBool(2, input.getBool(2))
    output.setBool(3, input.getBool(3))

    output.setNumber(1, globalScale)
    output.setNumber(2, input.getNumber(1))
    output.setNumber(3, input.getNumber(2))
    output.setNumber(4, input.getNumber(3))
    output.setNumber(5, input.getNumber(4))
    output.setNumber(6, CHSel1)
    output.setNumber(7, CHSel2)
    output.setNumber(8, input.getNumber(7))
    output.setNumber(9, input.getNumber(8))
    output.setNumber(10, input.getNumber(9))
    output.setNumber(11, input.getNumber(10))


    touchX = input.getNumber(5)
    touchY = input.getNumber(6)
    isPressed = input.getBool(1)

    if isPressed then
        if touchY > 16 and touchX > 26 then
            VScroll = VScroll + 1 < MaxVScroll and VScroll + 1 or MaxVScroll
        elseif touchY < 16 and touchX > 26 then
            VScroll = VScroll - 1 > 0 and VScroll - 1 or 0
        elseif ticks - lastPressed > 10 then
            moduleNumber, screenSide = isModuleSelected(touchX, touchY)
            if moduleNumber == 0 then
                if screenSide == 1 then
                    globalScale = globalScale - 1 > 1 and globalScale - 1 or 1
                end
                if screenSide == 2 then
                    globalScale = globalScale + 1 < #globalScales and globalScale + 1 or #globalScales
                end
            elseif moduleNumber == 1 then
                CHDarkmode = not CHDarkmode
            elseif moduleNumber > 1 then
                moduleNumber = moduleNumber - 1
                if screenSide == 1 then
                    if CHSel2 ~= moduleNumber then
                        CHSel1 = moduleNumber
                    else
                        CHSel2 = CHSel1
                        CHSel1 = moduleNumber
                    end
                end
                if screenSide == 2 then
                    if CHSel1 ~= moduleNumber then
                        CHSel2 = moduleNumber
                    else
                        CHSel1 = CHSel2
                        CHSel2 = moduleNumber
                    end
                end
            end
            lastPressed = ticks
        end
    end
end

function onDraw()
    if CHDarkmode then
        screen.setColor(0, 2, 0, 20)
    else
        screen.setColor(2, 0, 0, 20)
    end
    screen.drawRectF(0, 0, 32, 32)
    for i = -66, 32, 4 do
        if CHDarkmode then
            screen.setColor(2, 5, 2, 70)
        else
            screen.setColor(20, 10, 10, 100)
        end
        screen.drawLine(i, 0 - VScroll, i + 66, 66 - VScroll)
        if CHDarkmode then
            screen.setColor(7, 10, 7, 70)
        else
            screen.setColor(30, 20, 20, 100)
        end
        screen.drawLine(i + 1, 0 - VScroll, i + 67, 66 - VScroll)
    end

    resetColor()
    for i = 1, 5 do
        drawSelectionText(i, i * 8 - VScroll + 8)
    end

    resetColor()
    meterStr = globalScales[globalScale] >= 1 and globalScales[globalScale] .. "K" or math.floor(globalScales[globalScale] * 1000) .. "M"
    if globalScale == #globalScales then
        setDark()
    end
    screen.drawText(1, 1 - VScroll, "+")
    resetColor()
    if globalScale == 1 then
        setDark()
    end
    screen.drawText(25, 1 - VScroll, "-")
    resetColor()
    screen.drawTextBox(5, 1 - VScroll, 21, 6, meterStr, 0.5, 0.5)
    screen.drawTextBox(1, 8 - VScroll, 28, 6, CHDarkmode and "DARK" or "LIGHT", 0.5, 0.5)

    screen.drawRectF(30, 0, 2, 32)
    setRed(1)
    screen.drawRectF(30, VScroll / MaxVScroll * 28, 2, 4)
    setRed(2)
    screen.drawRectF(31, 1 + VScroll / MaxVScroll * 28, 1, 3)
    setRed(1)
    if VScroll > 0 then
        screen.drawRectF(30, VScroll / MaxVScroll * 28 - 2, 2, 1)
    end
    if VScroll < MaxVScroll then
        screen.drawRectF(30, VScroll / MaxVScroll * 28 + 5, 2, 1)
    end
end

function drawSelectionText(moduleNumber, y)
    if moduleNumber == CHSel2 then
        setRed(1)
    end
    screen.drawText(1, y, "<")
    resetColor()
    screen.drawTextBox(5, y, 21, 6, property.getText("Module " .. moduleNumber .. ":"), 0.5, 0.5)
    if moduleNumber == CHSel1 then
        setRed(1)
    end
    screen.drawText(25, y, ">")
    resetColor()
end

function isModuleSelected(touchX, touchY)

    moduleHeight = 8
    moduleNumber = math.floor((touchY + VScroll + 2) / moduleHeight)

    if touchX < 16 then
        screenSide = 2
    end
    if touchX > 16 and touchX < 28 then
        screenSide = 1
    end
    return moduleNumber, screenSide
end

function resetColor()
    if CHDarkmode then
        screen.setColor(33, 33, 33)
    else
        screen.setColor(150, 150, 150)
    end
end

function setRed(value)
    if CHDarkmode then
        if value == 1 then
            screen.setColor(10, 30, 10)
        elseif value == 2 then
            screen.setColor(5, 15, 5)
        end
    else
        if value == 1 then
            screen.setColor(255, 20, 20)
        elseif value == 2 then
            screen.setColor(235, 10, 10)
        end
    end
end

function setDark()
    if CHDarkmode then
        screen.setColor(10, 10, 10)
    else
        screen.setColor(30, 30, 30)
    end
end