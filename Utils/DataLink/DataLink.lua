MAX_DIGITS = 15 --The maximum amount of digits that can be transmitted without loosing precision
STATUS = {1, 1, 1, 1, 1, 1}

--Use for creating a new DataLink object with 3 cells of length 2, 2 and 5 respectively for values that range from -99 to 99 and -99999 to 99999 respectively
--dataLink = DataLink({2, 2, 5})
--encoded, signs = encode(dataLink, {12, 34, 56789})
--decoded = decode(dataLink, encoded, signs)
--expect({12, 34, 56789}, decoded)
--print("Test passed")

---Layout looks as follows: each cell of the table specifies the length of the data that can be transmitted / received there
---Note that floating point presicion errors can occur and will ruin the data
---Maybe use string encoding instead and decode from string?
---@class DataLink
---@field layout table<number> Layout of the data link
---@param layout table<number> Layout of the data link
---@return DataLink | nil DataLink a new DataLink object or nil if the layout is too large and would cause floating point precision errors
---@section DataLink
function DataLink(layout)
    if sumTable(layout) <= MAX_DIGITS then
        return {
            layout = layout, ---@type table<number> Layout of the data link (each cell specifies the length of the data that can be transmitted / received there)
        }
    end
    return nil
end
---@endsection

---Sums all the values from a table and returns the result
---@param table table<number> the table to sum
---@return number number the sum of the table
---@section sumTable
function sumTable(table)
    sum = 0
    for _, value in ipairs(table) do
        sum = sum + value
    end
    return sum
end
---@endsection

---Encodes the data into a single number
---@class DataLink
---@field encode function Encodes the data into a single number
---@param self DataLink the DataLink object
---@param data table<number> the data to encode
---@return number | nil number the encoded number or nil if the layout is not applicable on the data
---@return number | nil number the signs of the data (1 if negative, 0 if positive) or nil if the layout is not applicable on the data
---@section encode
function encode(self, data)
    if #self == #data then
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
    return nil
end
---@endsection

---Encodes the data into a single number and saves the signs of the data
---@param self DataLink the DataLink object
---@param data table<number> the data to encode
---@return EncodedData EncodedData the encoded data
---@section encodeToObject
function encodeToObject(self, data)
    encoded, signs = encode(self, data)
    return EncodedData(encoded, signs)
end
---@endsection

---Decodes the data from a single number
---@class DataLink
---@field decode function Decodes the data from a single number
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

---Compares two tables and throws an error if they are not equal
---@param a table the table to compare
---@param b table the table to compare
---@section expect
function expect(a, b)
    for i = 1, #a do
        assert(a[i] == b[i], "Expected " .. a[i] .. " but got " .. b[i])
    end
end
---@endsection

---Creates a Vessel object from the decoded data, saves the received ID and returns the object
---@param decoded table the decoded data
---@param rcvID number the received ID
---@return Vessel Vessel the new Vessel object
---@section Vessel
function Vessel(decoded, rcvID)
    d1 = decoded[1]
    d2 = decoded[2]
    d3 = decoded[3]
    d4 = decoded[4]
    d5 = decoded[5]
    return {
        globalAngle = d1[3],
        selfID = d1[4],
        rcvID = rcvID,
        speed = d2[2] / 3,
        status = Status(d2[3]),
        p_radio = d3[1],
        s_radio = d3[2],
        souls = d3[3] + 9,
        curr_wpt = Vec3(d4[1], d4[2], d4[3]),
        curr_wpt_id = d4[4] + 99,
        tar_wpt = Vec3(d5[1], d5[2], d5[3]),
        tar_wpt_id = d5[4] + 99,
        position = Vec3(d1[1], d1[2], d2[1] + 900), ---@type Vec3 the global position of the vessel (x, y, z) where x, y are in ranges: -99999 to 99999 and z is in ranges -99 to 1998
    }
end
---@endsection

---Decodes the entire vessel data to a Vessel object
---@param numbers table<number> the numbers to decode
---@param signs table<number> the signs of the numbers
---@param rcvID number the received ID
---@return Vessel Vessel the new Vessel object
---@section decodeVessel
function decodeVessel(numbers, signs, rcvID)
    d1 = decode(DataLink({5, 5, 3, 2}), numbers[1], signs[1])
    d2 = decode(DataLink({3, 3, 6}), numbers[2], signs[2])
    d3 = decode(DataLink({5, 5, 1}), numbers[3], signs[3])
    d4 = decode(DataLink({5, 5, 3, 2}), numbers[4], signs[4])
    d5 = decode(DataLink({5, 5, 3, 2}), numbers[5], signs[5])
    return Vessel({d1, d2, d3, d4, d5}, rcvID)
end
---@endsection

