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
local Baton = require "lib.baton.baton"
local Class = require "lib.hump.class"
local Timer = require "lib.hump.timer"
local Signal = require "lib.hump.signal"

local GameObject = require "gameobject"

local controls = {
	up = {'key:up', 'key:w', 'sc:w', 'axis:lefty-', 'button:dpup'},
	left = {'key:left', 'key:a', 'sc:a', 'axis:leftx-', 'button:dpleft'},
	right = {'key:right', 'key:d', 'sc:d', 'axis:leftx+', 'button:dpright'},
	--breath = {'key:space', 'sc:space', 'button:a'},
	debug = {'key:rctrl'}
}
local input = Baton.new(controls, love.joystick.getJoysticks()[1])

local Player = Class {
	__includes =  GameObject,
	swimSpeed = 35,
	rotSpeed = 40,
	startingBreath = 75
}

function Player:init(collider, x, y, rot, image)
	GameObject.init(self, nil, x, y, rot, image)

	self.collider = collider
	self.collision = collider:circle(x, y, 9)

	self.flashlight = love.graphics.newImage("gfx/light7.png")

	self.bubbles = love.graphics.newParticleSystem(love.graphics.newImage("gfx/bubble.png"), 64)
	self.bubbles:setLinearAcceleration(-1, -5, 1, -20)
	self.bubbles:setAreaSpread("normal", 4, 0)
	self.bubbles:setParticleLifetime(5, 10)
	self.bubbles:setSpin(0, 1)
	self.bubbles:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	self.bubbles:setSizeVariation(1.0)
	self.bubbles:setSizes(0.1, 0.2)

	self.heartbeat = love.audio.newSource("sfx/124095__robinhood76__02397-heartbeat-slowing-medium.mp3", "static")
	self.heartbeat:setVolume(0.2)
	self.heartbeat:setLooping(true)
	self.heartbeat:play()

	self.breathing = love.audio.newSource("sfx/183893__ryanconway__underwater-breathing.mp3", "static")
	self.breathing:setVolume(0.25)
	self.breathing:play()

	self.breath = Player.startingBreath
	self:breathe()

	self.signalHandler = Signal.register("winning", function()
		self.breathing:stop()
		self.heartbeat:stop()
		Timer.cancel(self.breathingTimer or {})
		Timer.cancel(self.delayBreathTimer or {})
	end)
end

function Player:destroy()
	self.breathing:stop()
	self.heartbeat:stop()
	Signal.remove("winning", self.signalHandler)
end

function Player:update(dt)
	GameObject.update(self, dt)
	self.bubbles:update(dt)

	if self.breath < 0 then
		self.heartbeat:setPitch(self.heartbeatPitch)
		return
	end

	do -- input
		input:update()

		local up = input:get("up")
		local rotate = input:get("left") - input:get("right")

		-- Movement
		self.rot = self.rot + rotate * self.rotSpeed * dt
		local dx, dy = math.rotationpoint(0, -up * self.swimSpeed * dt, math.rad(self.rot))
		self.x, self.y = self.x - dx, self.y + dy
		self.collision:move(-dx, dy)

		self:resolveCollisions()

		if math.abs(dx) ~= 0 and math.abs(dy) ~= 0 then
			-- No swaying.
			self.tx, self.ty = self.x, self.y
		end

		--if input:pressed("breath") then
			--self:breathe()
		--end

		if input:pressed("debug") then
			love.debug.collision = not love.debug.collision
		end
	end

	self.breath = self.breath - dt
	if self.breath < 0 then
		Signal.emit("dead", self)
		self.bubbles:emit(20)

		Timer.cancel(self.breathingTimer or {})
		self.breathing:rewind()
		self.breathing:setPitch(1)
		self.breathing:play()

		self.heartbeatPitch = self.heartbeat:getPitch()
		self.heartbeat:setVolume(self.heartbeat:getVolume() * 1.3)
		Timer.tween(6, self, { heartbeatPitch = 0.7 }, "linear", function()
			self.heartbeat:stop()
		end)
		Timer.after(2.5, function()
			self.bubbles:emit(10)
		end)
	else
		self.heartbeat:setPitch(math.lerp(0.8, 2.0, 1 - self.breath / Player.startingBreath))
	end
end

function Player:draw()
	--GameObject.draw(self)
	if self.image then
		love.graphics.push()
		love.graphics.translate(self.x, self.y)
		love.graphics.rotate(math.rad(-self.rot))

		local x, y = -self.image:getWidth() / 2, -self.image:getHeight() / 2 + 30

		love.graphics.draw(self.image, x, y)

		love.graphics.pop()
	end

	if love.debug.collision and self.collision then
		love.graphics.setColor(200, 50, 50, 100)
		self.collision:draw()
		love.graphics.setColor(255, 255, 255)
	end
	love.graphics.draw(self.bubbles, self.x, self.y)
end

function Player:drawLight()
	love.graphics.push()
	love.graphics.translate(self.x, self.y)
	love.graphics.rotate(math.rad(-self.rot))

	love.graphics.draw(self.flashlight, -self.flashlight:getWidth()/2-2, -6-self.flashlight:getHeight())

	love.graphics.pop()
end

function Player:breathe()
	self.bubbles:emit(6)

	Timer.cancel(self.breathingTimer or {})
	local pitch = math.prandom(0.8, 1.2)
	self.breathing:setPitch(pitch)
	self.breathing:play()
	self.breathingTimer = Timer.after(2 * 1.2 / pitch , function()
		self.breathing:stop()
		self.breathing:rewind()
	end)

	if self.breath > 8 then
		Timer.cancel(self.delayBreathTimer or {})
		self.delayBreathTimer = Timer.after(math.prandom(8, 12), function()
			self:breathe()
		end)
	end
end

return Player
