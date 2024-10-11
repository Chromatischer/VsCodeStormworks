---Generate a new fish object
---@class Fish
---@field globalAngle number the global angle of the fish
---@field globalX number the global X position of the fish
---@field globalY number the global Y position of the fish
---@field globalZ number the global Z position of the fish
---@field relDepth number the relative depth of the fish
---@field color Color the color of the fish generated randomly with a set value and saturation
---@field age number the age of the fish
---@field getGlobalPosition function the function to get the global position of the fish
---@field getGlobalAngle function the function to get the global angle of the fish
---@field getGlobalDepth function the function to get the global depth of the fish
---@field getAge function the function to get the age of the fish
---@field update function the function to increase the age of the fish by 1
---@field isDead function the function to check if the fish is dead
---@field drawSpotToScreen function the function to draw the fish to the screen
---@param gpsX number the GPS X position of the vessel
---@param gpsY number the GPS Y position of the vessel
---@param gpsZ number the GPS Z position of the vessel
---@param compas number the compas angle of the vessel (deg)
---@param yaw number the relative yaw angle to the fish (deg)
---@param distance number the distance to the fish (m)
---@param depth number the depth of the fish (m)
---@return Fish Fish the fish object
---@section Fish
function Fish(gpsX, gpsY, gpsZ, compas, yaw, distance, depth)
    return {
        globalAngle = (compas + yaw) % 360, ---@type number the global angle of the fish
        globalX = gpsX + (math.sin(globalAngle) * distance), ---@type number the global X position of the fish
        globalY = gpsY + (math.cos(globalAngle) * distance), ---@type number the global Y position of the fish
        globalZ = gpsZ - depth, ---@type number the global Z position of the fish
        relDepth = depth, ---@type number the relative depth of the fish
        color = color2(0, 0.5, 0.9, false):genNewHue(), ---@type Color the color of the fish generated randomly with a set value and saturation
        age = 100, ---@type number the age of the fish

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
        drawSpotToScreen = function (self, virtualMap, vesselAngle, isDarkMode)
            screenX, screenY = virtualMap:toScreenSpace(self.globalX, self.globalY, vesselAngle)
            self.color:getWithModifiedValue(isDarkMode and -0.3 or 0):setAsScreenColor()
            screen.drawCircleF(screenX, screenY, 6)
            self.color:getWithModifiedValue(isDarkMode and -0.5 or -0.2):setAsScreenColor()
            screen.drawCircle(screenX, screenY, 6)
            setColorGrey(0.7, isDarkMode)
            screen.drawText(screenX - 1, screenY - 1, self.relDepth)
        end
    }
end
---@endsection