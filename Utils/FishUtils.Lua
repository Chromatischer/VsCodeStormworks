require("Utils.VirtualMapUtils")

---Generate a new fish object
---@class Fish
---@field globalAngle number the global angle of the fish (deg)
---@field globalX number the global X position of the fish
---@field globalY number the global Y position of the fish
---@field globalZ number the global Z position of the fish
---@field relDepth number the relative depth of the fish (m)
---@field age number the age of the fish (ticks)
---@field getGlobalPosition function returns the global position of the fish as coordinate object
---@field getGlobalAngle function returns the global angle of the fish (deg)
---@field getGlobalDepth function returns the global depth of the fish (m)
---@field getAge function returns the age of the fish (ticks)
---@field update function updates the fish object
---@field isDead function returns if the fish is dead
---@param gpsX number the GPS X position of the vessel
---@param gpsY number the GPS Y position of the vessel
---@param gpsZ number the GPS Z position of the vessel
---@param compas number the compas angle of the vessel (deg)
---@param yaw number the relative yaw angle to the fish (deg)
---@param distance number the distance to the fish (m)
---@param depth number the depth of the fish (m)
---@return Fish Fish the fish object
function newFish(gpsX, gpsY, gpsZ, compas, yaw, distance, depth)
    return {
        globalAngle = (compas + yaw) % 360,
        globalX = gpsX + (math.sin(globalAngle) * distance),
        globalY = gpsY + (math.cos(globalAngle) * distance),
        globalZ = gpsZ - depth,
        relDepth = depth,
        color = {0, 0, 0},
        age = 100,

        generateColor = function()
            
        end,

        getGlobalPosition = function (self)
            return {x = self.globalX, y = self.globalY, z = self.globalZ}
        end,

        getGlobalAngle = function (self)
            return self.globalAngle
        end,

        getGlobalDepth = function (self)
            return self.relDepth
        end,

        ---Get the age of the fish
        ---@param self Fish the fish object
        ---@return number the age of the fish
        getAge = function (self)
            return self.age
        end,

        ---Increase the age of the fish by 1
        ---@param self Fish the fish object
        update = function (self)
            self.age = self.age - 1
        end,

        ---Check if the fish is dead
        ---@param self Fish the fish object
        ---@return boolean boolean True if the fish is dead
        isDead = function (self)
            return self.age <= 0
        end,

        ---Draw the fish to the screen
        ---@param self Fish the fish object
        ---@param virtualMap VirtualMap the virtual map object
        ---@param vesselAngle number the angle of the vessel (deg)
        drawSpotToScreen = function (self, virtualMap, vesselAngle)
            screenX, screenY = virtualMap:globalToOnScreen(self.globalX, self.globalY, vesselAngle)
            screen.setColor(self.color[1], self.color[2], self.color[3])
            screen.drawCircleF(screenX, screenY, 6)
        end
    }
end