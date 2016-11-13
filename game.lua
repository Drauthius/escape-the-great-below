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

local Camera = require "lib.hump.camera"
local HC = require "lib.HardonCollider"
local Timer = require "lib.hump.timer"
local Signal = require "lib.hump.signal"
local Debris = require "debris"
local Player = require "player"
local Level = require "level"

require "lib.math"

local Game = {
	defaultBackgroundColour = { 0, 15, 30, 180 }
}

love.debug = {
	--collision = true
}

function Game:init()
	self.winningSplash = love.audio.newSource("sfx/190080__tran5ient__splash7.mp3", "static")
	self.winningBreath = love.audio.newSource("sfx/267305__viznoman__breathing.mp3", "static")
	self.winningBreath:setVolume(0.8)

	-- Stencil away things with full opacity.
	self.maskShader = love.graphics.newShader[[
		vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords) {
			if(Texel(texture, texture_coords).a == vec3(1.0)) {
				discard;
			}
			return vec4(1.0);
		}
	]]

	-- Take the colour from LÖVE (via love.grahics.setColor), and the alpha
	-- from the texture.
	self.colourShader = love.graphics.newShader[[
		vec4 effect(vec4 colour, Image texture, vec2 texture_coords, vec2 screen_coords) {
			vec4 tex_colour = Texel(texture, texture_coords);
			return vec4(colour.r, colour.g, colour.b, tex_colour.a);
		}
	]]

	Signal.register("dead", function()
		self.gameOver = true
		Timer.tween(10, self.backgroundColour, { 0, 0, 0, 255 }, "linear", function()
			Timer.after(4, function()
				Signal.emit("switch_state", "menu")
			end)
		end)
	end)
end

function Game:enter()
	self.collider = HC.new(100)

	self.level = Level(self.collider, 300, 2500, 800, 500)
	self.player = Player(self.collider, 150, self.level.gap + 0.5 * self.level.height, love.math.random(0, 359), "gfx/person.png")
	self.playerRepacity = 0

	self.objects = {}
	local spawnArea = { 20, self.level.gap + 50, self.level.width - 40, self.level.height }
	for _,v in ipairs(Debris.Generate(self.collider, "barchair", 8, spawnArea)) do
		table.insert(self.objects, v)
	end
	for _,v in ipairs(Debris.Generate(self.collider, "couch", 3, spawnArea)) do
		table.insert(self.objects, v)
	end
	for _,v in ipairs(Debris.Generate(self.collider, "sofa", 2, spawnArea)) do
		table.insert(self.objects, v)
	end
	for _,v in ipairs(Debris.Generate(self.collider, "corpse3", 4, spawnArea)) do
		table.insert(self.objects, v)
	end
	for _,v in ipairs(Debris.Generate(self.collider, "corpse4", 4, spawnArea)) do
		table.insert(self.objects, v)
	end
	for _,v in ipairs(Debris.Generate(self.collider, "corpse5", 3, spawnArea)) do
		table.insert(self.objects, v)
	end
	for _,v in ipairs(Debris.Generate(self.collider, "corpse6", 3, spawnArea)) do
		table.insert(self.objects, v)
	end
	for _,v in ipairs(Debris.Generate(self.collider, "corpse7", 3, spawnArea)) do
		table.insert(self.objects, v)
	end
	for _,v in ipairs(Debris.Generate(self.collider, "corpse8", 3, spawnArea)) do
		table.insert(self.objects, v)
	end
	for _,v in ipairs(Debris.Generate(self.collider, "corpse9", 3, spawnArea)) do
		table.insert(self.objects, v)
	end
	for _,v in ipairs(Debris.Generate(self.collider, "piano2", 4, spawnArea)) do
		table.insert(self.objects, v)
	end

	self.camera = Camera(self.player.x, self.player.y, 4, math.rad(self.player.rot))
	self.cameraOffset = love.graphics.getHeight() / 2.5 / self.camera.scale
	local rotx, roty = math.rotationpoint(0, -self.cameraOffset, -math.rad(self.player.rot))
	self.camera:move(rotx, roty)

	self.backgroundColour = { unpack(Game.defaultBackgroundColour) }
	love.graphics.setBackgroundColor(self.backgroundColour)

	-- x,y, w,h
	self.waterArea = {
		-self.level.thickness, 0,
		2 * self.level.thickness + self.level.width, self.level.gap + self.level.height + 1000
	}

	self:flickerLight()

	self.gameOver = nil
end

function Game:leave()
	self.player:destroy()
	Timer.clear()
end

