---calculate the intersection of two circles if there is one or more using formula from this: https://math.stackexchange.com/a/1033561 post
---@param x1 number the coordinate of the first circles X-Postition
---@param y1 number the coordinate of the first circles Y-Postition
---@param r1 number the radius of the first circle
---@param x2 number the coordinate of the second circles X-Postition
---@param y2 number the coordinate of the second circles Y-Postition
---@param r2 number the radius of the second circle
---@return table intersections a table containing data about: two intersection points as (x1,y1) and (x2,y2)
---@deprecated do not use circle intersections, use TrilaterationUtils instead!
function circleIntersection(x1,y1,r1,x2,y2,r2)
    d = math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
    if d > r1 + r2 then
        return {x1 = nil, y1 = nil, x2 = nil, y2 = nil}
    end
    l = (r1^2 - r2^2 + d^2) / (2 * d) --remember? this was your problem :D not putting these parenthesis on the 2*d
    h = math.sqrt(r1^2 - l^2)
    xr1 = (l / d) * (x2 - x1) + (h / d) * (y2 - y1) + x1
    yr1 = (l / d) * (y2 - y1) + (h / d) * (x2 - x1) + y1
    xr2 = (l / d) * (x2 - x1) - (h / d) * (y2 - y1) + x1
    yr2 = (l / d) * (y2 - y1) - (h / d) * (x2 - x1) + y1
    return {x1 = xr1, y1=yr1, x2 = xr2, y2 = yr2}
end