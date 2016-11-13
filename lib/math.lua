function math.distance(x1, y1, x2, y2)
	return math.distancesquared(x1, y1, x2, y2)^0.5
end

function math.distancesquared(x1, y1, x2, y2)
	return ((x1-x2)^2 + (y1-y2)^2)
end

-- Returns the angle between two points.
function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end

-- Rotate a point according to an angle.
function math.rotationpoint(x, y, angle)
	local sin = math.sin(angle)
	local cos = math.cos(angle)
	return math.rotationpoint2(x, y, sin, cos)
end

-- Rotate a point according to pre-calculated angle.
function math.rotationpoint2(x, y, sin, cos)
	return x * cos - y * sin, x * sin + y * cos
end

function math.lerp(v0,v1,t)
	if type(v0) == "table" then
		local result = {}
		for i=1,#v0 do
			result[i] = math.lerp(v0[i], v1[i], t)
		end
		return result
	else
		return (1 - t) * v0 + t * v1
	end
end

function math.prandom(min, max)
	return love.math.random() * (max - min) + min
end
