-- Elliptical Grid mapping
-- mapping a circular disc to a square region
-- input: (u,v) coordinates in the circle
-- output: (x,y) coordinates in the square
-- source: http://squircular.blogspot.com/2015/09/mapping-circle-to-square.html
-- from my understanding u v coordinates are just a form of relative coordinates to an origin!
function ellipticalDiscToSquare(u, v)
    u2 = u * u
    v2 = v * v
    twosqrt2 = 2 * math.sqrt(2)
    subtermx = 2 + u2 - v2
    subtermy = 2 - u2 + v2
    termx1 = subtermx + u * twosqrt2
    termx2 = subtermx - u * twosqrt2
    termy1 = subtermy + v * twosqrt2
    termy2 = subtermy - v * twosqrt2
    x = 0.5 * math.sqrt(termx1) - 0.5 * math.sqrt(termx2)
    y = 0.5 * math.sqrt(termy1) - 0.5 * math.sqrt(termy2)
    return x, y
end
