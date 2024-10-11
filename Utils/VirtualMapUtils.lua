---Generate a virtual map object, which has the same behaviour as the default map object but is centered on the vessel and has the option to be vessel angle UP and not North UP
---@class VirtualMap
---@field centerX number global X center of the map
---@field centerY number global Y center of the map
---@field screenWidth number width of the screen
---@field screenHeight number height of the screen
---@field screenRadius number radius of the screen
---@field maxRadius number maximum radius of the map
---@field toScreenSpace function convert global coordinates to on screen coordinates
---@param centerX number the global X center of the map
---@param centerY number the global Y center of the map
---@param screenWidth number the width of the screen
---@param screenHeight number the height of the screen
---@param maxRadius number the maximum radius of the map
---@param isDepressed boolean if true, the center of the map is depressed by 1/3 of the screen height (to show more of the front of the vessel)
---@return VirtualMap VirtualMap the virtual map object
function virtualMap(centerX, centerY, screenWidth, screenHeight, maxRadius, isDepressed)
    return {
        centerX = centerX, ---@type number the global X center of the map
        centerY = centerY, ---@type number the global Y center of the map
        screenWidth = screenWidth, ---@type number the width of the screen in pixels
        screenHeight = screenHeight, ---@type number the height of the screen in pixels
        screenRadius = math.min(screenWidth, screenHeight), ---@type number the radius of the screen in pixels
        maxRadius = maxRadius, ---@type number the maximum radius of the map
        isDepressed = isDepressed, ---@type boolean true if the center of the map is depressed by 1/3 of the screen height

        ---Convert global coordinates to on screen coordinates with the option to be vessel angle UP and not North UP
        ---@param self VirtualMap the virtual map object
        ---@param globalX number the global X coordinate to convert
        ---@param globalY number the global Y coordinate to convert
        ---@param angleUP ?number the angle to be up, nil for North UP
        ---@return table Coordinate2D the on screen coordinates
        toScreenSpace = function (self, globalX, globalY, angleUP)
            angle = angleUP and 0 or math.atan(globalY - self.centerY, globalX - self.centerX)

            onScreenX = (globalX - self.centerX) * math.sin(angle) / self.maxRadius * self.screenRadius
            onScreenY = (globalY - self.centerY) * math.cos(angle) / self.maxRadius * self.screenRadius - (self.isDepressed and self.screenHeight / 3 or 0)

            return {x = onScreenX, y = onScreenY}
        end,
    }
end