---Creates an Object that saves data and signs of an encoded number
---@param data table<number> the data to save
---@param signs number the signs of the data
---@return EncodedData EncodedData the new EncodedData object
---@section EncodedData
function EncodedData(data, signs)
    return {
        data = data,
        signs = signs,
    }
end
---@endsection

---Encodes the entire vessel data into 5 objects ready to be transmitted
---@param position Vec3 the global position of the vessel
---@param angle number the global angle of the vessel in degrees (0-360)
---@param selfID number the ID of the vessel (0-198)
---@param speed number the speed of the vessel in m/s as an int (-333 to 333)
---@param vesselStatus any
---@param missionStatus any
---@param crewStatus any
---@param commStatus any
---@param resourceStatus any
---@param environmentStatus any
---@param p_radio any
---@param s_radio any
---@param souls any
---@param curr_wpt any
---@param curr_wpt_id any
---@param tar_wpt any
---@param tar_wpt_id any
---@return EncodedData
---@return EncodedData
---@return EncodedData
---@return EncodedData
---@return EncodedData
---@section encodeVesselData
function encodeVesselData(position, angle, selfID, speed, vesselStatus, missionStatus, crewStatus, commStatus, resourceStatus, environmentStatus, p_radio, s_radio, souls, curr_wpt, curr_wpt_id, tar_wpt, tar_wpt_id)
    obj1 = encodeToObject(DataLink({5, 5, 3, 2}), {position.x, position.y, angle, selfID - 99})
    obj2 = encodeToObject(DataLink({3, 3, 6}), {position.z - 900, speed * 3, encodeStatus(vesselStatus, missionStatus, crewStatus, commStatus, resourceStatus, environmentStatus)})
    obj3 = encodeToObject(DataLink({5, 5, 1}), {p_radio, s_radio, souls - 9})
    obj4 = encodeToObject(DataLink({5, 5, 3, 2}), {curr_wpt.x, curr_wpt.y, curr_wpt.z, curr_wpt_id - 99})
    obj5 = encodeToObject(DataLink({5, 5, 3, 2}), {tar_wpt.x, tar_wpt.y, tar_wpt.z, tar_wpt_id - 99})

    return obj1, obj2, obj3, obj4, obj5
end
---@endsection

---Creates and returns a new Status object
---@class Status a Status object that contains nescessary information about the status of the vessel
---@field vesselStatus number the status of the vessel
---@field missionStatus number the status of the mission
---@field crewStatus number the status of the crew
---@field communitcationStatus number the status of the communication
---@field resourceStatus number the status of the resources
---@field environmentStatus number the status of the environment
---@param input number the input to decode
---@return Status Status the new Status object
---@section Status
function Status(input)
    decoded = decode(DataLink(STATUS), input, 0)
    return {
        vesselStatus = decoded[1],
        missionStatus = decoded[2],
        crewStatus = decoded[3],
        communitcationStatus = decoded[4],
        resourceStatus = decoded[5],
        environmentStatus = decoded[6],
    }
end
---@endsection

---Encodes the status of the vessel into a single six digit number
---@param vessel number the status of the vessel
---@param mission number the status of the mission
---@param crew number the status of the crew
---@param comm number the status of the communication
---@param resource number the status of the resources
---@param environment number the status of the environment
---@return number | nil number the encoded status or nil if the layout is not applicable on the data
---@section encodeStatus
function encodeStatus(vessel, mission, crew, comm, resource, environment)
    return encode(DataLink(STATUS), {vessel, mission, crew, comm, resource, environment})
end
---@endsection

---Outputs the data and signs from an encoded object at the specified channel
---@param encoded EncodedData the encoded data
---@param startChannel number the channel to start at
---@section outputEncodedAt
function outputEncodedAt(encoded, startChannel)
    output.setNumber(startChannel, encoded.data)
    output.setNumber(startChannel + 1, encoded.signs)
end
---@endsection

---Creates a string from the givven vesselID (1-198) and returns it
---@param id number the id to convert
---@return string string two characters that represent the id as a string. No duplicates across all 198 IDs
---@section stringID
function IDToString(id)
    l = id / 198 * 25
    j = math.floor(l)
    k = math.floor((l - j) * 25)
    k = k == j and k + 1 or k

    return toChar(j) .. toChar(k)
end
---@endsection

---Creates a number from the given string (two characters) and returns it
---@param str string the string to convert
---@return number ID, boolean isComputable the id that was converted from the string
---@section IDFromString
function IDFromString(str)
    j = fromChar(string.sub(str, 1, 1))
    k = fromChar(string.sub(str, 2, 2))
    l = j + k / 25
    id = (l / 25) * 198

    return math.ceil(id), str == IDToString(math.ceil(id))
end
---@endsection