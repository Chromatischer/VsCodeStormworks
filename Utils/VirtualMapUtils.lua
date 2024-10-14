---Generate a virtual map object, which has the same behaviour as the default map object but is centered on the vessel and has the option to be vessel angle UP and not North UP
---@class VirtualMap
---@field centerX number global X center of the map
---@field centerY number global Y center of the map
---@field screenWidth number width of the screen
---@field screenHeight number height of the screen
---@field screenRadius number radius of the screen
---@field maxRadius number maximum radius of the map
---@param centerX number the global X center of the map
---@param centerY number the global Y center of the map
---@param screenWidth number the width of the screen
---@param screenHeight number the height of the screen
---@param maxRadius number the maximum radius of the map
---@param isDepressed boolean if true, the center of the map is depressed by 1/3 of the screen height (to show more of the front of the vessel)
---@return VirtualMap VirtualMap the virtual map object
---@section VirtualMap
function VirtualMap(centerX, centerY, screenWidth, screenHeight, maxRadius, isDepressed)
    return {
        globalCenter = Vec2(centerX, centerY), ---@type Vec2 the global center of the map
        screenWidth = screenWidth, ---@type number the width of the screen in pixels
        screenHeight = screenHeight, ---@type number the height of the screen in pixels
        screenRadius = math.min(screenWidth, screenHeight), ---@type number the radius of the screen in pixels
        maxRadius = maxRadius, ---@type number the maximum radius of the map
        isDepressed = isDepressed, ---@type boolean true if the center of the map is depressed by 1/3 of the screen height
    }
end
---@endsection

---Convert global coordinates to on screen coordinates with the option to be vessel angle UP and not North UP
---@class VirtualMap
---@field toScreenSpace function convert global coordinates to on screen coordinates
---@param self VirtualMap the virtual map object
---@param global Vec2 the global coordinates to convert
---@param angleUP ?number the angle to be up, nil for North UP
---@return Vec2 Vec2 on screen coordinates in pixels
---@section toScreenSpace
function toScreenSpace(self, global, angleUP)
    ang = angleUP and math.rad(angleUP) or 0
    --convert from global to local
    relative = subtract(global, self.globalCenter)
    --rotate
    relDistance = vec2length(relative)
    relAngle = angleTo(self.globalCenter, global)
    rotated = ang + relAngle
    --convert to screen space
    screenDistance = relDistance / self.maxRadius * self.screenRadius --convert to pixels
    screenX = self.screenWidth / 2 + screenDistance * math.sin(rotated)
    screenY = screenDistance * math.cos(rotated) - (self.isDepressed and self.screenHeight / 2 + self.screenHeight / 3 or self.screenHeight / 2)
    return Vec2(screenX, screenY)
end
---@endsection