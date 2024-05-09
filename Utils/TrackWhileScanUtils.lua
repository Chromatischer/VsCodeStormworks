---Initializes a new Track
---@param coordinate Coordinate the initatil point of radar contact
---@param boxSize number the size of the tracking box
---@param maxUpdateTime number the maximum amount of time that a track stays active without getting new data
---@param coastTime number the maximum amount of time a track stays coasted without new data
---@param activationNumber number the amount of coordinates needed to activate a track from inactive state
function newTrack(coordinate, boxSize, maxUpdateTime, coastTime, activationNumber)
    local newObject = {
        history = { coordinate }, -- all the coordinate data associated with the track
        boxSize = boxSize,        -- the size of the bounding box
        bufferTimer = 0,          -- for coasting for example
        updateTime = 0,           -- time since the last update for coasting as well as deleting
        prediction = coordinate,  -- next predicted point at current speed and angle
        speed = 0,
        heading = 0,
        state = 2, -- states: 0-active 1-coasted 2-inactive
        maxUpdateTime = maxUpdateTime,
        maxCoastTime = coastTime,
        activationNumber = activationNumber,
        -- easier to use for the prediction
        deltaX = 0,
        deltaY = 0,
        deltaZ = 0,

        ---returns the state of the track
        ---@return integer int 0 for active, 1 for coasted and 2 for inactive
        ---@section getState
        getState = function(self)
            return self.state
        end,
        ---@endsection

        ---returns the size of the tracking box
        ---@return number number the size of the box
        ---@section getBoxSize
        getBoxSize = function(self)
            return self.boxSize
        end,
        ---@endsection

        ---Appends the coordinate to the history, updates the deltas and the state all at once
        ---@param coordinate Coordinate the coordinate of the new contact
        ---@section addCoordinate
        addCoordinate = function(self, coordinate)
            self.history[#self.history + 1] = coordinate
            -- updating delta values also using WMA and dividing by updateTime to get deltas per Tick!
            self.deltaX = ((self.history[#self.history]:getX() - self.history[#self.history - 1]:getX()) / self.updateTime()) *
                0.5 + (self.deltaX * 0.5)
            self.deltaY = ((self.history[#self.history]:getY() - self.history[#self.history - 1]:getY()) / self.updateTime()) *
                0.5 + (self.deltaY * 0.5)
            self.deltaZ = ((self.history[#self.history]:getZ() - self.history[#self.history - 1]:getZ()) / self.updateTime()) *
                0.5 + (self.deltaZ * 0.5)
            self.speed = math.sqrt(self.deltaX ^ 2 + self.deltaY ^ 2 + self.deltaZ ^ 2) *
                60                                           -- is m / tick * 60 for m / s
            self.angle = math.atan(self.deltaY, self.deltaX) -- 2D direction
            self.updateTime = 0
            --activating the track if it is inactive and has a certain number of tracking points already or is coasted
            if (#self.history > self.activationNumber and self.state == 2) or self.state == 1 then
                self:activate()
            end
        end,
        ---@endsection

        addUpdateTime = function(self)
            self.updateTime = self.updateTime + 1
        end,

        getUpdateTime = function(self)
            return self.updateTime
        end,

        getMaxUpdateTime = function(self)
            return self.maxUpdateTime
        end,

        getMaxCoastTime = function(self)
            return self.maxCoastTime
        end,

        ---updates the prediction with the deltas previously aquired
        predict = function(self)
            self.prediction:add(self.deltaX, self.deltaY, self.deltaZ)
        end,

        ---coasts the track
        coast = function(self)
            self.state = 1
        end,

        ---activates the track
        activate = function(self)
            self.state = 0
        end,

        ---returns the location and size of the tracking box. Location is the latest detection except for if the track is coasted!
        ---@return Coordinate coordinate the location of the tracking box
        ---@return number number the size of the tracking box
        getBoxInfo = function(self)
            --return prediction only for coasted targets not for active or inactive ones
            return (self.state == 1) and self.prediction or self.history[#self.history], self.boxSize
        end,
        ---@return integer int the length of the history

        ---@section getHistoryLength
        getHistoryLength = function(self)
            return #self.history
        end,
        ---@endsection

        getLatestHistoryPosition = function (self)
            return self.history[#self.history]
        end,

        getPrediction = function (self)
            return self.prediction
        end
    }
    return newObject
end