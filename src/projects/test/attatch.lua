local M = {}

function M.onTick(ctx)
	ctx.input.setNumber(1, 1000)
	ctx.input.setBool(2, true)
end

return M
