local target = require("Simulator.Radar.target")
local radar = require("Simulator.Radar.radar").new(nil)

local M = {}

---@param ctx SimulatorCtx
function M.onTick(ctx)
	radar:update(1)
	radar:add_target(target:new(nil, Vec3(0, 0, 0), Vec2(0, 0), 10, nil, nil))
	print(radar:get_state())
	ctx.input.setNumber(1, 10)
end

return M
