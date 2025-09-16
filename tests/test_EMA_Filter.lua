-- Test file for EMA-Filter.lua
-- This test file simulates the behavior of the EMA filter

-- Mock the global environment that would be available in the actual environment
property = {}
input = {}
output = {}

-- Mock functions that would be available in the actual environment
function property.getNumber(name)
	if name == "EMA Faktor" then
		return mockEMAfactor
	end
	return nil
end

function input.getNumber(index)
	if index == 1 then
		return mockInputValue
	end
	return 0
end

function output.setNumber(index, value)
	if index == 1 then
		outputValue = value
	end
end

-- Variables to hold mock values and results
mockEMAfactor = 0.001
mockInputValue = 0
outputValue = 0

-- Test function to reset the global state between tests
function resetFilter()
	package.loaded["EMA-Filter"] = nil
	ema = nil
	change = 0.001
end

-- Test 1: Initial value
print("Test 1: Initial value")
resetFilter()
mockInputValue = 100
dofile("EMA-Filter.lua") -- Load and run once
onTick()
print("Input: " .. mockInputValue .. ", Output: " .. outputValue)

-- Test 2: Second tick with same input
print("\nTest 2: Second tick with same input")
onTick()
print("Input: " .. mockInputValue .. ", Output: " .. outputValue)

-- Test 3: Change input value
print("\nTest 3: Change input to 200")
mockInputValue = 200
onTick()
print("Input: " .. mockInputValue .. ", Output: " .. outputValue)

-- Test 4: Few more ticks with new value
print("\nTest 4: Few more ticks with input 200")
for i = 1, 5 do
	onTick()
	print("Tick " .. i .. ": Input: " .. mockInputValue .. ", Output: " .. outputValue)
end

-- Test 5: Change EMA factor
print("\nTest 5: Change EMA factor to 0.1")
resetFilter()
mockEMAfactor = 0.1
mockInputValue = 100
dofile("EMA-Filter.lua") -- Reload with new factor
onTick() -- First tick
print("First tick - EMA factor: " .. mockEMAfactor .. ", Input: " .. mockInputValue .. ", Output: " .. outputValue)

mockInputValue = 300
onTick() -- Second tick with new input
print("Second tick - EMA factor: " .. mockEMAfactor .. ", Input: " .. mockInputValue .. ", Output: " .. outputValue)

-- Test 6: Few more ticks with high EMA factor
print("\nTest 6: Few more ticks with EMA factor 0.1 and input 300")
for i = 1, 5 do
	onTick()
	print("Tick " .. i .. ": Input: " .. mockInputValue .. ", Output: " .. outputValue)
end
