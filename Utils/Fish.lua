---Generate a new fish object
---@class Fish
---@module "Utils.Color"
---@module "Utils.VirtualMapUtils"
---@module "Utils.Vectors.vec2"
---@module "Utils.Vectors.vec3"
---@field globalAngle number the global angle of the fish
---@field globalX number the global X position of the fish
---@field globalY number the global Y position of the fish
---@field globalZ number the global Z position of the fish
---@field relDepth number the relative depth of the fish
---@field color Color the color of the fish generated randomly with a set value and saturation
---@field age number the age of the fish
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
        color = Color2(0, 0.5, 0.9, false):genNewHue(), ---@type Color the color of the fish generated randomly with a set value and saturation
        age = 100, ---@type number the age of the fish
    }
end
---@endsection

---Draw the fish to the screen
---@class Fish
---@field drawSpotToScreen function draw the fish to the screen as a circle with a text of the depth
---@param self Fish the fish object
---@param virtualMap VirtualMap the virtual map object
---@param vesselAngle number the angle of the vessel (deg)
---@section drawSpotToScreen
function drawSpotToScreen(self, virtualMap, vesselAngle, isDarkMode)
    screenX, screenY = virtualMap:toScreenSpace(self.globalX, self.globalY, vesselAngle)
    self.color:getWithModifiedValue(isDarkMode and -0.3 or 0):setAsScreenColor()
    screen.drawCircleF(screenX, screenY, 6)
    self.color:getWithModifiedValue(isDarkMode and -0.5 or -0.2):setAsScreenColor()
    screen.drawCircle(screenX, screenY, 6)
    setColorGrey(0.7, isDarkMode)
    screen.drawText(screenX - 1, screenY - 1, self.relDepth)
end
---@endsection

---Returns the global position of the fish
---@class Fish
---@field getGlobalPosition function returns the global position of the fish
---@param self Fish the fish object
---@return table the global position of the fish
---@section getGlobalPosition
function getGlobalPosition(self)
    return {x = self.globalX, y = self.globalY, z = self.globalZ}
end
---@endsection

---Returns the global position of the fish as a Vec3 object
---@class Fish
---@field getAsVec3 function returns the global position of the fish as a Vec3 object
---@param self Fish the fish object
---@return Vec3 the global position of the fish as a Vec3 object
---@section getAsVec3
function getAsVec3(self)
    return Vec3(self.globalX, self.globalY, self.globalZ)
end
---@endsection

---Returns the global angle of the fish
---@class Fish
---@field getGlobalAngle function returns the global angle of the fish
---@param self Fish the fish object
---@return number the global angle of the fish
---@section getGlobalAngle
function getGlobalAngle(self)
    return self.globalAngle
end
---@endsection

---Returns the global depth of the fish
---@class Fish
---@field getGlobalDepth function returns the global depth of the fish
---@param self Fish the fish object
---@return number the global depth of the fish (m)
---@section getGlobalDepth
function getGlobalDepth(self)
    return self.relDepth
end
---@endsection

---Get the age of the fish
---@class Fish
---@field getAge function returns the age of the fish
---@param self Fish the fish object
---@return number the age of the fish
---@section getAge
function getAge(self)
    return self.age
end
---@endsection

---Increase the age of the fish by 1
---@class Fish
---@field update function increase the age of the fish by 1
---@param self Fish the fish object
---@section update
function update(self)
    self.age = self.age - 1
end
---@endsection

---Check if the fish is dead
---@class Fish
---@field isDead function returns true if the fish is dead
---@param self Fish the fish object
---@return boolean boolean True if the fish is dead
---@section isDead
function isDead(self)
    return self.age <= 0
end
---@endsection