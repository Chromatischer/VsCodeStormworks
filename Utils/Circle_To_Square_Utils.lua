function math.sign(number)
    if number > 0 then
       return 1
    elseif number < 0 then
       return -1
    else
       return 0
    end
end

---This is an algorithm that converts coordinates from a circular space into a square space!
---@param u number the u coordinate in the circular space range: -1 - 1
---@param v number the v coordinate in the circular space range: -1 - 1
---@return number x the x coordinate in the square space range: -1 - 1
---@return number y the y coordinate in the square space range -1 - 1
---source: http://arxiv.org/abs/1509.06344
function simpleStretching(u, v)
    u2 = u ^ 2
    v2 = v ^ 2
    signu = math.sign(u)
    signv = math.sign(v)
    sqrtu2v2 = math.sqrt(u2 + v2)

    if u2 >= v2 then
        x = signu * sqrtu2v2
        y = signu * v / u * sqrtu2v2
    else
        x = signv * u / v * sqrtu2v2
        y = signv * sqrtu2v2
    end

    x = u == 0 and u or x
    y = v == 0 and v or y
    return x, y
end



---This is an algorithm that converts coordinates from a circular space into a square space!
---@param u number the u coordinate in the circular space range: -1 - 1
---@param v number the v coordinate in the circular space range: -1 - 1
---@return number x the x coordinate in the square space range: -1 - 1
---@return number y the y coordinate in the square space range -1 - 1
---source: http://arxiv.org/abs/1509.06344
function fgSquircularMapping(u, v)
    u2 = u ^ 2
    v2 = v ^ 2
    signuv = math.sign(u * v)
    common = math.sqrt(u2 + v2 - math.sqrt((u2 + v2) * (u2 + v2 - 4 * u2 * v2)))

    x = v == 0 and u or (signuv / v * math.sqrt(2)) * common
    y = u == 0 and v or (signuv / u * math.sqrt(2)) * common
    return x, y
end

---This is an algorithm that converts coordinates from a circular space into a square space!
---@param u number the u coordinate in the circular space range: -1 - 1
---@param v number the v coordinate in the circular space range: -1 - 1
---@return number x the x coordinate in the square space range: -1 - 1
---@return number y the y coordinate in the square space range -1 - 1
---source: http://arxiv.org/abs/1509.06344
function twoSquircularMapping(u, v)
    signuv = math.sign(u * v)
    common = math.sqrt(1 - math.sqrt(1 - 4 * u ^ 2 * v ^ 2))

    x = v == 0 and u or signuv / v * math.sqrt(2) * common
    y = u == 0 and v or signuv / u * math.sqrt(2) * common
    return x, y
end

---maps UV coordinates onto the unit circle even though they are outside
---@param u number the original x value
---@param v number the original y value
---@return number u the new x value
---@return number v the new y value
---based on the pythagorean therum and the fact that dividing by the distance will always make it return into the unit circle with radius 1
---see: https://www.desmos.com/calculator/ob8rg6n35e?lang=de for the base idea visualized
function uvCoordinatesOntoUnitCircle(u, v)
    u2 = u ^ 2
    v2 = v ^ 2
    d = math.sqrt(u2 + v2)
    if d >= 1 then
        if u == 0 then
            return 0, math.clamp(v, -1, 1)
        else
            if v == 0 then
                return math.clamp(u, -1, 1), 0
            else
                return (u / d), (v / d)
            end
        end
    else
        --print("u:" .. u .. " v:" .. v .. " d:" .. d)
        return u, v
    end
end