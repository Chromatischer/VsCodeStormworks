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
        simulator:setInputNumber(15, screenConnection.touchX)
        simulator:setInputNumber(16, screenConnection.touchY)
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!

require("Utils.Utils")
require("Utils.Coordinate.radarToGlobalCoordinates")

ticks = 0
cameraInfraredActive = false
targetPitch = 0
cameraTargetFOV = 0
secondaryPivotSpeed = 0
function onTick()
    ticks = ticks + 1
    radarPivotCurrent = input.getNumber(1)
    laserDistance = input.getNumber(2)
    secondaryRadarXPos = input.getNumber(3)
    secondaryRadarZPos = input.getNumber(4)
    secondaryRadarYPos = input.getNumber(5)
    secondaryRadarOrientation = input.getNumber(6)
    primaryRadarRotation = input.getNumber(7)
    primaryRadarTargetOA = input.getNumber(8)
    primaryRadarTargetOE = input.getNumber(9)
    primaryRadarTargetTA = input.getNumber(10)
    primaryRadarTargetTE = input.getNumber(11)
    secondaryRadarOutput = input.getNumber(12) -- problably unused
    secondaryRadarTargetA = input.getNumber(13)
    secondaryRadarTargetE = input.getNumber(14)
    monitorTouchX = input.getNumber(15)
    monitorTouchY = input.getNumber(16)
    monitorIsTouched = input.getBool(1)
    primaryActive = input.getBool(2)
    primaryRadarTargetOD = input.getBool(3)
    primaryRadarTargetTD = input.getBool(4)
    secondaryActive = input.getBool(5)
    secondaryRadarTargetD = input.getBool(6)

    output.setBool(1, cameraInfraredActive)
    output.setNumber(1, targetPitch)
    output.setNumber(2, cameraTargetFOV)
    output.setNumber(3, secondaryPivotSpeed)
end

function onDraw()
    screen.drawCircle(16,16,5)
end
