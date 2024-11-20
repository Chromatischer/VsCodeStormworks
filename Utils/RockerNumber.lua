---Creates a new rocker number object, which is a number that can be increased or decreased by pressing on the screen using arrows
---@class RockerNumber
---@field min number the minimum value of the number
---@field max number the maximum value of the number
---@field value number the current value of the number
---@field x number the x position of the number
---@field y number the y position of the number
---@field color Color the color of the number
---@param min number int the minimum value of the number
---@param max number int the maximum value of the number
---@param default number int the default value of the number
---@param x number the x position of the number on the screen
---@param y number the y position of the number on the screen
---@param color Color the color of the number
---@return RockerNumber Rocker the new rocker number object
---@section RockerNumber
function createRockerNumber(min, max, default, x, y, color)
    return {
        min = min,
        max = max,
        value = default,
        x = x,
        y = y,
        color = color,
    }
end
---@endsection

---Draws the rocker number on the screen with arrows to increase or decrease the value
---@class RockerNumber
---@field drawRockerNumber function draw the rocker number on the screen
---@param self RockerNumber the rocker number object
---@section drawRockerNumber
function drawRockerNumber(self)
    setAsScreenColor(self.color)
    screen.drawText(self.x, self.y, self.value)
    setAsScreenColor(modifyValue(self.color, 0.5)) -- lighten the color for the arrows
    screen.drawText(self.x, self.y + 5, "^")
    screen.drawText(self.x, self.y - 5, "v")
end
---@endsection

---Updates the rocker number value if the arrows are pressed
---@class RockerNumber
---@field updateRockerNumber function update the rocker number value if the arrows are pressed
---@param self RockerNumber the rocker number object
---@param pressedX number the x position of the press
---@param pressedY number the y position of the press
---@param isDepressed boolean whether the press is a depress or release
---@return boolean whether the rocker number was updated
---@section updateRockerNumber
function updateRockerNumber(self, pressedX, pressedY, isDepressed)
    if isDepressed then
        if isPointInRectangle(self.x, self.y - 5, 4, 5, pressedX, pressedY) then
            self.value = math.min(self.max, self.value + 1)
            return true
        end

        if isPointInRectangle(self.x, self.y, 4, 5, pressedX, pressedY) then
            self.value = math.max(self.min, self.value - 1)
            return true
        end
    end
    return false
end
---@endsection

---Updates the rocker numbers in an array if the arrows are pressed (only one rocker number pressed at a time)
---@param array table<RockerNumber> the array of rocker numbers
---@param pressedX number the x position of the press
---@param pressedY number the y position of the press
---@param isDepressed boolean whether the press is a depress or release
---@section updateRockerNumbers
function updateRockerNumbers(array, pressedX, pressedY, isDepressed)
    for _, rocker in ipairs(array) do
        if updateRockerNumber(rocker, pressedX, pressedY, isDepressed) then
            break
        end
    end
end
---@endsection