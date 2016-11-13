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

local Timer = require "lib.hump.timer"
local Signal = require "lib.hump.signal"

local Menu = {}

local function gradient(colors)
    local direction = colors.direction or "horizontal"
    if direction == "horizontal" then
        direction = true
    elseif direction == "vertical" then
        direction = false
    else
        error("Invalid direction '" .. tostring(direction) "' for gradient.  Horizontal or vertical expected.")
    end
    local result = love.image.newImageData(direction and 1 or #colors, direction and #colors or 1)
    for i, color in ipairs(colors) do
        local x, y
        if direction then
            x, y = 0, i - 1
        else
            x, y = i - 1, 0
        end
        result:setPixel(x, y, color[1], color[2], color[3], color[4] or 255)
    end
    result = love.graphics.newImage(result)
    result:setFilter('linear', 'linear')
    return result
end

local function drawinrect(img, x, y, w, h, r, ox, oy, kx, ky)
    return -- tail call for a little extra bit of efficiency
    love.graphics.draw(img, x, y, r, w / img:getWidth(), h / img:getHeight(), ox, oy, kx, ky)
end

function Menu:init()
	self.background = gradient {
		{ 0, 15, 30 },
		{ 0, 0, 20 }
	}
	self.colourOverlay = { 0, 0, 0, 0 }

	self.titleFont = love.graphics.newFont("ttf/horrh___.ttf", 100)
	self.bodyFont = love.graphics.newFont("ttf/SharkintheWater.ttf", 20)

	self.bubbles = love.graphics.newParticleSystem(love.graphics.newImage("gfx/bubble.png"), 128)
	self.bubbles:setLinearAcceleration(-1, -5, 1, -20)
	self.bubbles:setAreaSpread("normal", 8, 8)
	self.bubbles:setParticleLifetime(5, 20)
	self.bubbles:setSpin(0, 1)
	self.bubbles:setColors(255, 255, 255, 255, 255, 255, 255, 0)
	self.bubbles:setSizeVariation(1.0)
	self.bubbles:setSizes(0.4, 0.8)
end

function Menu:enter(_, won)
	self.bubblesTimer = Timer.every(2.4, function()
		self.bubbles:moveTo(love.math.random(0, love.graphics.getWidth()), love.graphics.getHeight() + 20)
		self.bubbles:emit(love.math.random(6,12))
	end)

	-- Fake some interesting stuff.
	for _=0,love.math.random(20,60) do
		self:update(1)
	end

	if won then
		self.colourOverlay = { 255, 255, 255, 255 }
	else
		self.colourOverlay = { 0, 0, 0, 255 }
	end
	local targetOverlay = { unpack(self.colourOverlay) }
	targetOverlay[4] = 0
	self.overlayTimer = Timer.tween(2, self.colourOverlay, targetOverlay, "quad", function()
		self.overlayTimer = nil
	end)
end

function Menu:leave()
	Timer.cancel(self.bubblesTimer)
end

function Menu:update(dt)
	Timer.update(dt)
	self.bubbles:update(dt)
end

function Menu:draw()
	drawinrect(self.background, 0, 0, love.graphics.getDimensions())
	love.graphics.draw(self.bubbles)

	love.graphics.setColor(255, 255, 255, 225)
	love.graphics.setFont(self.titleFont)
	love.graphics.printf("Escape the Great Below", 0, love.graphics.getHeight() / 3, love.graphics.getWidth(), "center")

	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.setFont(self.bodyFont)
	love.graphics.printf("Credits:\nAlbert Diserholt\nSunisa Thongdaengdee", love.graphics.getWidth() - self.bodyFont:getWidth("Sunisa Thongdaengdee") - 10, love.graphics.getHeight() - self.bodyFont:getHeight() * 3, self.bodyFont:getWidth("Sunisa Thongdaengdee"), "right")
	love.graphics.print("Created for Asylum Jam 2016\nTheme: Escape Room", 10, love.graphics.getHeight() - self.bodyFont:getHeight() * 2)

	love.graphics.printf("Controls:\nArrow keys, WASD, or gamepad", love.graphics.getWidth() - 100 - 10, 300, 100, "right")

	love.graphics.setColor(self.colourOverlay)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
	love.graphics.setColor(255, 255, 255, 255)
end

function Menu.keypressed(_, key)
	if key == "escape" then
		love.event.quit()
	end
end

function Menu:keyreleased()
	if not self.overlayTimer then
		Signal.emit("switch_state", "game")
	end
end

function Menu:mousereleased()
	self:keyreleased()
end

return Menu
