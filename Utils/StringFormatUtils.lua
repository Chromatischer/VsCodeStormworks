---floors the number then formats it using the specified length and returns the resulting string!
---@param number number the number to be formatted
---@param length number number of characters to return with
---@param character string one single character decides if it look like this: "--3" or "003"
---@return string String the formatted string
---@section string.formatNumberAsInteger
function string.formatNumberAsInteger(number, length, character)
    formatingString = "%" .. character .. length .. "d"
    return string.format(formatingString, math.floor(number))
end
---@endsection