function onTick()
	output.setNumber(1, input.getNumber(1))
end

---@return MicrocontrollerConfig config
function onAttatch()
	return {
		input_simulator = require("src.projects.test.attatch"),
	} ---@type MicrocontrollerConfig
end
