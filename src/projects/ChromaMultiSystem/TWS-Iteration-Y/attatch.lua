local rad_sim = require("Simulator.Radar.attatch")

-- simulators/my_adv_sim.lua
---@class MyAdvSim : InputSimulatorTable
local M = { t = 0 }

---@param ctx SimulatorCtx
---@param cfg table|nil
function M.onInit(ctx, cfg)
	rad_sim.onInit(ctx, cfg)
end

---@param ctx SimulatorCtx
function M.onTick(ctx)
	local rad_state = rad_sim.onTick(ctx)
	ctx.input.setBool(3, true)
	ctx.input.setNumber(1, 0)
	ctx.input.setNumber(2, 0)
	ctx.input.setNumber(3, 0)
	ctx.input.setNumber(10, rad_state.current_rotation)
end

function M.onDebugDraw()
	rad_sim.onDebugDraw()
end

return M
