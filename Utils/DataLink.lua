---Layout looks as follows: each cell of the table specifies the length of the data that can be transmitted / received there
---Note that floating point presicion errors can occur and will ruin the data
---Maybe use string encoding instead and decode from string?
---@class DataLink
---@field layout table<number> Layout of the data link
---@param layout table<number> Layout of the data link
---@return DataLink DataLink a new DataLink object
function DataLink(layout)
    return {
        layout = layout, ---@type table<number> Layout of the data link (each cell specifies the length of the data that can be transmitted / received there)
    }
end

---Encodes the data into a single number
---@class DataLink
---@field encode function Encodes the data into a single number
---@param self DataLink the DataLink object
---@param data table<number> the data to encode
---@return number number the encoded number
---@return number number the signs of the data (1 if negative, 0 if positive)
---@section encode
function encode(self, data)
    if not #self == #data then
        return nil, nil
    else
        encoded = 0
        signs = 0
        multiplier = 1
        for i = #data, 1, -1 do
            value = data[i]
            length = self.layout[i]
            if value < 0 then
                signs = signs + 2 ^ (i - 1)
            end
            encoded = encoded + valueToLength(value, length) * multiplier

            multiplier = multiplier * 10 ^ length
        end

        return encoded, signs
    end
end
---@endsection

---Decodes the data from a single number
---@param self DataLink the DataLink object
---@param number number the number to decode
---@param signs number the signs of the data (1 if negative, 0 if positive)
---@return table<number> table the decoded data
---@section decode
function decode(self, number, signs)
    values = {}
    for i = #self.layout, 1, -1  do
        length = self.layout[i]
        divisor = 10 ^ length
        value = number % divisor
        number = number / divisor

        if signs & 2 ^ i ~= 0 then
            value = -value
        end

        table.insert(values, math.floor(value))
    end
    return invertTable(values)
end
---@endsection

---Clamp the value between the minimum and the maximum value
---@param a table the table to invert
---@return b table the inverted table
---@section invertTable
function invertTable(a)
    --Invert the table so that the last element is the first and the first is the last
    b = {}
    for i = #a, 1, -1 do
        table.insert(b, a[i])
    end
    return b
end
---@endsection

---Clamp the value between 0 and the maximum value that can be stored in the length
---furthermore floors the number and take the absolute value
---
---1234.56 -> 1234 with length 4
---
---1234.56 -> 999 with length 3
---@param value number the value to clamp
---@param length number the number of digits the value can have
---@return number number the clamped value
---@section valueToLength
function valueToLength(value, length)
    return math.clamp(math.floor(math.abs(value)), 0, 10 ^ length - 1) --clamp between 0 and the maximum value that can be stored in the length e.g. 999 for a length of 3
end
---@endsection

---@section Testing

--Test with equal length and positive values
require("Utils.Utils")
dataLink = DataLink({3, 3, 3, 3})
encoded, signs = encode(dataLink, {123, 456, 789, 101})
print(encoded, signs)
decoded = decode(dataLink, encoded, signs)
for _, value in ipairs(decoded) do
    print(value)
end

print("------")

--test with negative values
dataLink = DataLink({3, 3, 3, 3})
encoded, signs = encode(dataLink, {123, -456, 789, -101})
print(encoded, signs)
decoded = decode(dataLink, encoded, signs)
for _, value in ipairs(decoded) do
    print(value)
end

print("------")

--test with different lengths
dataLink = DataLink({3, 5, 6, 3, 3})
encoded, signs = encode(dataLink, {123, 45678, 789101, 101, 101})
print(encoded, signs)
decoded = decode(dataLink, encoded, signs)
for _, value in ipairs(decoded) do
    print(value)
end

print("------")

--test with 2 large values for float precision errors
dataLink = DataLink({6, 6, 5})
encoded, signs = encode(dataLink, {999998, 999998, 99998})
print(encoded, signs)
decoded = decode(dataLink, encoded, signs)
for _, value in ipairs(decoded) do
    print(value)
end
---@endsection