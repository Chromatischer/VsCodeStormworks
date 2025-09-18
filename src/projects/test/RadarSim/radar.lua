ticks = 0
function onTick()
	ticks = ticks + 1
end

---@return MicrocontrollerConfig
function onAttatch()
	return {
		tick = 60,
		tiles = "3x2",
		scale = 3,
		debugCanvas = true,
		debugCanvasSize = { w = 320, h = 320 },
		-- Attach an input simulator (function-form or table-form module)
		---@type InputSimulator
		input_simulator = require("Simulator.Radar.attatch"),
	}
end