function Game:update(dt)
	Timer.update(dt)

	if self.player.y < self.level.gap - 100 then
		if not self.gameOver then
			self.player.rot = 0
			self.camera:rotateTo(0)
			Timer.after(2, function()
				Timer.tween(2.5, self.backgroundColour, {255, 255, 255, 255}, "quad", function()
					Timer.after(2.5, function()
						self.winningSplash:stop()
						self.winningBreath:stop()
						Signal.emit("switch_state", "menu")
					end)
				end)
			end)
			--Timer.tween(3.5, self.camera, { scale = 3 })
			Timer.tween(4, self, { playerRepacity = 255 }, "linear")
			Timer.after(3, function()
				Signal.emit("winning")
				self.winningSplash:play()
				self.winningBreath:play()
			end)
			self.gameOver = true
		end
		self.player.y = self.player.y - Player.swimSpeed * dt * 2
	else
		self.player:update(dt)

		for _,obj in ipairs(self.objects) do
			obj:update(dt)
		end
	end

	if self.gameOver then
		return
	end

	local dx, dy = self.player.x - self.camera.x, self.player.y - self.camera.y
	local rotx, roty = math.rotationpoint(0, -self.cameraOffset, -math.rad(self.player.rot))
	self.camera:move((dx + rotx) / 2, (dy + roty) / 2):rotateTo(math.rad(self.player.rot))

	if self.player.y > 0.6 * (self.level.gap + self.level.height) then
		local targetColour = { 0, 0, 5, 190 }
		local ratio = (self.player.y - 0.6 * (self.level.gap + self.level.height)) / self.level.gap
		-- Don't recreate the background colour, or the tween in init will fail.
		self.backgroundColour[1] = math.lerp(Game.defaultBackgroundColour[1], targetColour[1], ratio)
		self.backgroundColour[2] = math.lerp(Game.defaultBackgroundColour[2], targetColour[2], ratio)
		self.backgroundColour[3] = math.lerp(Game.defaultBackgroundColour[3], targetColour[3], ratio)
		self.backgroundColour[4] = math.lerp(Game.defaultBackgroundColour[4], targetColour[4], ratio)
	elseif self.player.y < self.level.gap + 50 then
		local targetColour = { 30, 30, 75, 110 }
		local targetRepacity = 150
		local ratio = 1 - self.player.y / (self.level.gap + 50)
		-- Don't recreate the background colour, or the tween in init will fail.
		self.backgroundColour[1] = math.lerp(Game.defaultBackgroundColour[1], targetColour[1], ratio)
		self.backgroundColour[2] = math.lerp(Game.defaultBackgroundColour[2], targetColour[2], ratio)
		self.backgroundColour[3] = math.lerp(Game.defaultBackgroundColour[3], targetColour[3], ratio)
		self.backgroundColour[4] = math.lerp(Game.defaultBackgroundColour[4], targetColour[4], ratio)
		self.playerRepacity = math.lerp(0, targetRepacity, ratio)
	end
end

function Game:draw()
	self.camera:draw(function()
		self.level:draw()

		for _,obj in ipairs(self.objects) do
			obj:draw(self.player)
		end

		self.player:draw()

		self.lightStencil = self.lightStencil or function()
			if not self.lightsOut then
				love.graphics.setShader(self.maskShader)
				self.player:drawLight()
				love.graphics.setShader()
			end
		end
		love.graphics.stencil(self.lightStencil)

		--- Draw light gradient
		love.graphics.setColor(self.backgroundColour)
		love.graphics.setShader(self.colourShader)
		self.player:drawLight()
		love.graphics.setColor(255, 255, 255)
		love.graphics.setShader()

		love.graphics.setColor(
			self.backgroundColour[1],
			self.backgroundColour[2],
			self.backgroundColour[3],
			255)
		self.level:drawWalls()

		-- Darken unlit areas.
		love.graphics.setStencilTest("less", 1)
		love.graphics.setColor(
			self.backgroundColour[1],
			self.backgroundColour[2],
			self.backgroundColour[3],
			255)
		love.graphics.rectangle("fill", unpack(self.waterArea))

		-- Darken lit areas.
		love.graphics.setStencilTest("equal", 1)
		love.graphics.setColor(
			self.backgroundColour[1],
			self.backgroundColour[2],
			self.backgroundColour[3],
			120)
		love.graphics.rectangle("fill", unpack(self.waterArea))

		love.graphics.setStencilTest()

		love.graphics.setColor(255, 255, 255, self.playerRepacity)
		self.player:draw()

		self:drawWaterFilter()
	end)
end

function Game:drawWaterFilter()
	love.graphics.setColor(self.backgroundColour)
	love.graphics.rectangle("fill", unpack(self.waterArea))
	love.graphics.setColor(255, 255, 255, 255)
end

function Game:flickerLight()
	Timer.during(math.prandom(0.2, 1.5), function()
		self.lightsOut = love.math.random() > 0.5
	end,
	function()
		if self.lightsOut then
			Timer.after(1, function()
				self.lightsOut = false
			end)
		end
	end)

	Timer.after(love.math.random(4, 15), function()
		self:flickerLight()
	end)
end

return Game
