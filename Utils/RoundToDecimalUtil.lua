--Original code from: https://www.youtube.com/watch?v=itk-ZbOjdVw

---Should work! But its weird! decimal -1 is the 10th places rounded! -2 is the 100th places rounded
---@param number number the number to round
---@param decimal number the number of decimal places to round to for example: 0.1 or 10
---@return number number the number rounded to the specified decimal place
function math.roundToDecimal(number, decimal)
    local multiplier = 10 ^ (decimal or 0)
    return math.floor(number * multiplier + 0.5) / multiplier
end