---Generate a new fish object
---@class Fish
---@field angle number the global angle of the fish
---@field globalPosition Vec3 the global position of the fish
---@field relDepth number the relative depth of the fish
---@field color Color the color of the fish
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
        angle = (compas + yaw) % 360, ---@type number the global angle of the fish
        globalPosition = Vec3(gpsX + (math.sin((compas + yaw) % 360) * distance), gpsY + (math.cos((compas + yaw) % 360) * distance), gpsZ - depth), ---@type Vec3 the global position of the fish
        relDepth = depth, ---@type number the relative depth of the fish
        color = genNewHue(Color2(0, 1, 0.9, false)), ---@type Color the color of the fish generated randomly with a set value and saturation
        age = 100, ---@type number the age of the fish
    }
end
---@endsection

---Generate a new school object
---@class School
---@field position Vec2 the position of the school
---@field size number the size of the school
---@field color Color the color of the school
---@field age number the age of the school
---@param fish Fish the fish to create the school from
---@return School School the school object
---@section School
function School(fish)
    return {
        position = getAsVec3(fish),
        color = fish.color,
        age = 0,
        fishes = {fish},
    }
end
---@endsection

---Add fishes to schools
---@param schools table<School> the schools to add the fishes to
---@param fishes table<Fish> the fishes to add to the schools
---@return table<School> School the schools with the added fishes
---@return table<Fish> Fish the fishes that were not added to the schools
---@section addFishesToSchools
function addFishesToSchools(schools, fishes)
    --add fishes to schools if they are close enough
    --do not add if the fish is already in this school from a previous iteration
    for i = #schools, 1, -1 do
        school = schools[i]
        for o = #fishes, 1, -1 do
            fish = fishes[o]
            if distanceToVec2(school.position, vec3ToVec2(getAsVec3(fish))) < 10 then
                if not fishPartOfSchool(fish, school) then
                    table.insert(school.fishes, fish)
                    table.remove(fishes, o)
                end
            end
        end
    end
    return schools, fishes
end
---@endsection

---Returns true if the fish is part of the school
---@param self Fish the fish object
---@param school School the school object
---@return boolean True if the fish is part of the school
---@section fishPartOfSchool
function fishPartOfSchool(self, school)
    --Check for distance to all fishes in the school
    for _, fish in ipairs(school.fishes) do
        if distanceToVec2(school.position, vec3ToVec2(getAsVec3(fish))) < 2 then
            return true
        end
    end
    return false
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
    onScreen = toScreenSpace(virtualMap, vec3ToVec2(self.globalPosition), vesselAngle)
    setAsScreenColor(self.color)
    screen.drawCircleF(onScreen.x, onScreen.y, 6)
    setAsScreenColor(self.color)
    screen.drawCircle(onScreen.x, onScreen.y, 6)
    --setColorGrey(0.7, isDarkMode)
    --screen.drawText(onSreen.x - 1, onSreen.y - 1, self.relDepth)
end
---@endsection

---Returns the global position of the fish as a Vec3 object
---@class Fish
---@field getAsVec3 function returns the global position of the fish as a Vec3 object
---@param self Fish the fish object
---@return Vec3 the global position of the fish as a Vec3 object
---@section getAsVec3
function getAsVec3(self)
    return self.globalPosition
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
    return self.globalPosition.z
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
---@field updateFish function increase the age of the fish by 1
---@param self Fish the fish object
---@section updateFish
function updateFish(self)
    self.age = self.age - 1
    return self
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