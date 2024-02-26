-- Author: Chroma
-- GitHub: <GithubLink>
-- Workshop: <WorkshopLink>
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
    simulator:setScreen(1, "1x1")
    --simulator:setScreen(2, "2x2")
    --simulator:setScreen(3, "3x2")
    simulator:setScreen(4, "3x3")
    --simulator:setScreen(5, "5x3")
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
        simulator:setInputBool(31, simulator:getIsClicked(1))     -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))      -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))     -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50) -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

require("Utils.Utils")
require("Utils.draw_additions")
ticks = 0
frames = 0
time = 6
fake_loadings = {"Initializing", "Building", "Reverting", "Baking", "Applying", "Evaluating", "Completing", "Compiling", "Fishing", "Connecting", "Testing", "Imagining", "Ordering", "Downloading", "Unpacking", "Installing", "Mapmaking", "Positioning", "Chromatischer", "Programming", "Computing", "Moduling", "Sending", "Fetching", "Cooking", "Uploading", "Starting", "Affiliating", "Producing", "Polishing", "Finishing", "", "Done", "Yippie"}
function onTick()
    ticks = ticks + 1
end

function onDraw()
    Sheight = screen.getHeight()
    Swidth = screen.getWidth()
    if frames < time * 60 then
        screen.setColor(0, 0, 0)
        screen.drawRectF(-1, -1, Swidth + 1, Sheight + 1)
        screen.setColor(240, 115, 10, 50)
        if not (Swidth == 32 and Sheight == 32) then
            for i = -1, 1, 1 do
                angle = (frames / 2) % 360 * i
                length = Swidth / 2
                turnAngle = math.pi / 1.5
                backgroundLineTopX = length * math.sin(math.rad(angle)) + Swidth / 2
                backgroundLineTopY = length * math.cos(math.rad(angle)) + Sheight / 2
                backgroundLineBottomX = length * math.sin(math.rad(angle) + turnAngle) + Swidth / 2
                backgroundLineBottomY = length * math.cos(math.rad(angle) + turnAngle) + Sheight / 2
                backgroundLineSideX = length * math.sin(math.rad(angle) - turnAngle) + Swidth / 2
                backgroundLineSideY = length * math.cos(math.rad(angle) - turnAngle) + Sheight / 2
                screen.drawLine(backgroundLineTopX, backgroundLineTopY, backgroundLineSideX, backgroundLineSideY)
                screen.drawLine(backgroundLineBottomX, backgroundLineBottomY, backgroundLineSideX, backgroundLineSideY)
                screen.drawLine(backgroundLineTopX, backgroundLineTopY, backgroundLineBottomX, backgroundLineBottomY)
            end
            screen.setColor(240, 115, 10, 126)
            radius = Swidth / 4
            drawCircle(Swidth / 2, Sheight / 2, radius, 16, 0, (frames / time * 6 % 360) / 360 * math.pi * 2)
        end
        TopLine = Swidth > 32 and "Booting" or "BOOT"
        if Swidth > 32 then
            for i = 1, frames / 120 % 4, 1 do
                TopLine = TopLine .. "."
            end
        end
        firstLine = Swidth > 64 and "Chroma Systems" or Swidth > 32 and "Chroma" or "Chrm"
        secondLine = Swidth > 64 and "" or Swidth > 32 and "Systems" or "Stms"
        if Swidth > 32 then
            screen.setColor(240, 115, 10)
        else
            screen.setColor(240, 115, 10, (frames / 60)%2 * 512)
        end
        screen.drawText(Swidth / 2 - stringPixelLength(TopLine) / 2, 2, TopLine)
        screen.setColor(240, 115, 10)
        screen.drawText(Swidth / 2 - stringPixelLength(firstLine) / 2, Sheight / 2, firstLine)
        screen.drawText(Swidth / 2 - stringPixelLength(secondLine) / 2, Sheight / 2 + 7, secondLine)
        if Sheight > 32 then
            currentLoadingIndex = math.ceil(math.clamp(frames / (time * 60) * #fake_loadings, 1, #fake_loadings))
            currentLoadingString = fake_loadings[currentLoadingIndex]
            screen.drawText(Swidth / 2 - stringPixelLength(currentLoadingString) / 2, Sheight - 7, currentLoadingString)
        end
    end
    frames = frames + 1
end
