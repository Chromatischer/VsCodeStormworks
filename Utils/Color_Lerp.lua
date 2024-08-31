require("Utils.Utils")

---lerps between a color A and B and returns the color data for the result
---@param colorA table color table format {r, g ,b}
---@param colorB table color table format {r, g ,b}
---@param factor number the lerping factor mixing the colors
---@return table colorData the color data in the {r, g, b} format
---requires: percent() from "Utils.Utils"
function colorLerp(colorA, colorB, factor)
    gR = lerp(factor, colorA.g, colorB.g)
    bR = lerp(factor, colorA.b, colorB.b)
    rR = lerp(factor, colorA.r, colorB.r)

    return {r = rR, g = gR, b = bR}
end