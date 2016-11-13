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

require "lib.math"
local Class = require "lib.hump.class"
local Timer = require "lib.hump.timer"

local GameObject = Class {
	oscillationSpeed = 15
}

function GameObject:init(collider, x, y, rot, image)
	self.collider = collider
	self.x, self.y = x, y
	self.tx, self.ty = x, y
	self.rot = rot

	if image then
		if type(image) == "string" then
			self.image = love.graphics.newImage(image)
		else
			self.image = image
		end

		if collider then
			local w, h = self.image:getDimensions()
			w, h = w - 4, h - 4
			self.collision = collider:rectangle(x - w/2, y - h/2, w, h)
			self.collision:rotate(-math.rad(rot))

			self:resolveCollisions(true)
		end
	end

	Timer.every(3, function()
		local dx, dy = math.prandom(-1, 1), math.prandom(-1, 1)
		self.tx, self.ty = self.x + dx * self.oscillationSpeed, self.y + dy * self.oscillationSpeed
	end)
end

function GameObject:draw(lightSource)
	if self.image then
		love.graphics.push()
		love.graphics.translate(self.x, self.y)
		love.graphics.rotate(math.rad(-self.rot))

		local x, y = -self.image:getWidth() / 2, -self.image:getHeight() / 2

		-- Shadow
		if lightSource then
			local r,g,b,a = love.graphics.getColor()

			-- Uh........
			local angle = math.angle(self.x, self.y, lightSource.x, lightSource.y)
			local ox, oy = 0, 5
			ox, oy = math.rotationpoint(ox, oy, -angle)
			ox, oy = math.rotationpoint(ox, oy, -math.rad(self.rot))

			love.graphics.setColor(0, 0, 0, 150)
			love.graphics.draw(self.image, x + ox, y + oy)

			love.graphics.setColor(r,g,b,a)
		end

		-- Normal sprite
		love.graphics.draw(self.image, x, y)

		love.graphics.pop()
	end

	if love.debug.collision and self.collision then
		love.graphics.setColor(200, 50, 50, 100)
		self.collision:draw()
		love.graphics.setColor(255, 255, 255)
	end
end

function GameObject:update(dt)
	local dx, dy = self.tx - self.x, self.ty - self.y

	self.x, self.y = self.x + dx * dt * 0.5, self.y + dy * dt * 0.5
	if self.collision then
		self.collision:moveTo(self.x, self.y)
		self:resolveCollisions(true)
	end
end

local minFloat = 4e-10
function GameObject:resolveCollisions(once)
	local collides
	repeat
		collides = false

		for _,sepVector in pairs(self.collider:collisions(self.collision)) do
			local dx, dy = sepVector.x, sepVector.y
			if math.abs(dx) > minFloat or math.abs(dy) > minFloat then
				self.x, self.y = self.x + dx, self.y + dy
				self.collision:move(dx, dy)
				collides = not once and true
			end
		end
	until not collides
end

return GameObject
