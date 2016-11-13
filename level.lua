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

local Level = Class()

function Level:init(collider, width, height, gap, thickness)
	self.width, self.height, self.gap = width, height, gap
	self.thickness = thickness or 20

	self.carpetImage = love.graphics.newImage("gfx/carpet2.png")

	local diff = self.width % self.carpetImage:getWidth()
	if diff ~= 0 then
		diff = 128 - diff
		--print("Increasing width by "..diff.." to " ..(self.width + diff))
		self.width = self.width + diff
	end
	diff = self.height % self.carpetImage:getHeight()
	if diff ~= 0 then
		diff = 128 - diff
		--print("Increasing height by "..diff.." to " ..(self.height + diff))
		self.height = self.height + diff
	end

	self.carpet = love.graphics.newSpriteBatch(self.carpetImage)
	for x = 0,self.width-1,self.carpetImage:getWidth() do
		for y = self.gap,self.gap+self.height,self.carpetImage:getHeight() do
			self.carpet:add(x, y)
		end
	end

	self.floorImage = love.graphics.newImage("gfx/floorboards.png")
	self.floor = love.graphics.newSpriteBatch(self.floorImage)
	for x = 0,self.width-1,self.floorImage:getWidth() do
		-- Top
		self.floor:add(x, self.gap - self.floorImage:getHeight())
		-- Bottom
		self.floor:add(x, self.gap + self.height + self.floorImage:getHeight() * 2, math.rad(180))
	end

	self.bow = {
		image = love.graphics.newImage("gfx/shipbow.png"),
	}
	--self.bow.x = self.width / 2 - self.bow.image:getWidth() / 2
	self.bow.x = -self.bow.image:getWidth() / 2
	self.bow.y = self.gap - self.bow.image:getHeight()

	self.leftWall = collider:rectangle(-self.thickness, self.gap, self.thickness, self.height)
	self.rightWall = collider:rectangle(self.width, self.gap, self.thickness, self.height)
end

function Level:draw()
	love.graphics.draw(self.carpet)
	love.graphics.draw(self.floor)
	love.graphics.draw(self.bow.image, self.bow.x, self.bow.y)
end

function Level:drawWalls()
	self.leftWall:draw("fill")
	self.rightWall:draw("fill")

	if love.debug.collision then
		love.graphics.setColor(200, 50, 50, 100)
		self.leftWall:draw()
		self.rightWall:draw()
		love.graphics.setColor(255, 255, 255)
	end
end

return Level
