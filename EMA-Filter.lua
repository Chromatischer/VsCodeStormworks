ema = nil
change = 0.001

function onTick()
	change = property.getNumber("EMA Faktor") ~= 0 or change
	current = input.getNumber(1)
	ema = ema ~= nil and ema or current
	ema = (1 - change) * ema + (change * current)

	output.setNumber(1, ema or 0)
end

function onDebugDraw()
	str = "DO SOME CRAZY SHIT"
	print(str)
end
