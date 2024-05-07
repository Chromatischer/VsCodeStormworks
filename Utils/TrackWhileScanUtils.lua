Track = {}
Track.__index = Track

function Track.new(coordinate, boxSize)
    local self = setmetatable({}, Track)
    self.history = {coordinate} -- all the coordinate data associated with the track
    self.boxSize = boxSize -- the size of the bounding box
    self.bufferTimer = 0 -- for coasting for example
    self.updateTime = 0 -- time since the last update for coasting as well as deleting
    self.prediction = coordinate -- next predicted point at current speed and angle
    self.speed = 0
    self.heading = 0
    self.state = 2 -- states: 0-active 1-coasted 2-inactive
    -- easier to use for the prediction
    self.deltaX = 0
    self.deltaY = 0
    self.deltaZ = 0
end

function Track:getState()
    return self.state
end

function Track:getBoxSize()
    return self.boxSize
end

function Track:addCoordinate(coordinate)
    self.history[#self.history+1] = coordinate
    self.updateTime = 0
end

function Track:addUpdateTime()
    self.updateTime = self.updateTime + 1
end

function Track:predict()
    -- to be implemented (continue the prediction with the last speed and angle data)
end

function Track:coast()
    self.state = 1
end

function Track:activate()
    self.state = 0
end

function Track:getBoxInfo()
    return (self.state == 0) and self.history[#self.history] or self.prediction, self.boxSize
end
