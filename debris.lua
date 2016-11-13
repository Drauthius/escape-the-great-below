--[[
Copyright (C) 2016  Albert Diserholt

This file is part of Escape the Great Below.

Escape the Great Below is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any
later version.

Escape the Great Below is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Escape the Great Below.  If not, see <http://www.gnu.org/licenses/>.
--]]

local Class = require "lib.hump.class"

local GameObject = require "gameobject"

local Debris = Class {
	__includes = GameObject,
	types = {
	}
}

function Debris.Generate(collider, debrisType, num, area)
	if not Debris.types[debrisType] then
		Debris.types[debrisType] = love.graphics.newImage("gfx/" .. debrisType .. ".png")
	end

	local result = {}
	for _=0,num do
		local x, y = love.math.random(area[1], area[1] + area[3]), love.math.random(area[2], area[2] + area[4])
		local debris = Debris(collider, x, y, love.math.random(0, 359), Debris.types[debrisType])
		table.insert(result, debris)
	end

	return result
end

return Debris
