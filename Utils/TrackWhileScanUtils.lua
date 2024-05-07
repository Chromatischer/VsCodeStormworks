Track = {}
Track.__index = Track

---Initializes a new Track
---@param coordinate Coordinate the initatil point of radar contact
---@param boxSize number the size of the tracking box
---@param maxUpdateTime number the maximum amount of time that a track stays active without getting new data
---@param coastTime number the maximum amount of time a track stays coasted without new data
---@param activationNumber number the amount of coordinates needed to activate a track from inactive state
---@section intializer
function Track.new(coordinate, boxSize, maxUpdateTime, coastTime, activationNumber)
    local self = setmetatable({}, Track)
    self.history = {coordinate} -- all the coordinate data associated with the track
    self.boxSize = boxSize -- the size of the bounding box
    self.bufferTimer = 0 -- for coasting for example
    self.updateTime = 0 -- time since the last update for coasting as well as deleting
    self.prediction = coordinate -- next predicted point at current speed and angle
    self.speed = 0
    self.heading = 0
    self.state = 2 -- states: 0-active 1-coasted 2-inactive
    self.maxUpdateTime = maxUpdateTime
    self.maxCoastTime = coastTime
    self.activationNumber = activationNumber
    -- easier to use for the prediction
    self.deltaX = 0
    self.deltaY = 0
    self.deltaZ = 0
end
---@endsection

---returns the state of the track
---@return integer int 0 for active, 1 for coasted and 2 for inactive
---@section getState
function Track:getState()
    return self.state
end
---@endsection

---returns the size of the tracking box
---@return number number the size of the box
---@section getBoxSize
function Track:getBoxSize()
    return self.boxSize
end
---@endsection

---Appends the coordinate to the history, updates the deltas and the state all at once
---@param coordinate Coordinate the coordinate of the new contact
---@section addCoordinate
function Track:addCoordinate(coordinate)
    self.history[#self.history+1] = coordinate
    -- updating delta values also using WMA and dividing by updateTime to get deltas per Tick!
    self.deltaX = ((self.history[#self.history]:getX() - self.history[#self.history - 1]:getX()) / self.updateTime()) * 0.5 + (self.deltaX * 0.5)
    self.deltaY = ((self.history[#self.history]:getY() - self.history[#self.history - 1]:getY()) / self.updateTime()) * 0.5 + (self.deltaY * 0.5)
    self.deltaZ = ((self.history[#self.history]:getZ() - self.history[#self.history - 1]:getZ()) / self.updateTime()) * 0.5 + (self.deltaZ * 0.5)
    self.speed = math.sqrt(self.deltaX ^ 2 + self.deltaY ^ 2 + self.deltaZ ^ 2) * 60 -- is m / tick * 60 for m / s
    self.angle = math.atan(self.deltaY, self.deltaX) -- 2D direction
    self.updateTime = 0
    --activating the track if it is inactive and has a certain number of tracking points already or is coasted
    if (#self.history > self.activationNumber and self.state == 2) or self.state == 1 then
        self:activate()
    end
end
---@endsection


function Track:addUpdateTime()
    self.updateTime = self.updateTime + 1
end

function Track:getUpdateTime()
    return self.updateTime
end

function Track:getMaxUpdateTime()
    return self.maxUpdateTime
end

function Track:getMaxCoastTime()
    return self.maxCoastTime
end

---updates the prediction with the deltas previously aquired
function Track:predict()
    self.prediction:add(self.deltaX, self.deltaY, self.deltaZ)
end

---coasts the track
function Track:coast()
    self.state = 1
end

---activates the track
function Track:activate()
    self.state = 0
end

---returns the location and size of the tracking box. Location is the latest detection except for if the track is coasted!
---@return Coordinate coordinate the location of the tracking box
---@return number number the size of the tracking box
function Track:getBoxInfo()
    --return prediction only for coasted targets not for active or inactive ones
    return (self.state == 1) and self.prediction or self.history[#self.history], self.boxSize
end

---@return integer int the length of the history
---@section getHistoryLength
function Track:getHistoryLength()
    return #self.history
end
---@endsection