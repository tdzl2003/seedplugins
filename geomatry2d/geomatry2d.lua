
local sqrt = math.sqrt

_ENV = {}

function normalize(x, y)
    local l = sqrt(x*x + y*y)
    return x/l, y/l
end

function magnitude(x, y)
    return sqrt(x*x + y*y)
end

function distance(x1, y1, x2, y2)
    return magnitude(x1-x2, y1-y2)
end

function magnitude2(x, y)
    return x*x + y*y
end

function distance2(x1, y1, x2, y2)
    return magnitude2(x1-x2, y1-y2)
end

return _ENV