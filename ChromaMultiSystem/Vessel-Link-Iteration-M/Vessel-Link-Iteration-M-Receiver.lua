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
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)
        end;
end
---@endsection

require("Utils.Vectors.vec3")
require("Utils.Vectors.vec2")
require("Utils.Utils")
require("Utils.DrawAddons")
require("Utils.DataLink.DataLink")


vessels = {} ---@type table<Vessel>
startScanningAt = 0
lastCompleted = 0
numberOfVessels = 0
transmitOn = 0
currentScan = 0
channelOffset = 0
MAX_VESSEL_DETECT_TIME = 500
MAX_VESSELS = 32

ticks = 0
function onTick()
    ticks = ticks + 1
    startScanningAt = property.getNumber("ScanAbove:")
    transmitOn = transmitOn == 0 and startScanningAt + MAX_VESSELS or transmitOn --if transmitOn is 0, set it to the biggest possible, then do the step downward
    --start scanning for vessels transmitting their data at the specified channel
    if isVesselTransmit then
        if not scanAt == transmitOn then --dont scan the channel you are transmitting on
            --Read the data from the vessel transmitting on the channel
            numbers = {input.getNumber(channelOffset + 1), input.getNumber(channelOffset + 3), input.getNumber(channelOffset + 5), input.getNumber(channelOffset + 7), input.getNumber(channelOffset + 9)}
            signs = {input.getBool(channelOffset + 2), input.getBool(channelOffset + 4), input.getBool(channelOffset + 6), input.getBool(channelOffset + 8), input.getBool(channelOffset + 10)}

            --Create a vessel object with the data
            vessel = decodeVessel(numbers, signs, scanAt - 1) ---@type Vessel
            vessels[currentScan] = vessel
            vessels[currentScan].detected = ticks
            currentScan = currentScan + 1
        end
    else --no vessel on currentScan Channel
        if currentScan + 1 == transmitOn - 1 then
            transmitOn = currentScan --shift the transmit channel down one
            --meaning, that there will never be two vessels transmitting on the same channel
        end
        numberOfVessels = currentScan
        currentScan = 0
    end

    --Delete vessels that have not been detected for a while, due to receiver range or disconnecting
    for _, vessel in ipairs(vessels) do
        if ticks - vessel.detected > MAX_VESSEL_DETECT_TIME then
            table.remove(vessels, _)
        end
    end

    scanAt = startScanningAt + currentScan
    output.setNumber(1, transmitOn)
    output.setNumber(2, scanAt)
end

function onDraw()
end
