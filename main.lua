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

local Gamestate = require "lib.hump.gamestate"
local Signal = require "lib.hump.signal"

local Menu = require "menu"
local Game = require "game"

local backgroundMusic
local won = false

function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")

	Gamestate.registerEvents()

	backgroundMusic = love.audio.newSource("sfx/197751__wjoojoo__underwater-ambience-lake-lbj-08232013-1.mp3", "static")
	backgroundMusic:setVolume(0.4)
	backgroundMusic:setLooping(true)
	backgroundMusic:setPitch(0.5)

	Signal.register("winning", function()
		backgroundMusic:stop()
		won = true
	end)

	Signal.register("switch_state", function(state)
		if state == "menu" then
			Gamestate.switch(Menu, won)
		elseif state == "game" then
			Gamestate.switch(Game)
		else
			assert(false, "What "..tostring(state).."?")
		end

		won = false
		backgroundMusic:play()
	end)

	Signal.emit("switch_state", "menu")
end
