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
        updateTime = 0,           -- time since the last update for coasting as well as deleting
        updateTimes = {},         -- all the update times
        prediction = coordinate,  -- next predicted point at current speed and angle
        speed = 0,
        angle = 0,
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
            self.updateTimes[#self.updateTimes + 1] = self.updateTime
            self.history[#self.history + 1] = coordinate
            -- updating delta values also using WMA and dividing by updateTime to get deltas per Tick!
            --self:calculateMovingAverageDeltas(10)
            -- updating delta values using EMA and dividing by updateTime to get deltas per Tick!
            self:calculateExpontentialMovingDeltas(0.001) --this seems to work best
            -- updating delta values using Kalman Filter and dividing by updateTime to get deltas per Tick!
            --self:calculateKalmanDeltas(0.01, 1) --this is broken and way too huge for the amount of tokens available
            self.speed = math.sqrt(self.deltaX ^ 2 + self.deltaY ^ 2 + self.deltaZ ^ 2) * 60 -- is m / tick * 60 for m / s
            self.angle = math.atan(self.deltaY, self.deltaX) -- 2D direction
            self.updateTime = 0
            --activating the track if it is inactive and has a certain number of tracking points
            if #self.history > self.activationNumber and self.state == 2 then
                self:activate()
            end
        end,
        ---@endsection

        ---calculates the moving average deltas for the last Coordinates inside the averaging window
        ---@param windowSize number the size of the averaging window (number of values to average over)
        ---@section calculateMovingAverageDeltas
        calculateMovingAverageDeltas = function (self, windowSize)
            sumX = 0
            sumY = 0
            sumZ = 0
            for i = #self.history, #self.history - windowSize, -1 do
                sumX = sumX + (self.history[i]:getX() / self.updateTimes[i])
                sumY = sumY + (self.history[i]:getY() / self.updateTimes[i])
                sumZ = sumZ + (self.history[i]:getZ() / self.updateTimes[i])
            end
            self.deltaX = sumX / windowSize
            self.deltaY = sumY / windowSize
            self.deltaZ = sumZ / windowSize
        end,
        ---@endsection

        ---calculates the expontential moving average deltas
        ---@param alpha number the influence of the new data on the average
        ---@section calculateExpontentialMovingDeltas
        calculateExpontentialMovingDeltas = function (self, alpha)
            halpha = 1 - alpha
            updateTime = math.max(1, self.updateTime)
            self.deltaX = alpha * ((self.history[#self.history]:getX() - self.history[#self.history - 1]:getX()) / updateTime) + halpha * self.deltaX
            self.deltaY = alpha * ((self.history[#self.history]:getY() - self.history[#self.history - 1]:getY()) / updateTime) + halpha * self.deltaY
            self.deltaZ = alpha * ((self.history[#self.history]:getZ() - self.history[#self.history - 1]:getZ()) / updateTime) + halpha * self.deltaZ
        end,
        ---@endsection


        ---combines the exponential moving average with a windowed moving average for a hopefully better result
        ---@param alpha number the influence of the new data on the average
        ---@param windowSize number the size of the averaging window (number of values to average over)
        ---@section calculateExponentialWindowedMovingDeltas
        calculateExponentialWindowedMovingDeltas = function (self, alpha, windowSize)
            deltaX = 0
            deltaY = 0
            deltaZ = 0
            halpha = 1 - alpha
            if #self.history > 2 then
                for i = #self.history, #self.history - windowSize, -1 do
                    deltaX = alpha * (self.history[i]:getX() - self.history[i - 1]:getX()) / math.max(1, self.updateTimes[i]) + halpha * deltaX
                    deltaY = alpha * (self.history[i]:getY() - self.history[i - 1]:getY()) / math.max(1, self.updateTimes[i]) + halpha * deltaY
                    deltaZ = alpha * (self.history[i]:getZ() - self.history[i - 1]:getZ()) / math.max(1, self.updateTimes[i]) + halpha * deltaZ
                end
            end
        end,
        ---@endsection

        ---uses the kalman filter to calculate the deltas
        ---very broken!
        ---@param Q number the process noise covariance
        ---@param R number the measurement noise covariance
        ---@section calculateKalmanDeltas
        calculateKalmanDeltas = function(self, Q, R)
            -- Initialize state variables
            local x = 0 -- state estimate
            local P = 1 -- error covariance

            if #self.history > 2 and #self.updateTimes > 2 then
                for i = #self.history, 2, -1 do
                    -- Prediction step
                    local x_pred = x
                    local P_pred = P + Q

                    -- Update step
                    local y = self.history[i]:getX() - self.history[i - 1]:getX() / math.max(1, self.updateTimes[i])
                    local K = P_pred / (P_pred + R)
                    x = x_pred + K * y
                    P = (1 - K) * P_pred

                    -- Update delta values
                    self.deltaX = x
                end
                for i = #self.history, 2, -1 do
                    -- Prediction step
                    local x_pred = x
                    local P_pred = P + Q

                    -- Update step
                    local y = self.history[i]:getY() - self.history[i - 1]:getY() / math.max(1, self.updateTimes[i])
                    local K = P_pred / (P_pred + R)
                    x = x_pred + K * y
                    P = (1 - K) * P_pred

                    -- Update delta values
                    self.deltaY = x
                end
                for i = #self.history, 2, -1 do
                    -- Prediction step
                    local x_pred = x
                    local P_pred = P + Q

                    -- Update step
                    local y = self.history[i]:getZ() - self.history[i - 1]:getZ() / math.max(1, self.updateTimes[i])
                    local K = P_pred / (P_pred + R)
                    x = x_pred + K * y
                    P = (1 - K) * P_pred

                    -- Update delta values
                    self.deltaZ = x
                end
            end
        end,
        ---@endsection

        ---@section addUpdateTime
        addUpdateTime = function(self)
            self.updateTime = self.updateTime + 1
        end,
        ---@endsection

        ---@section getUpdateTime
        getUpdateTime = function(self)
            return self.updateTime
        end,
        ---@endsection

        ---@section getMaxUpdateTime
        getMaxUpdateTime = function(self)
            return self.maxUpdateTime
        end,
        ---@endsection

        ---@section getMaxCoastTime
        getMaxCoastTime = function(self)
            return self.maxCoastTime
        end,
        ---@endsection

        ---updates the prediction with the deltas previously aquired
        ---@section predict
        predict = function(self)
            self.prediction:add(self.deltaX, self.deltaY, self.deltaZ)
        end,
        ---@endsection

        ---coasts the track
        ---@section coast
        coast = function(self)
            self.state = 1
        end,
        ---@endsection

        ---activates the track
        ---@section activate
        activate = function(self)
            self.state = 0
        end,
        ---@endsection

        ---returns the location and size of the tracking box. Location is the latest detection except for if the track is coasted!
        ---@return Coordinate coordinate the location of the tracking box
        ---@return number number the size of the tracking box
        ---@section getBoxInfo
        getBoxInfo = function(self)
            --return prediction only for coasted targets not for active or inactive ones
            if self.state == 0 or self.state == 2 then
                location = self.history[#self.history]
            else
                if self.prediction then
                    location = self.prediction
                else
                    location = self.history[#self.history]
                end
            end
            return location, self.boxSize
        end,
        ---@endsection

        ---returns the length of the history
        ---@return integer int the length of the history
        ---@section getHistoryLength
        getHistoryLength = function(self)
            return #self.history
        end,
        ---@endsection

        ---returns the latest position in the history
        ---@return Coordinate coordinate the latest position
        ---@section getLatestHistoryPosition
        getLatestHistoryPosition = function (self)
            return self.history[#self.history]
        end,
        ---@endsection

        ---returns the prediction
        ---@return Coordinate coordinate the prediction
        ---@section getPrediction
        getPrediction = function (self)
            return self.prediction
        end,
        ---@endsection

        ---returns the calculated delta values
        ---@return Coordinate coordinate the delta values
        ---@section getDeltas
        getDeltas = function (self)
            return newCoordinate(self.deltaX, self.deltaY, self.deltaZ)
        end,
        ---@endsection

        ---retruns the 2D angle of the track
        ---@return number number the angle of travel of the track in radians
        ---@section getAngle
        getAngle = function (self)
            return self.angle
        end,
        ---@endsection

        ---returns the speed in m/s
        ---@return number number the speed of the track in m/s
        ---@section getSpeed
        getSpeed = function (self)
            return self.speed
        end,
        ---@endsection

        ---getHistory
        ---@return table table the history of the track
        ---@section getHistory
        getHistory = function (self)
            return self.history
        end,
        ---@endsection

        ---getUpdateTimes
        ---@return table table the update times of the track
        ---@section getUpdateTimes
        getUpdateTimes = function (self)
            return self.updateTimes
        end,
        ---@endsection
    }
    return newObject
end