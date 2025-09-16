-- Author: Chromatischer
-- GitHub: github.com/Chromatischer
-- Workshop: steamcommunity.com/profiles/76561199061545480/
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey

--#region CH Layout
-- CH1: GPS X
-- CH2: GPS Y
-- CH3: GPS Z
-- CH4: Vessel Angle
-- CH5: Global Scale
-- CH6: Screen Center X
-- CH7: Screen Center Y
-- CH8: Touch X
-- CH9: Touch Y
-- CH10: Radar Rotation
-- CH11-22: Contact Data (4 channels per contact: distance, azimuth, elevation, timeSinceDetected)
-- CH13: ???

-- CHB1: Is Depressed
-- CHB2: Global Darkmode
-- CHB3: Self Is Selected
-- CHB4-6: Target Detected Status (1 per contact)
--#endregion

require("Vectors.Vectors")
require("Radar.BestTrackAlgorithm")
require("Radar.radarToGlobalCoordinates")
require("Utils")
require("Color")
require("DrawAddons")
require("Vectors.vec2")
require("Vectors.vec3")

rawRadarData = { Vec3(0, 0, 0), Vec3(0, 0, 0), Vec3(0, 0, 0) } ---@type Vec3[]
MAX_SEPERATION = 50 ---@type number
LIFESPAN = 20 ---@type number Lifespan till track deprecation in seconds
contacts = {} ---@type Vec3[]
tracks = {} ---@type Track[]

-- Display variables
renderDepression = 20 ---@type integer Pixel amount the vessel icon should be depressed by on the rectangular screen portion
dirUp = 0 ---@type number Radians Direction that is Upwards for the radar
mapDiameter = 10 ---@type number Total diameter that the screen should display in km

vesselPos = Vec3()
vesselAngle = 0
compas = 0
finalZoom = 1
screenCenter = Vec2()
radarRotation = 0
isDepressed = false
CHDarkmode = false
SelfIsSelected = false
vesselPitch = 0

ticks = 0
function onTick()
	ticks = ticks + 1

	-- Read primary inputs
	vesselPos = Vec3(input.getNumber(1), input.getNumber(2), input.getNumber(3))
	vesselAngle = input.getNumber(4)
	finalZoom = input.getNumber(5)
	screenCenter = Vec2(input.getNumber(6), input.getNumber(7))
	touchX = input.getNumber(8) -- Not used in current Y version
	touchY = input.getNumber(9) -- Not used in current Y version
	radarRotation = input.getNumber(10)

	-- Read boolean inputs
	isDepressed = input.getBool(1)
	CHDarkmode = input.getBool(2)
	SelfIsSelected = input.getBool(3)

	-- Only process radar data if self is selected
	if SelfIsSelected then
		compas = (vesselAngle - 180) / 360 -- Convert to radians

		dataOffset = 11
		boolOffset = 4

		-- Process each contact (0 to 2 for 3 contacts)
		for i = 0, 2 do
			distance = input.getNumber(i * 4 + dataOffset)
			targetDetected = input.getBool(i + boolOffset)
			timeSinceDetected = input.getNumber(i * 4 + 3 + dataOffset)

			-- Calculate target relative position then convert to world position
			tgtRelativePos = radarToGlobalCoordinates(
				distance,
				input.getNumber(i * 4 + 1 + dataOffset), -- azimuth
				input.getNumber(i * 4 + 2 + dataOffset), -- elevation
				vesselPos,
				radarRotation,
				vesselPitch
			)
			tgtWorldPos = addVec3(tgtRelativePos, vesselPos)

			-- Get the existing radar data point
			tgt = rawRadarData[i + 1] or Vec3(0, 0, 0)

			if timeSinceDetected ~= 0 then
				-- Using recursive averaging formula for smoothing
				-- new = ((old * n-1) + new) / n
				rawRadarData[i + 1] =
					scaleDivideVec3(addVec3(tgtWorldPos, scaleVec3(tgt, timeSinceDetected - 1)), timeSinceDetected)
			elseif vec3length(tgtWorldPos) > 50 then -- Only add if distance is significant
				-- Add to contacts for tracking
				table.insert(contacts, tgtWorldPos)
				rawRadarData[i + 1] = Vec3(0, 0, 0) -- Reset raw data
			end
		end

		-- Update tracks with contacts
		tracks = updateTrackT(tracks)

		if #contacts > 0 then
			-- Use Hungarian algorithm for tracking
			tracks = hungarianTrackingAlgorithm(contacts, tracks, MAX_SEPERATION, LIFESPAN * 60, {})
			contacts = {} -- Clear contacts after processing
		end
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
	---@param world Vec2 | Vec3 Worldposition
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

	vesselScreenPos = transformWS(vesselPos, screenCenter, dirUp, globalScales[globalScale])
end
