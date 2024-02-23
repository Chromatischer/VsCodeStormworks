---returns a string version of the table of coordinates looking like this: Tablename: [X:1 Y:1, X:2 Y:2]
---@param table table the table of coordinates to print out
---@param name string the name to print in front of the table
---@return string tabledata the table data as a string
function printableCoordinateTable(table, name)
    firstLine = name .. ": ["
    for key, value in pairs(table) do
        firstLine = firstLine .. "X:" .. value.x .. " Y:" .. value.y .. (key < #table and ", " or "")
    end
    firstLine = firstLine .. "]"
    return firstLine
end

---print a coordinate at a selected position in the table
---@param table table the coordinate table
---@param name string the name to be displayed in front of the Data
---@param index number the position to print out
---@return string coordinate the coordinate in a format like this: Name X:1 Y:1
function printableCoordinateFromTable(table,name,index)
    return name .. " X:" .. table[index].x .. " Y:" .. table[index].y
end

---make the radar data to a string
---@param radarContact table radar Contact data
---@return string the data as a string
function printableRadarContact(radarContact)
    return "Global Coordinates: [" .. math.floor(radarContact.x) .. ", " .. math.floor(radarContact.y) .. ", " .. math.floor(radarContact.z) .. "] Age: " .. radarContact.age
end