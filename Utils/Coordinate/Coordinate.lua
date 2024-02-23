---@class Coordinate

Coordinate = {x=0,y=0}
---give the coordinate a start value
---@param x number the X value of the coordinate to have
---@param y number the Y value of the coordinate to have
---@return table coordinate the coordinate
function Coordinate.initialize(x,y)
    return {x=x,y=y}
end

function Coordinate.getX(self)
    return self.x
end

function Coordinate.getY(self)
    return self.y
end