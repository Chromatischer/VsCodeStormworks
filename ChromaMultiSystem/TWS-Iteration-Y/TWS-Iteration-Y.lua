-- Author: Chromatischer
-- GitHub: github.com/Chromatischer
-- Workshop: steamcommunity.com/profiles/76561199061545480/
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

--#region CH Layout
-- N-1: Global Scale
-- N-2: GPS X
-- N-3: GPS Y
-- N-4: GPS Z
-- N-5: Vessel Angle
-- N-6: Screen Select I
-- N-7: Screen Select II
-- N-8: Touch X I
-- N-9: Touch Y I
-- N-10: Touch X II
-- N-11: Touch Y II

-- B-1: Global Darkmode
-- B-2: Touch I
-- B-3: Touch II
--#endregion

require("Vectors.Vectors")
require("Radar.BestTrackAlgorithm")
require("Radar.radarToGlobalCoordinates")

worldPos = Vec3(0, 0, 0) --TODO: Read in and remove this redundant declaration!

rawRadarData = {}
radarRotation = 0 ---@type number Radar rotation, normalized to rad
MAX_SEPERATION = 50 ---@type number
LIFESPAN = 20 ---@type number Lifespan till track deprecation in seconds
contacts = {} ---@type Vec3[]
tracks = {} ---@type Track[]

intercepts = {} --TODO: Maybe?

-- Display variables
renderDepression = 20 ---@type integer Pixel amount the vessel icon should be depressed by on the rectangular screen portion
dirUp = 0 ---@type number Radians Direction that is Upwards for the radar
mapDiameter = 10 ---@type number Total diameter that the screen should display in km

ticks = 0
function onTick()
	ticks = ticks + 1

	dataOffset = 11
	boolOffset = 5
	for i = 0, 3 do
		distance = input.getNumber(i * 4 + dataOffset)
		targetDetected = input.getBool(i + boolOffset)
		timeSinceDetected = input.getNumber(i * 4 + 3 + dataOffset)
		relPos = radarToRelativeVec3(
			distance,
			input.getNumber(i * 4 + 1 + dataOffset),
			input.getNumber(i * 4 + 2 + dataOffset),
			compas,
			input.getNumber(13)
		)
		tgt = rawRadarData[i + 1]

		if timeSinceDetected ~= 0 then
			-- Using target smoothing like Smithy
			-- new = old + ((new - old) / n)
			rawRadarData[i + 1] = addVec3(tgt, scaleDivideVec3(subVec3(relPos, tgt), timeSinceDetected))

			-- Using recursive averaging
			-- new = ((old * n-1) + new) / n
			-- rawRadarData[i + 1] = tgt and scaleDivideVec3(addVec3(relPos, scaleVec3(tgt, timeSinceDetected - 1)), timeSinceDetected) or relPos
		elseif tgt then --Check that there is a contact at the postion.
			table.insert(contacts, addVec3(worldPos, tgt))
			rawRadarData[i + 1] = nil
		end
	end

	tracks = updateTrackT(tracks) ---@type Track[]

	if #contacts ~= 0 then -- Now possible through the use of the Hungarian algorithm
		-- This is the complete solution: updating, deleting and creating in one! Amazing
		tracks = hungarianTrackingAlgorithm(contacts, tracks, MAX_SEPERATION, LIFESPAN * 60, {})
		contacts = {} -- Clear contacts!
	end
end

function onDraw()
	Swidth, Sheight = screen.getWidth(), screen.getHeight() --224x160
	--! Ok so this project aims for: 7x5 scaled to 3x2 monitors

	-- Split the screen into two parts: one rectangular and one to the side.
	-- Split into 64 to the right and 160 on the side
	screen.setColor(100, 0, 0, 128)
	screen.drawRect(0, 0, 63, 160)

	-- The rectangular part is for the main radar
	screen.setColor(0, 100, 0, 128)
	screen.drawRect(64, 0, 160, 160)

	-- Set the point at which the vessel is to be rendered
	radarMidPointX = 144 -- 64 + 160 / 2 (The midpoint of the larger rectangle)
	radarMidPointY = 80 + renderDepression

	---Translates a Worldspace Position to a Screenspace position
	---@param world Vec2 Worldposition
	---@param center Vec2 Worldposition where the Map is centered
	---@param updir number (rad) The direction that should be upward on screen
	---@param scale number (m) Diameter of the entire Map
	---@return Vec2 Vec2 Screenspace position
	function transformWS(world, center, updir, scale)
		relative = subtract(world, center) --The relative position of the world position to the center
		--[[
        distance = vec2length(relative) --Distance to the Worldposition in meters
        angle = math.atan(relative.y, relative.x) --Angle to the relative Position
        rotatedAngle = angle - updir --Rotated to be updir facing upwards
        transformScalar(relative, rotatedAngle, distance / scale)

        Transformed into Screenspace by:
        1. Converting into relative position
        2. Rotating to be facing the correct direction
        3. Scaled by the proportion the distance to the position takes on screen at the current scale
        And now as a single liner because I can:
        ]]
		--
		return transformScalar(relative, math.atan(relative.y, relative.x) - updir, vec2length(relative) / scale)
	end
	--TODO: Render tracks
end
